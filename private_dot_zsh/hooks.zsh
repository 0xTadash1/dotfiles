# Called from pre:/post: in .zsh_plugins.txt

function hook:ez-compinit:pre {
	zstyle ':plugin:ez-compinit' use-cache yes
}

function hook:smartcache:pre {
	typeset -g ZSH_SMARTCACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/smartcache"
}

function hook:omzl-completion:post {
	zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
}

function hook:omzl-history:post {
	unsetopt HIST_IGNORE_DUPS HIST_VERIFY
}

function hook:pztm-terminal:pre {
	zstyle ":prezto:module:terminal" auto-title "yes"
}

function hook:gxx:post {
	local dir=$ANTIDOTE_HOME/github.com/0xTadash1/gxx.sh  # assumes the default path-style (full)
	smartcache eval source "$dir/gxx.sh"
	alias g-="git switch -"
	alias g..="git log main.."
	alias g...="git log main..."
	alias g1="g oneline"
}

function hook:fzf-tab:post {
	zstyle ":completion:*:git-checkout:*" sort false
	zstyle ":completion:*:descriptions" format "[%d]"
	zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
	zstyle ":completion:*" menu no

	EZA="eza -A --color=always --icons=always --group-directories-first"
	zstyle ":fzf-tab:complete:less:*" fzf-preview "
		if [[ -d \"\$realpath\" ]]; then
			COLUMNS=\$(( COLUMNS / 2 - 9 )) $EZA \"\$realpath\"
		else
			bat -pp --color=always \"\$realpath\"
		fi
	"
	zstyle ":fzf-tab:complete:cd:*" fzf-preview "$EZA \"\$realpath\""
	unset EZA

	zstyle ":fzf-tab:*" fzf-flags --min-height=8 --height=50%
	# There is an issue when use with fzf `--tmux` option
	# https://github.com/Aloxaf/fzf-tab/issues/455
	zstyle ":fzf-tab:*" use-fzf-default-opts yes

	# Default: F1, F2
	zstyle ":fzf-tab:*" switch-group "<" ">"
}

function hook:zsh-autosuggestions:post {
	_zsh_autosuggest_start
	ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"
	#ZSH_AUTOSUGGEST_STRATEGY="completion"
	ZSH_AUTOSUGGEST_STRATEGY="match_prev_cmd"
}

function hook:zsh-history-substring-search:post {
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
	HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
}

function hook:bat-into-tokyonight:post {
	# Use as a `man` colorizer as you like
	#export MANPAGER="sh -c 'col -bx | bat -l man -p'"
	export LESSOPEN="${LESSOPEN:-"| bat -ppf %s"}"
	alias cat='command bat -pp'
	alias bat='bat --italic-text=always --tabs 6'
	alias -g B='| bat'

	export BAT_THEME=tokyonight_night
	local dir=$ANTIDOTE_HOME/github.com/0xTadash1/bat-into-tokyonight  # assumes the default path-style (full)
	("$dir/bat-into-tokyonight" >/dev/null 2>&1 &)
}

function hook:p10k:pre {
	if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
		source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
	fi
}

function hook:p10k:post {
	. $ZDOTDIR/.p10k.zsh
	_p9k_precmd; (( ! ${+functions[p10k]} )) || p10k finalize
}
