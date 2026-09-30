#
# Helpers that run a real interactive login shell to query its state and send it keys
#
# No zsh -i -c: most plugins are loaded by zsh-defer after the prompt shows, so under
# -i -c, where zle does not run, the functions and keys under test do not exist
#
# script owns the pseudo-terminal, keeps reading its output and writes it to a log. runner
# only writes to the input FIFO and reads the result FIFO. Owning the pty itself would
# mean draining it forever so the shell does not block on unread output
#
# The config is layered "OMZ -> hooks.zsh and plugins.d -> rc". Tests assert only the final
# state after deferred loading and never base expectations on what an intermediate layer says
#

typeset -g SESSION_DIR= SESSION_PID=
typeset -gi SESSION_IN=-1

# Results of session_run
typeset -g REPLY=
typeset -gi REPLY_STATUS=-1

##
# Session
#

# The interactive shell's stderr is kept in $SESSION_DIR/stderr and the pty output in $SESSION_DIR/log
session_start() {
	typeset term=$1
	SESSION_DIR=$(mktemp -d ${TMPDIR:-/tmp}/dotfiles-session.XXXX)
	mkfifo $SESSION_DIR/in $SESSION_DIR/out || return 1
	TERM=$term script -qfec "zsh -l -i 2>>$SESSION_DIR/stderr" $SESSION_DIR/log \
		<$SESSION_DIR/in >/dev/null &
	SESSION_PID=$!
	# Keep the input FIFO open: closing it sends EOF to script
	exec {SESSION_IN}>$SESSION_DIR/in
}

# Make the shell exit: kill makes script print "Session terminated"
session_stop() {
	send_line exit
	exec {SESSION_IN}>&-
	wait $SESSION_PID
}

# Queue a sentinel at the end of the zsh-defer queue and wait until it runs
# (the queue runs in order, so every deferred task queued before it has finished)
session_wait_deferred() {
	send_line "zsh-defer -c 'print -r -- ready >| $SESSION_DIR/out'"
	[[ "$(<$SESSION_DIR/out)" == ready ]]
}

# Wrap in bracketed paste: writes reach zle as keystrokes, and unwrapped, they would let
# zsh-autopair complete brackets and quotes and break the command
# Newline outside the wrap: inside, it only adds a newline to the buffer without accepting
send_line() {
	print -rn -- $'\e[200~'"$1"$'\e[201~'$'\n' >&$SESSION_IN
}

# No bracketed paste: let zle interpret it one character at a time
send_keys() {
	print -rn -- "$1" >&$SESSION_IN
}

