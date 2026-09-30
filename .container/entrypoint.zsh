#!/usr/bin/env zsh
#
# Place the config in $HOME by decoding chezmoi names, then start an interactive shell

emulate -L zsh
setopt err_exit no_unset pipe_fail

# Not baked into the image; runs directly from the mounted repo (see ENTRYPOINT in the Dockerfile)
typeset SRC=/mnt/dotfiles

# Volume freshness: volumes outlive image rebuilds, so after a package change a broken
# install left in an old volume is not fixed. Dropping it is left to the user
typeset image_digest=/usr/local/lib/dotfiles-verify/build-digest
typeset volume_digest=$HOME/.cache/dotfiles-verify.build-digest
if [[ ! -f $volume_digest ]]; then
	cp -- $image_digest $volume_digest
elif [[ "$(<$volume_digest)" != "$(<$image_digest)" ]]; then
	print -ru2 -- "entrypoint: the plugin cache does not match this image."
	print -ru2 -- "  The image environment (packages, etc.) has changed, so"
	print -ru2 -- "  drop the cache and retry:"
	print -ru2 -- "    .container/run clean <variant>"
	exit 1
fi

# Decodes only private_ and dot_. Other attributes (executable_, .tmpl) are not decoded
chezmoi_target() {
	typeset part target=
	for part in ${(s:/:)1}; do
		part=${part#private_}
		target+=/${part/#dot_/.}
	done
	print -r -- ${target#/}
}

# Place only what the zsh startup path uses
install -d -m 0700 -- "$HOME/.zsh"
typeset src
for src in $SRC/dot_z*(N.) $SRC/dot_profile $SRC/private_dot_zsh/**/*(N.); do
	install -D -m 0644 -- "$src" "$HOME/$(chezmoi_target ${src#$SRC/})"
done

# .zshrc: unmanaged by the repo because it changes often; on the real machine,
# `. $ZDOTDIR/init.zsh` is appended by hand after apply. Reproduce that shape
#
# dirstax keeps values that are already set, so ⌘ + arrows can be swapped in without
# touching the repo config or the plugin (^[ is two caret-notation characters, not ESC)
{
	if [[ ${DIRSTAX_KEYBINDS-} == darwin ]]; then
		print -r -- 'typeset -Ax dirstax=('
		print -r -- "	[keybind_upward]='^[[1;9A'"
		print -r -- "	[keybind_forward]='^[[1;9C'"
		print -r -- "	[keybind_backward]='^[[1;9D'"
		print -r -- ')'
	fi
	print -r -- '. $ZDOTDIR/init.zsh'
} > $HOME/.zsh/.zshrc

case ${1:-shell} in
	shell)
		# Without terminfo, zle cannot move the cursor, input looks duplicated, and colors do not show
		# Baking terminfo in breaks whenever the terminal changes (ghostty and kitty are not
		# in ncurses), so import the host definition passed by run
		if [[ -n ${TERM-} ]] && ! infocmp "$TERM" >/dev/null 2>&1; then
			if [[ -n ${HOST_TERMINFO-} ]]; then
				print -r -- "$HOST_TERMINFO" | tic -x -o "$HOME/.terminfo" - 2>/dev/null || true
			fi
			if infocmp "$TERM" >/dev/null 2>&1; then
				print -ru2 -- "entrypoint: imported $TERM from the host terminfo"
			else
				print -ru2 -- "entrypoint: TERM is not in terminfo, starting with xterm-256color"
				export TERM=xterm-256color
			fi
		fi
		# Login shell: the .zprofile -> .profile chain only runs there
		exec zsh -l
		;;
	*)
		exec "$@"
		;;
esac
