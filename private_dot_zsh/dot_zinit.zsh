typeset -Ax ZINIT=(
	# [HOME_DIR]="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
	[HOME_DIR]="${ZDOTDIR:-$HOME}/.zinit"
	[NO_ALIASES]=1
)

if [[ ! -f "${ZINIT[HOME_DIR]}/bin/zinit.zsh" ]]; then
	print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
	command mkdir -p "${ZINIT[HOME_DIR]}" && command chmod g-rwX "${ZINIT[HOME_DIR]}"
	command git clone https://github.com/zdharma-continuum/zinit "${ZINIT[HOME_DIR]}/bin" && \
		print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
		print -P "%F{160}▓▒░ The clone has failed.%f%b"

	command mkdir -p "${ZINIT[HOME_DIR]}/polaris/bin"
fi

source "${ZINIT[HOME_DIR]}/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
	zdharma-continuum/zinit-annex-readurl \
	zdharma-continuum/zinit-annex-bin-gem-node \
	zdharma-continuum/zinit-annex-patch-dl \
	zdharma-continuum/zinit-annex-rust

zinit light-mode for \
	@romkatv/zsh-defer \
	@QuarticCat/zsh-smartcache

# Practical Settings
# https://github.com/ohmyzsh/ohmyzsh
zinit light-mode for \
	OMZL::completion.zsh \
	OMZL::key-bindings.zsh \
	atload'unsetopt HIST_IGNORE_DUPS HIST_VERIFY' \
	OMZL::history.zsh \
	OMZL::clipboard.zsh

zinit wait lucid light-mode for OMZP::extract

zinit wait lucid light-mode for \
	atload'zstyle ":prezto:module:terminal" auto-title "yes"' \
	PZTM::terminal

zinit wait lucid light-mode for proto'ssh' @0xTadash1/zsh-noob-init
zinit wait lucid light-mode for @0xTadash1/util.sh

zinit wait lucid light-mode for @0xTadash1/dirstax
zinit wait lucid light-mode for \
	as'null' \
	atload'
		smartcache eval source ./gxx.sh
		alias g-="git switch -"
		alias g..="git log main.."
		alias g...="git log main..."
		alias g1="g oneline"
	' \
	@0xTadash1/gxx.sh

zinit wait lucid light-mode for \
	atinit"$(<<-'END'
		# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/surround
		autoload -Uz surround
		zle -N delete-surround surround
		zle -N add-surround surround
		zle -N change-surround surround
		bindkey -a 'cs' change-surround
		bindkey -a 'ds' delete-surround
		bindkey -a 'ys' add-surround
		bindkey -M visual 'S' add-surround

		# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-quoted
		autoload -U select-quoted
		zle -N select-quoted
		for m in visual viopp; do
			for c in {a,i}{\',\",\`}; do
				bindkey -M $m $c select-quoted
			done
		done

		# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-bracketed
		autoload -U select-bracketed
		zle -N select-bracketed
		for m in visual viopp; do
			for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
				bindkey -M $m $c select-bracketed
			done
		done
	END
	)" \
	@hlissner/zsh-autopair

# `*.plugin.zsh` in repo just sets an alias
zinit wait lucid light-mode for ver'develop' sbin'translate -> trans' \
	atload"$(<<-'END'
		# sed removes hyphenations and join lines
		#   \u2010 vs \u2D == ‐ vs - == "hyphen" vs "hyphen-minus"
		#   A standard hyphen entered via keyboard is "hyphen-minus"
		trans.stdin() { [[ -p /dev/stdin ]] && command cat || clippaste; }
		trans.join_and_trim() { tr -d '\n' | tr -s '[:space:]' | sed "s/$(printf '\u2010') //g"; }
		trans.e2j() { trans -b -s en -t ja; }
		trans.j2e() { trans -b -s ja -t en; }

		e2j() { trans.stdin | trans.join_and_trim | trans.e2j; }
		j2e() { trans.stdin | trans.join_and_trim | trans.j2e; }

		e2j2e() { e2j | tee >(trans.j2e); }
		j2e2j() { j2e | tee >(trans.e2j); }
		END
	)" \
	@soimort/translate-shell
	
zinit wait lucid light-mode for \
	if'[[ ! -z "$(command -v pbcopy xclip xsel wl-copy)" ]]' \
	@kutsan/zsh-system-clipboard

##
# Completions
#

# These may be bundled with docker
#zinit wait lucid light-mode for id-as'_docker' as'completion' \
#	https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
#zinit wait lucid light-mode for \
#	as'completion' OMZP::docker-compose/_docker-compose


##
# Other  e.g. completion, prompt, syntax-highlight...
#

