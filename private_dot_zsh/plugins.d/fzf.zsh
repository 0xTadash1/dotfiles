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
