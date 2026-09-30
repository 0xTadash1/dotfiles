#
# Check that keys reach the intended widget, by the edit buffer or cwd after sending real keys
# (key conflicts or load order can break this. What the widgets do is not tested)
#

##
# zsh-autopair
#

assert_buffer_after_keys "pressing ( fills in )" \
	'(' \
	'()'

##
# surround (vicmd)
#
# The config uses emacs mode, so enter vicmd with ^X^V (vi-cmd-mode) before sending
#

assert_buffer_after_keys 'cs can change the surrounding " to '"'"'' \
	$'"abc\x18\x16cs"\'' \
	"'abc'"

assert_buffer_after_keys 'ds can remove the surrounding pair' \
	$'"abc\x18\x16ds"' \
	'abc'

##
# history-substring-search
#
# Split with ${:-hs}: so the seeding command line itself, once in history, does not match the search
#

session_run 'print -s "echo ${:-hs}-target-line"'

assert_buffer_after_keys "^P searches history for substrings matching the text being typed" \
	$'hs-target\x10' \
	'echo hs-target-line'

##
# dirstax
#

session_run 'cd /tmp; cd /usr'

assert_pwd_after_keys "alt + ← goes back to the previous directory" \
	$'\e[1;3D' \
	'/tmp'

assert_pwd_after_keys "alt + → goes forward to the directory before going back" \
	$'\e[1;3C' \
	'/usr'

assert_pwd_after_keys "alt + ↑ goes up to the parent directory" \
	$'\e[1;3A' \
	'/'