zinit wait lucid for \
	atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' \
		@zdharma-continuum/fast-syntax-highlighting \
	blockf atpull'zinit creinstall -q .' \
		@zsh-users/zsh-completions \
	has'fzf' atload'
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
	' \
		@Aloxaf/fzf-tab \
	atload'
		_zsh_autosuggest_start
		ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"
		#ZSH_AUTOSUGGEST_STRATEGY="completion"
		ZSH_AUTOSUGGEST_STRATEGY="match_prev_cmd"
	' \
		@zsh-users/zsh-autosuggestions \
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
		HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
	' \
		@zsh-users/zsh-history-substring-search

###
# bin
##

zinit wait lucid light-mode for id-as'setup-bat' as'null' has'bat' \
	atload"$(<<-'END'
		# Use as a `man` colorizer as you like
		#export MANPAGER="sh -c 'col -bx | bat -l man -p'"
		export LESSOPEN="${LESSOPEN:-"| bat -ppf %s"}"
		alias cat='command bat -pp'
		alias bat='bat --italic-text=always --tabs 6'
		alias -g B='| bat'

		export BAT_THEME=tokyonight_night
		(./bat-into-tokyonight >/dev/null 2>&1 &)
		END
	)" \
	@0xTadash1/bat-into-tokyonight

zinit wait lucid light-mode for id-as'setup-walk' as'null' has'walk' \
	atload'function lk() { cd "$(walk --icons --preview "$@")"; }' \
	atload'
		function walk-lk-widget() {
			zle push-line-or-edit
			lk
			zle accept-line
		}
		zle -N walk-lk-widget
		if [[ "$(uname -s)" == "Darwin" ]]; then
			bindkey "^[[1;9B" walk-lk-widget  # ⌘ + ↓
		else
			bindkey "^[[1;3B" walk-lk-widget  # alt + ↓
		fi
	' \
	@zdharma-continuum/null

zinit wait lucid light-mode for id-as'setup-lscolors' as'null' has'vivid' \
	atload'
		export LS_COLORS="$(vivid generate tokyonight-night)"
		zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
	' \
	@zdharma-continuum/null

zinit wait lucid light-mode for sbin'zoxide' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile \
	atclone'command cp -Rv ./man/. "${ZINIT[MAN_DIR]}"' \
	atpull'%atclone' \
	atload'smartcache eval zoxide init zsh' \
	@ajeetdsouza/zoxide


