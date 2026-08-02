#
# .zshrc の生成。entrypoint とテストの両方がこれを読む。
#
# entrypoint に直接書いていたが、それだと生成される内容を検証できなかった。
# 実際に利用する対話パス (run sh) だけが通る分岐なので、テストの対象外に
# しておくと環境変数名や生成順序が壊れても気付けない。
#
# .zshrc は repo の管理外。変更頻度が高いため意図的に外してあり、実機では
# apply 後に手作業で `. $ZDOTDIR/.zinit.zsh` を追記する運用になっている。
# ここではその形を再現する。
#

# gen_zshrc <出力先パス> [dirstax のキー割り当て]
#
# 第 2 引数が darwin のとき、dirstax に ⌘ + 矢印を使わせる指定を先に書く。
# dirstax は uname -s で分岐するのでコンテナ (Linux) では alt 側を選ぶが、
# ホストが macOS のときは Mac の指の慣性のまま使いたい。プラグインが
# 用意している拡張点 (先に値が入っていれば上書きしない) を使うので、
# repo の設定もプラグイン本体も触らない。
#
# キーは bindkey のキャレット記法。^[ は 2 文字で書く (ESC そのものではない)。
gen_zshrc() {
	emulate -L zsh
	typeset dest=$1 keybinds=${2-}

	{
		if [[ $keybinds == darwin ]]; then
			print -r -- 'typeset -Ax dirstax=('
			print -r -- "	[keybind_upward]='^[[1;9A'"
			print -r -- "	[keybind_forward]='^[[1;9C'"
			print -r -- "	[keybind_backward]='^[[1;9D'"
			print -r -- ')'
		fi
		print -r -- '. $ZDOTDIR/.zinit.zsh'
	} > $dest
}
