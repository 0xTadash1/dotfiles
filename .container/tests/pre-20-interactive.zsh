#
# 対話パス (run sh) だけが通るロジック。
#
# .zshrc の dirstax 分岐と TERM の解決は run sh でしか実行されないため、
# 以前はテストの対象外だった。実機で踏んだ不具合を直した中心部分がそこに
# あるので、entrypoint から切り出して直接呼んで検証する。
#
# ここで見るのは生成物と解決結果まで。「生成した .zshrc を読ませた状態で
# ⌘ + 矢印が張られるか」という通しの確認は入っていない。dirstax が拡張点を
# 尊重するかまで見るには、そのために別のセッションを張ることになる。
#

typeset SRC=${DOTFILES_SRC:-/mnt/dotfiles}
source $SRC/.container/gen-zshrc.zsh
source $SRC/.container/resolve-term.zsh

typeset work=${TMPDIR:-/tmp}/pre-20.$$
mkdir -p $work

##
# .zshrc の生成
#

gen_zshrc $work/zshrc-plain
if [[ "$(<$work/zshrc-plain)" == '. $ZDOTDIR/.zinit.zsh' ]]; then
	ok "既定では .zinit.zsh を読む 1 行だけ"
else
	fail "既定では .zinit.zsh を読む 1 行だけ" "$(<$work/zshrc-plain)"
fi

gen_zshrc $work/zshrc-darwin darwin
typeset -a lines=(${(f)"$(<$work/zshrc-darwin)"})

if [[ ${lines[1]} == 'typeset -Ax dirstax=(' ]]; then
	ok "darwin 指定で dirstax の設定が先頭に来る"
else
	fail "darwin 指定で dirstax の設定が先頭に来る" "1 行目: ${lines[1]-}"
fi

# 順序が逆だと .zinit.zsh のロード後になり、拡張点として効かない。
if [[ ${lines[-1]} == '. $ZDOTDIR/.zinit.zsh' ]]; then
	ok "dirstax の設定は .zinit.zsh の読み込みより前にある"
else
	fail "dirstax の設定は .zinit.zsh の読み込みより前にある" "最終行: ${lines[-1]-}"
fi

if [[ "$(<$work/zshrc-darwin)" == *"[keybind_backward]='^[[1;9D'"* ]]; then
	ok "⌘ + ← のキーが書かれる"
else
	fail "⌘ + ← のキーが書かれる" "$(<$work/zshrc-darwin)"
fi

# 未知の値で誤って darwin 扱いにならないこと。
gen_zshrc $work/zshrc-other something-else
if [[ "$(<$work/zshrc-other)" == '. $ZDOTDIR/.zinit.zsh' ]]; then
	ok "未知の指定は既定と同じ扱いになる"
else
	fail "未知の指定は既定と同じ扱いになる" "$(<$work/zshrc-other)"
fi

##
# TERM の解決
#
# resolve_term は $TERM と $TERM_RESOLUTION を書き換えるので、サブシェルで
# 呼んで結果を受け取る。
#
# 前置代入 (TERM=x resolve_term) は使えない。zsh は関数呼び出しの前置代入を
# 呼び出し後に復元するので、続く print では外側の値に戻ってしまう。
# サブシェル内で普通に代入する。
#

typeset probe=
probe=$(TERM=xterm-256color; HOST_TERMINFO=; resolve_term; print -r -- "$TERM_RESOLUTION:$TERM")
if [[ $probe == 'unchanged:xterm-256color' ]]; then
	ok "既知の TERM はそのまま使う"
else
	fail "既知の TERM はそのまま使う" "結果:TERM = $probe"
fi

# ホストの定義を渡された未知の TERM は取り込めること。
# xterm-256color の定義を別名に付け替えて「未知の端末」を作る。
typeset ti=
ti=$(infocmp -x xterm-256color 2>/dev/null | sed '1,/^[a-zA-Z]/{s/^xterm-256color|/dotfiles-probe-term|/}')
if [[ -z $ti ]]; then
	fail "テスト用の terminfo を作れる" "infocmp が失敗した"
else
	probe=$(HOME=$work; TERM=dotfiles-probe-term; HOST_TERMINFO=$ti; resolve_term; print -r -- "$TERM_RESOLUTION:$TERM")
	if [[ $probe == 'imported:dotfiles-probe-term' ]]; then
		ok "未知の TERM はホストの定義から取り込む"
	else
		fail "未知の TERM はホストの定義から取り込む" "結果:TERM = $probe"
	fi
fi

probe=$(HOME=$work; TERM=dotfiles-no-such-term; HOST_TERMINFO=; resolve_term; print -r -- "$TERM_RESOLUTION:$TERM")
if [[ $probe == 'fallback:xterm-256color' ]]; then
	ok "定義が渡されなければ xterm-256color に落とす"
else
	fail "定義が渡されなければ xterm-256color に落とす" "結果:TERM = $probe"
fi

# 壊れた定義を渡された場合もフォールバックすること (tic が失敗する)。
probe=$(HOME=$work; TERM=dotfiles-broken-term; HOST_TERMINFO='これは terminfo ではない'; resolve_term; print -r -- "$TERM_RESOLUTION:$TERM")
if [[ $probe == 'fallback:xterm-256color' ]]; then
	ok "壊れた定義なら xterm-256color に落とす"
else
	fail "壊れた定義なら xterm-256color に落とす" "結果:TERM = $probe"
fi

rm -rf $work
