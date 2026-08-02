#
# キーを実際に押したときの挙動。
#
# pty-20 が見ているのは「widget が登録されているか」まで。同名の widget の
# 中身が壊れても pty-20 は green になる。ここでは生のキー列を zle に流し込み、
# 編集バッファがどう変わったかで検証する。
#
# キー列はブラケットペーストで包まない (包むと zle が literal 挿入して
# しまい、autopair も surround も走らない)。詳細は lib.zsh の実キー送出の節。
#

##
# zsh-autopair
#

assert_buffer_after_keys "( を押すと ) が補われる" \
	'(' \
	'()'

assert_buffer_after_keys "閉じ括弧は重ねずに読み飛ばす" \
	'(x)' \
	'(x)'

##
# surround (vicmd)
#
# ^X^V (vi-cmd-mode) で vicmd に入ってから cs / ds を送る。
# 設定は emacs モードなので、vicmd へはこの経路で入る。
#

assert_buffer_after_keys 'cs で囲みを " から '"'"' に変えられる' \
	$'"abc\x18\x16cs"\'' \
	"'abc'"

assert_buffer_after_keys 'ds で囲みを外せる' \
	$'"abc\x18\x16ds"' \
	'abc'

# 括弧からクォートへ。括弧同士の変換は vim-surround の空白規約
# (開き括弧を指定すると内側に空白が入る) が絡んで期待値が曖昧になるので避ける。
assert_buffer_after_keys "括弧の囲みをクォートに変えられる" \
	$'(abc\x18\x16cs("' \
	'"abc"'

##
# history-substring-search
#
# print -s で履歴に 1 件仕込んでから ^P を押す。仕込む文字列は
# ${:-hs} で分割して書く。そうしないとこのコマンド行自身が履歴に入って
# 検索に引っかかり、どちらを引いたのか分からなくなる。
#

pty_run 'print -s "echo ${:-hs}-target-line"' || fatal "履歴の仕込みに失敗"

assert_buffer_after_keys "^P が入力中の文字列で履歴を部分一致検索する" \
	$'hs-target\x10' \
	'echo hs-target-line'

##
# dirstax (ディレクトリ履歴の前後移動)
#
# 登録の確認は pty-20 にある。ここでは実際にキーを押して cwd が動くかを見る。
# widget は cd を実行してしまうので、編集バッファではなく副作用で検証する。
#

pty_run 'cd /tmp; cd /usr; print -r -- $PWD' || fatal "dirstax の下準備に失敗"

assert_pwd_after_keys "alt + ← で直前のディレクトリに戻る" \
	$'\e[1;3D' \
	'/tmp'

assert_pwd_after_keys "alt + → で戻る前のディレクトリに進む" \
	$'\e[1;3C' \
	'/usr'

assert_pwd_after_keys "alt + ↑ で親ディレクトリに上がる" \
	$'\e[1;3A' \
	'/'

# 通常の cd をすると forward 履歴が捨てられる (dirstax の chpwd フックの仕事)。
# フック関数名を見るのではなく、その結果で確認する。
pty_run 'cd /tmp; cd /usr; print -r -- $PWD' || fatal "forward 履歴の下準備に失敗"

assert_pwd_after_keys "戻ったあと" \
	$'\e[1;3D' \
	'/tmp'

# ここで通常の cd をすると、/usr への forward 履歴は捨てられる。
pty_run 'cd /etc; print -r -- $PWD' || fatal "cd に失敗"

assert_pwd_after_keys "通常の cd の後は forward に進めない" \
	$'\e[1;3C' \
	'/etc'
