function lk() { cd "$(walk --icons --preview "$@")"; }

function walk-lk-widget() {
	zle push-line-or-edit
	lk
	zle accept-line
}
zle -N walk-lk-widget
bindkey "^[[1;9B" walk-lk-widget  # ⌘ + ↓
bindkey "^[[1;3B" walk-lk-widget  # alt + ↓
