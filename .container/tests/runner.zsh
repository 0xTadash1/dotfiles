#!/usr/bin/env zsh
#
# Check the output of the first start, then run tests/[0-9]*.zsh in one interactive session
# (no new session per test, because startup takes time)
#
# The only time limit is the one entrypoint puts on the whole run. No limit on reads
# inside the session: giving up on one read lets the next read take the late result,
# and every result after that is off

emulate -L zsh
setopt no_unset pipe_fail

typeset -g TESTS_DIR=${0:A:h}
source $TESTS_DIR/lib.zsh

##
# variant
#
# Expectations are based on TEST_VARIANT (the declared value run passes), not on measuring
# which commands exist. Branching on measured results would pass "no bat" as correct when bat goes missing from full
# So check first that the image matches the declaration
#

typeset -g TEST_VARIANT=${TEST_VARIANT-}

case $TEST_VARIANT in
	minimal|full) ;;
	*)
		print -ru2 -- "FATAL TEST_VARIANT is unset or invalid: '${TEST_VARIANT}'"
		exit 1
		;;
esac

# Not checking zsh and git: without them, runner or the antidote fetch fails right away
# tar: missing from the arm64 rebuild; without it, p10k silently fails to unpack gitstatusd
# whence -p: command -v also matches aliases
check_image_matches_variant() {
	typeset c
	for c in less tar; do
		whence -p $c >/dev/null || fatal "$c is missing (required in both variants)"
	done
	for c in bat eza fd fzf trans vivid walk zoxide; do
		if [[ $TEST_VARIANT == full ]]; then
			whence -p $c >/dev/null || fatal "$c is missing in full"
		elif whence -p $c >/dev/null; then
			fatal "$c exists in minimal"
		fi
	done
}
check_image_matches_variant

# Both sides of each conditional come from the variant (full: all hold, minimal: none hold)
# Add the stubs to PATH only for the full tests: when poking around in run sh full,
# an xclip that only shows it exists would be confusing
typeset -g SESSION_TERM=linux
if [[ $TEST_VARIANT == full ]]; then
	SESSION_TERM=xterm-256color
	export PATH=${TESTS_DIR:h}/stubs:$PATH
fi

print -r -- "== dotfiles verification =="
print -r -- "variant=$TEST_VARIANT  mode=${TEST_MODE:-unknown}  TERM=$SESSION_TERM"

##
# First start
#
# On cold, this is a new machine's first start. Cloning, smartcache cache generation and the
# gitstatusd fetch only happen here, so check that nothing but fetch progress is printed
# No bundle list here: it would copy .zsh_plugins.txt
#
# Fetch here: keeps fetch progress out of the session stderr check
# TERM=xterm-256color: also fetch gitstatusd regardless of the variant
# Exit status ignored: it is only that of the last command in the startup files
# </dev/null: with the terminal attached, it never returned under timeout
#

print -r -- ""
print -r -- "-- first start"
() {
	typeset -a unexpected=(${(f)"$(TERM=xterm-256color zsh -l -i -c exit </dev/null 2>&1)"})
	unexpected=(${unexpected:#Cloning into \'$HOME/.zsh/.antidote\'...})
	unexpected=(${unexpected:#\# antidote cloning *...})
	unexpected=(${unexpected:#\[powerlevel10k\] fetching gitstatusd *\[ok\]})
	if (( ${#unexpected} )); then
		fail "the first start prints nothing but fetch progress" "${(F)unexpected}"
	else
		ok "the first start prints nothing but fetch progress"
	fi
}

##
# Session
#

typeset -a tests=($TESTS_DIR/[0-9]*.zsh(N))
# Do not go green silently when files are removed or renamed
if (( ${#tests} == 0 )); then
	print -ru2 -- "FATAL no test files"
	exit 1
fi

print -r -- ""
print -r -- "-- starting the interactive session (TERM=$SESSION_TERM)"
session_start $SESSION_TERM || { fatal "could not start the session"; exit 1 }
if ! session_wait_deferred; then
	fatal "could not confirm that deferred loading finished"
else
	# Catches failures that only show up as error output while each assertion passes (a missing command, etc.)
	# Deferred plugins' stderr is visible thanks to defer-options '-12' in init.zsh
	# Checked before the tests: stderr of widgets run by keys goes to the same file
	typeset err=$(<$SESSION_DIR/stderr)
	if [[ -z $err ]]; then
		ok "stderr from startup through deferred loading is empty"
	else
		fail "stderr from startup through deferred loading is empty" "$err"
	fi

	install_buffer_dump
	typeset f
	for f in $tests; do
		run_test_file $f
	done

	# Bundles track upstream HEAD, so tracing a failure needs the revisions (not printed on success)
	if (( TESTS_FAILED )); then
		session_run 'for d in $ANTIDOTE_HOME/*/*/*(N/); do print -r -- "  ${d#$ANTIDOTE_HOME/} $(git -C $d rev-parse --short HEAD 2>/dev/null || print -r -- no-git)"; done'
		print -r -- ""
		print -r -- "-- plugin revisions"
		print -r -- $REPLY
	fi
fi
session_stop

print -r -- ""
print -r -- "== variant=$TEST_VARIANT run=$TESTS_RUN failed=$TESTS_FAILED fatal=$TESTS_FATAL =="

(( TESTS_FAILED == 0 ))
