#
# TERM の解決。entrypoint とテストの両方がこれを読む。
#
# TERM の terminfo が無いと zle がカーソル移動できず、入力した文字が重複して
# 見える。色も出ない (syntax highlight だけは生の SGR なので出る)。
#
# 端末ごとに terminfo パッケージを焼き込むのはやめて、run が渡したホスト側の
# 定義を取り込む。ghostty も kitty も ncurses には入っていないので、
# 焼き込み方式では使う端末を変えるたびに破綻する。
#
# entrypoint に直接書いていたが、それだと 3 つの経路を検証できなかった。
#

# resolve_term
#
# $TERM と $HOST_TERMINFO を見て、必要なら terminfo を取り込むか TERM を
# 無難な値に落とす。結果は $TERM と $TERM_RESOLUTION に反映する。
#
#   unchanged … 変更不要 (terminfo が既にある)
#   imported  … ホストの定義を取り込んだ
#   fallback  … 取り込めなかったので $TERM_FALLBACK に落とした
#
# 結果は終了コードではなく変数で返し、常に 0 を返す。呼び出し側は
# setopt err_exit で動くので、非 0 を返すと裸で呼んだ時点でスクリプトが
# 黙って終わる (実際に踏んで run sh が起動しなくなった)。終了コードを
# データチャネルに使わないことで、その罠を設計から消す。
typeset -g TERM_RESOLUTION=

resolve_term() {
	emulate -L zsh
	typeset fallback=${TERM_FALLBACK:-xterm-256color}

	TERM_RESOLUTION=unchanged
	[[ -n ${TERM-} ]] || return 0
	infocmp "$TERM" >/dev/null 2>&1 && return 0

	if [[ -n ${HOST_TERMINFO-} ]]; then
		print -r -- "$HOST_TERMINFO" | tic -x -o "$HOME/.terminfo" - 2>/dev/null || true
		if infocmp "$TERM" >/dev/null 2>&1; then
			TERM_RESOLUTION=imported
			return 0
		fi
	fi

	export TERM=$fallback
	TERM_RESOLUTION=fallback
	return 0
}