zinit wait lucid light-mode for \
	id-as'setup-fzf' as'null' has'fzf' \
	atload"$(<<-'END'
		fzf_yank='{ clipcopy || nohup xclip -sel clip >/dev/null 2>&1 || wl-copy || pbcopy; }'
		fzf_default_border_label=' c-y yank, c-p preview, c-s preview wrap, c-/ preview pos '
		export FZF_DEFAULT_BORDER_LABELS=(
			'^Y yank'
			'^P preview'
			'^S preview wrap'
			'^/ preview pos'
		)

		export FZF_DEFAULT_OPTS="
			--cycle
			--select-1
			--layout='reverse'
			--height='50%'
			--ellipsis='…'
			--bind='change:first'

			#--preview-window='right,hidden,<50(down)'
			--preview-window='right,hidden,<50(down,hidden)'

			--bind='ctrl-/:change-preview-window(right|down|)'

			--bind='ctrl-y:execute-silent(echo {} | $fzf_yank)'
			#--bind='ctrl-p:toggle-preview'
			--bind='ctrl-s:toggle-preview-wrap'

			--border=bottom
			--border-label-pos=bottom
			--border-label=' ""${(j:, :)FZF_DEFAULT_BORDER_LABELS[@]}"" '
		"
		
		# @folke/tokyonight.nvim
		# https://github.com/folke/tokyonight.nvim/blob/main/extras/fzf/tokyonight_night.sh
		export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
			--highlight-line \
			--info=inline-right \
			--ansi \
			--layout=reverse \
			#--border=none
			--color=bg+:#283457 \
			--color=bg:#16161e \
			--color=border:#27a1b9 \
			--color=fg:#c0caf5 \
			--color=gutter:#16161e \
			--color=header:#ff9e64 \
			--color=hl+:#2ac3de \
			--color=hl:#2ac3de \
			--color=info:#545c7e \
			--color=marker:#ff007c \
			--color=pointer:#ff007c \
			--color=prompt:#2ac3de \
			--color=query:#c0caf5:regular \
			--color=scrollbar:#27a1b9 \
			--color=separator:#ff9e64 \
			--color=spinner:#ff007c \
		"

		export FZF_CTRL_T_COMMAND='fd --color=always --type=file --max-depth=5'

		FZF_DEFAULT_BORDER_LABELS+='^V view'
		FZF_DEFAULT_BORDER_LABELS+='^H show hidden'
		FZF_DEFAULT_BORDER_LABELS+='^G show ignored'

		fzf_ctrl_t_preview_cmd='bat -pp -f --italic-text=always --tabs 6 {}'
		fzf_print_help='printf "%s\n" \
			"alt-h Close this help" \
			"alt-/ Toggle wrap" \
			"ctrl-p Toggle preview" \
			"ctrl-r Rotate preview" \
			"ctrl-y Yank" \
			"ctrl-v View with less command" \
			"ctrl-h Toggle display of hidden files" \
			"ctrl-g Toggle display of ignored files. see FD(1)"
		'

		export FZF_CTRL_T_OPTS="
			--wrap
			--preview='bat -pp -f --italic-text=always --tabs 6 {}'

			--bind='focus:transform-preview-label("'[[ -n {} ]] && echo " $(file {}) "'")'
			#--bind='ctrl-p:toggle-preview+transform-preview-label("'[[ -n {} ]] && echo " $(file {}) "'")'

			#--bind='ctrl-/:change-preview-window(down|left|top|right)'

			--bind='ctrl-h:transform:"'[[ $FZF_BORDER_LABEL =~ "show hidden" ]] \
				&& printf "%s" "change-border-label(${FZF_BORDER_LABEL/show hidden/hide hidden})" \
				|| printf "%s" "change-border-label(${FZF_BORDER_LABEL/hide hidden/show hidden})"
				echo "+reload($FZF_CTRL_T_COMMAND $(
					[[ $FZF_BORDER_LABEL =~ "show hidden" ]] && printf "--hidden"
					[[ $FZF_BORDER_LABEL =~ "show ignored" ]] || printf " --no-ignore"
				))"'"
			'
			--bind='ctrl-g:transform:"'[[ $FZF_BORDER_LABEL =~ "show ignored" ]] \
				&& printf "%s" "change-border-label(${FZF_BORDER_LABEL/show ignored/hide ignored})" \
				|| printf "%s" "change-border-label(${FZF_BORDER_LABEL/hide ignored/show ignored})"
				echo "+reload($FZF_CTRL_T_COMMAND $(
					[[ $FZF_BORDER_LABEL =~ "show hidden" ]] || printf "--hidden"
					[[ $FZF_BORDER_LABEL =~ "show ignored" ]] && printf " --no-ignore"
				))"'"
			'


			--bind='ctrl-v:execute(less --+quit-if-one-screen {})'

			--border-label=' ""${(j:, :)FZF_DEFAULT_BORDER_LABELS[@]}"" '
		"

		FZF_DEFAULT_BORDER_LABELS="${FZF_DEFAULT_BORDER_LABELS:: -3}"

		export FZF_ALT_C_OPTS="
			--walker-skip='.git,node_modules,target'
			--preview='eza --color=always --icons=always --tree --level=5 {}'
			#--preview-window='3:nowrap'
			--exit-0
		"

		export FZF_CTRL_R_OPTS="
			--no-multi-line
			--nth='2..'
			--preview='echo {2..} | bat -l=sh -pp --color=always'
			--preview-window='3:hidden:wrap'
			--bind='ctrl-y:execute-silent(echo {2..} | $fzf_yank)'
		"

		unset fzf_yank

		#source <(fzf --zsh)
		smartcache eval fzf --zsh
		END
	)" \
		@zdharma-continuum/null \
	has'fzf' \
		@junegunn/fzf-git.sh
	#id-as'_fzf' pick'completion.zsh -> _fzf' as'completion' \
	#	https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh
	#id-as'__fzf_key-bindings' \
	#	https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh

# TODO
#zinit wait lucid light-mode for id-as'add-gitignore' node'!add-gitignore' @zdharma-continuum/null

###
# runtime
##

#zinit wait'0ra' lucid light-mode for id-as'rust' sbin'bin/*' as'null' rustup \
#	atload'
#		[[ ! -f _rustup ]] && ./bin/rustup completions zsh > _rustup
#		export CARGO_HOME=$PWD
#		export RUSTUP_HOME=${PWD}/rustup
#		export PATH="${PATH}:${CARGO_HOME}/bin"' \
#	@zdharma-continuum/null


# TODO
#zinit wait"0na" lucid light-mode for \
#	atinit'VOLTA_HOME="${HOME}/.local/volta"' 0xTadash1/zsh-quick-volta


##
# Sequential Loading
#
zinit light-mode for \
	depth'1' atclone'[[ ! -f $ZDOTDIR/.p10k.zsh ]] && p10k configure; :' \
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

