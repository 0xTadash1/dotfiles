#
# Check load conditions, hook wiring and layer overrides in the final state after combining
#

##
# Both sides of each conditional (holds in full, does not hold in minimal)
#
# Add one line here when adding a bundle with a condition
#

assert_only_in_full "p10k loads only when TERM is not linux" '(( ${+functions[p10k]} ))'
assert_only_in_full "zsh-system-clipboard loads only when a clipboard tool exists" \
	'(( ${+functions[zsh-system-clipboard-set]} ))'
assert_only_in_full "e2j is defined only when trans exists" '(( ${+functions[e2j]} ))'
# Replacing cat can also affect the function bodies of plugins sourced later
assert_only_in_full "cat is replaced with bat only when bat exists" '[[ ${aliases[cat]-} == *bat* ]]'
assert_only_in_full "lk is defined only when walk exists" '(( ${+functions[lk]} ))'
assert_only_in_full "LS_COLORS is built only when vivid exists" '[[ ${LS_COLORS-} == *=*:* ]]'
assert_only_in_full "fzf-tab loads only when fzf exists" '(( ${+functions[fzf-tab-complete]} ))'
assert_only_in_full "^G^B is the fzf-git widget only when fzf exists" \
	'[[ $(bindkey "^G^B") == *fzf-git-branches-widget ]]'
# OMZ key-bindings also binds ^R, so in full this checks that the deferred fzf overrode it
assert_only_in_full "^R is fzf's history search only when fzf exists" \
	'[[ $(bindkey "^R") == *fzf-history-widget ]]'
assert_only_in_full "z is defined only when zoxide exists" '(( ${+functions[z]} ))'

##
# Terminal title (Prezto terminal module. It does nothing with TERM=linux, so full only)
#
# Look at the OSC 2 that reaches the terminal, in the pty log that script writes (printed in
# precmd, so it is written by the time the next command finishes)
# Build the directory name as ${:-title}probe: the preexec title contains the command text,
# so a literal name would match even if the cwd title never shows
#

if [[ $TEST_VARIANT == full ]]; then
	session_run "command mkdir -p /tmp/\${:-title}probe && cd /tmp/\${:-title}probe && print -r -- ready"
	if [[ $REPLY != ready ]]; then
		fatal "could not cd into the directory for the terminal title test: $REPLY"
	else
		session_run ':'
		typeset -a titles=()
		typeset rest=$(<$SESSION_DIR/log)
		while [[ $rest == *$'\e]2;'* ]]; do
			rest=${rest#*$'\e]2;'}
			titles+=("${rest%%$'\a'*}")
		done
		if [[ -n ${(M)titles:#*titleprobe*} ]]; then
			ok "the terminal title becomes the current directory when the prompt shows"
		else
			fail "the terminal title becomes the current directory when the prompt shows" \
				"OSC 2 titles: ${(j:, :)${(q+)titles}:-none}"
		fi
	fi
fi

##
# Hook wiring (checking alias values would copy hooks.zsh, so only check that the hook ran)
#
# Not checking that hook:p10k:post reads .p10k.zsh (when it breaks, p10k stops at its
# configuration wizard, and the whole run times out before reaching any assertion)
#

assert_cond "gxx.sh's post hook runs (alias g- exists)" '(( ${+aliases[g-]} ))'

##
# Layer overrides
#

# The next two only make sense together. OMZ also sets HIST_IGNORE_DUPS, so it being set
# cannot tell "rc set it again later" from "the hook's unsetopt never ran".
# HIST_VERIFY, which rc does not touch, being unset proves the unsetopt ran, and then
# HIST_IGNORE_DUPS being set means rc won
assert_cond "HIST_IGNORE_DUPS, as rc set it, is on in the final state" '[[ -o hist_ignore_dups ]]'
assert_cond "HIST_VERIFY is off in the final state" '[[ ! -o hist_verify ]]'

# Evidence that rc loaded (only rc sets HIST_FCNTL_LOCK)
assert_cond "rc's HIST_FCNTL_LOCK is on" '[[ -o hist_fcntl_lock ]]'

# rc sets PUSHD_IGNORE_DUPS and dirstax unsets it, so unset proves both the load and the order
assert_cond "dirstax unsets the PUSHD_IGNORE_DUPS rc set" '[[ ! -o pushd_ignore_dups ]]'
