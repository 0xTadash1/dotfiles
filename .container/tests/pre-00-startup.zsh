#
# 同期ロード経路の健全性。
#
# turbo のプラグインはここには含まれない。その代わり stderr を独立して
# 見られる。疑似端末の中では stdout と stderr が混ざるため、起動時の
# エラー出力を検出できるのはここだけ。
#
# 終了コードは別に見ない。最後の print まで到達しなければ下の値検査が
# 落ちるので、終了コードだけが独立して壊れる経路はない。
#

typeset errfile=${TMPDIR:-/tmp}/dotfiles-sync-stderr.$$
# 値を伴わない typeset は同名の変数が既にあると宣言内容を印字するので、
# 必ず代入を付ける (runner の run_test_file がローカル変数を持っている)。
typeset out= err=

out=$(zsh -l -i -c 'print -rl -- $ZDOTDIR $HISTFILE $EDITOR $PAGER' 2>$errfile)
err=$(<$errfile)
rm -f -- $errfile

if [[ -z $err ]]; then
	ok "同期ロード経路で stderr が空"
else
	fail "同期ロード経路で stderr が空" "$err"
fi

typeset -a got=(${(f)out})

if [[ ${got[1]} == $HOME/.zsh ]]; then
	ok ".zshenv が ZDOTDIR を設定する"
else
	fail ".zshenv が ZDOTDIR を設定する" "ZDOTDIR=${got[1]-}"
fi

if [[ ${got[2]} == $HOME/.zsh/.zsh_history ]]; then
	ok ".zshenv が HISTFILE を ZDOTDIR 配下に向ける"
else
	fail ".zshenv が HISTFILE を ZDOTDIR 配下に向ける" "HISTFILE=${got[2]-}"
fi

# .zprofile が .profile を emulate -R sh で読む経路。非ログインシェルでは
# 読まれないので、-l で起動していることの確認も兼ねている。
#
# 見ているのは export される値だけで、$EDITOR が解決できるかは見ていない。
# nvim をイメージに入れていないのは意図的で、エディタの存在は .profile の
# 契約ではないため。
if [[ ${got[3]} == nvim ]]; then
	ok ".zprofile 経由で .profile の EDITOR が入る (値のみ)"
else
	fail ".zprofile 経由で .profile の EDITOR が入る (値のみ)" "EDITOR=${got[3]-}"
fi

if [[ ${got[4]} == less ]]; then
	ok ".zprofile 経由で .profile の PAGER が入る"
else
	fail ".zprofile 経由で .profile の PAGER が入る" "PAGER=${got[4]-}"
fi