# Put stdout and stderr in REPLY and the exit status in REPLY_STATUS
#
# Open the result FIFO only once per command. Opening it twice makes one read take both
# results and the next read never returns. EOF when the writer closes it signals completion
# (a background job that keeps the FIFO open delays the EOF)
#
# Through eval: turns a syntax error into a runtime error so the outer command still
# finishes (sent as is, it never reaches the result FIFO and hangs)
#
# The trailing blank line keeps output without a final newline off the exit status line
# (the status is saved before printing the blank line; $? afterwards would be print's 0)
#
# Commands are parsed by the interactive shell, so aliases expand. Do not write rc's global
# aliases (S='| sed', and A B G H HD L LP N P R TL V X X0) as bare words.
# rm and cat are aliases too, so prefix the underlying commands with command
session_run() {
	send_line "{ eval ${(qq)1} 2>&1; _st=\$?; print; print -r -- \$_st } >| $SESSION_DIR/out"
	typeset out=$(<$SESSION_DIR/out) st
	st=${out##*$'\n'}
	REPLY=${${out%$'\n'*}%$'\n'}
	# Do not mistake an unreadable exit status for 0 (success)
	if [[ $st == <-> ]]; then
		REPLY_STATUS=$st
	else
		REPLY_STATUS=-1
		fatal "could not read the command's exit status: $1"
	fi
}

##
# Real keys
#
# The edit buffer cannot be read from outside, so install a widget that writes it out and
# call it with ^X^N at the end of the key sequence. Keep terminal special characters out of
# the second byte (with ^X^D, the ^D right after returning to canonical mode was read as EOF
# and killed the session)
#

typeset -g BUFFER_DUMP=/tmp/dotfiles-zle-buffer

install_buffer_dump() {
	# Keys can arrive before zle is back after the previous command (terminal in cooked mode)
	# Unset lnext: otherwise the line discipline eats the ^V of ^X^V (human typing goes to zle in raw mode)
	session_run 'stty lnext undef'
	# Back to the main keymap: left in vicmd, the ESC sequence of the next bracketed paste
	# would be read as vicmd keys
	session_run "function _test_dump_buffer() { print -r -- \"\$BUFFER\" >! $BUFFER_DUMP; BUFFER=''; CURSOR=0; zle -K main }; zle -N _test_dump_buffer"
	session_run "for _m in main emacs viins vicmd visual viopp; do bindkey -M \$_m '^X^N' _test_dump_buffer; done; unset _m"
}

##
# Verdicts
#

typeset -gi TESTS_RUN=0 TESTS_FAILED=0 TESTS_FATAL=0

# When a premise broke and the result is invalid (counted as a failure)
fatal() {
	(( TESTS_FATAL++, TESTS_FAILED++ ))
	print -ru2 -- "  FATAL $1"
}

ok() {
	(( TESTS_RUN++ ))
	print -r -- "  ok    $1"
}

fail() {
	(( TESTS_RUN++, TESTS_FAILED++ ))
	print -ru2 -- "  FAIL  $1"
	[[ -n ${2-} ]] && print -ru2 -- "        ${2//$'\n'/ | }"
	return 0
}

# Anything on stderr means the condition itself is broken (so an error cannot slip through as a pass on the negated side)
assert_cond() {
	typeset desc=$1 cmd=$2
	session_run "{ $cmd } >/dev/null"
	if [[ -n $REPLY ]]; then
		fail $desc "error while evaluating: $cmd / $REPLY"
	elif (( REPLY_STATUS == 0 )); then
		ok $desc
	else
		fail $desc "false: $cmd"
	fi
}

assert_only_in_full() {
	typeset desc=$1 cond=$2
	if [[ $TEST_VARIANT == full ]]; then
		assert_cond $desc $cond
	else
		assert_cond $desc "! { $cond }"
	fi
}

# Clear the buffer with ^U: ^G leaves zle and the following bytes are read as terminal special characters
# Remove the file every time: so a stale value cannot match when the widget does not fire
assert_buffer_after_keys() {
	typeset desc=$1 keys=$2 want=$3
	session_run "command rm -f $BUFFER_DUMP"
	send_keys $'\x15'"$keys"$'\x18\x0e'
	session_run "command cat $BUFFER_DUMP"
	if (( REPLY_STATUS != 0 )); then
		fail $desc "dump widget did not fire (no buffer file)"
	elif [[ $REPLY == "$want" ]]; then
		ok $desc
	else
		fail $desc "expected: $want / actual: $REPLY"
	fi
}

# Widgets that run a command, like dirstax, are checked by cwd instead of the buffer
assert_pwd_after_keys() {
	typeset desc=$1 keys=$2 want=$3
	send_keys $keys
	session_run 'print -r -- $PWD'
	[[ $REPLY == "$want" ]] && ok $desc || fail $desc "expected: $want / actual: $REPLY"
}

# A failed source, or a file that runs no assertion, is FATAL
# (do not let a broken test file itself produce green)
run_test_file() {
	typeset f=$1
	typeset -i before=$TESTS_RUN
	print -r -- ""
	print -r -- "-- ${f:t}"
	if ! source $f; then
		fatal "${f:t} failed to run (syntax error, unset variable, etc.)"
	elif (( TESTS_RUN == before )); then
		fatal "${f:t} ran no assertions"
	fi
}
