# Changed directory path to respect ZDOTDIR
### Added by Zinit's installer
if [[ ! -f "${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh" ]]; then
	print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
	command mkdir -p "${ZDOTDIR:-$HOME}/.zinit" && command chmod g-rwX "${ZDOTDIR:-$HOME}/.zinit"
	command git clone https://github.com/zdharma-continuum/zinit "${ZDOTDIR:-$HOME}/.zinit/bin" && \
		print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
		print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
	zdharma-continuum/zinit-annex-readurl \
	zdharma-continuum/zinit-annex-bin-gem-node \
	zdharma-continuum/zinit-annex-patch-dl \
	zdharma-continuum/zinit-annex-rust

() {
	local d="${ZDOTDIR:-$HOME}/.zinit/polaris/bin"
	[[ ! -d "$d" ]] && command mkdir -p "$d"
}
### End of Zinit's installer chunk


zinit wait'0' lucid light-mode for proto'ssh' @0xTadash1/zsh-noob-init


## Oh-My-Zsh TODO: history, kbd
zinit wait'0' lucid light-mode svn for OMZP::extract
zinit wait'0' lucid light-mode for OMZL::clipboard.zsh

## Prezto:TODO


# TODO: Read docs more, Use more
#zinit wait'0' lucid light-mode for sbin'bin/git-fuzzy' as'null' \
#	if'[[ "$(command -v fzf)" ]]' \
#	atload': pass' \
#	@bigH/git-fuzzy

# TODO: variables, functions, clipboard tool
# `*.plugin.zsh` in repo just sets an alias
zinit wait'0' lucid light-mode for sbin'translate -> trans' \
	atload"$(<<-'END'
		# sed removes hyphenations and join lines
		#   \u2010 vs \u2D == ‐ vs - == "hyphen" vs "hyphen-minus"
		#   A standard hyphen entered via keyboard is "hyphen-minus"
		xclip_sed='echo $(xclip -o -sel clip | sed -zE "s/[\u2010\u2D]\n +//g")'
		stdin='[[ -p /dev/stdin ]] && command cat'
		_e2j='trans -b -s en -t ja'
		_j2e='trans -b -s ja -t en'

		alias e2j="{ $stdin || $xclip_sed } | $_e2j"
		alias j2e="{ $stdin || $xclip_sed } | $_j2e"
		alias e2j2e="{ $stdin || $xclip_sed } | $_e2j >&2 | $_j2e"
		alias j2e2j="{ $stdin || $xclip_sed } | $_j2e >&2 | $_e2j"

		unset xclip_sed stdin _e2j _j2e
		END
		)" \
		@soimort/translate-shell

zinit wait'0' lucid light-mode for \
	if'[[ ! -z "$(command -v pbcopy xclip xsel wl-copy)" ]]' \
	@kutsan/zsh-system-clipboard


##
# Completions
#

# This may be bundled with docker
#zinit wait'0' lucid light-mode for id-as as'completion' \
#	https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
zinit wait'0' lucid light-mode for \
	as'completion' OMZP::docker-compose/_docker-compose



##
# Other  e.g. completion, prompt, syntax-highlight...
#

zinit wait'1' lucid for \
	atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' \
		@zdharma-continuum/fast-syntax-highlighting \
	atload'_zsh_autosuggest_start; ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"' \
		@zsh-users/zsh-autosuggestions \
	blockf \
		@zsh-users/zsh-completions \
	blockf atload'
		# Arrow Key
		bindkey "$terminfo[kcuu1]" history-substring-search-up
		bindkey "$terminfo[kcud1]" history-substring-search-down
		bindkey "^[[A" history-substring-search-up
		bindkey "^[[B" history-substring-search-down

		bindkey -M emacs "^P" history-substring-search-up
		bindkey -M emacs "^N" history-substring-search-down

		bindkey -M vicmd "k" history-substring-search-up
		bindkey -M vicmd "j" history-substring-search-down
		
		# e.g. "standout,bold,underline"
		HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=0,bg=2,bold"
		HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=7,bg=8"
		# i=case-insensitive, l=smart, I=sensitive  ("Globbing Flags" in zshexpn(1))
		HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS=l
		HISTORY_SUBSTRING_SEARCH_FUZZY=1
		HISTORY_SUBSTRING_SEARCH_PREFIXED=
		HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1' \
	@zsh-users/zsh-history-substring-search


##
# Sequential Loading
#
zinit light-mode for \
	depth'1' atclone'[[ ! -f $ZDOTDIR/.p10k.zsh ]] && p10k configure' \
	if'[[ ! $TERM = "linux" ]]' \
	atinit'
		if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
			  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
		fi' \
	atload'
		. $ZDOTDIR/.p10k.zsh
		_p9k_precmd; (( ! ${+functions[p10k]} )) || p10k finalize' \
	@romkatv/powerlevel10k

# Doesn't work well with lazy loading
# zinit light-mode for depth'1' jeffreytse/zsh-vi-mode

source "${${(%):-%x}:a:h}/.zinit.d/runtime.zsh"
source "${${(%):-%x}:a:h}/.zinit.d/bin.zsh"
