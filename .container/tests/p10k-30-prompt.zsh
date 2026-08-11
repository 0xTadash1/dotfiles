#
# powerlevel10k のロードと .p10k.zsh の読み込み。
#
# 既定の PTY セッションは TERM=linux なので、.zinit.zsh の
# if'[[ ! $TERM = "linux" ]]' ガードによって p10k はロードされない。
# それだけだと 1668 行の dot_p10k.zsh を構文エラーにしても既定のテストは
# green のままなので、TERM を変えた別セッションでここを見る。
#
# 見ているのはロードと設定の読み込みまで。プロンプトの描画そのもの
# (グリフや instant prompt の 2 段出力) は検証していない。
#

assert_cond "powerlevel10k がロードされる" \
	'(( ${+functions[p10k]} ))'

# 設定ファイル固有の値。.p10k.zsh が読まれたことの確認になる。
assert_output ".p10k.zsh の左プロンプト要素の並び" \
	'print -r -- ${(j:,:)POWERLEVEL9K_LEFT_PROMPT_ELEMENTS}' \
	'dir,vcs,newline,prompt_char'

# 左プロンプトに newline 要素があるので、組み立てられた PROMPT は 2 行になる。
# 空でないことも既定値でないことも、これに含意される。
assert_cond "PROMPT が 2 行になる (要素の並びが反映されている)" \
	'[[ $PROMPT == *$'"'"'\n'"'"'* ]]'

##
# vcs セグメント (git の表示)
#
# 観測は利用者が見るものと同じにする。git リポジトリに入ったとき、
# 組み立てられたプロンプトにブランチ名が出るかを見る。
#
# 生の端末出力を走査してはいけない。自分のエコーや autosuggestions の
# 候補表示が混ざり、偽陽性になる (実際に踏んだ)。プロンプトを展開して
# マーカー間で受け取る。
#

typeset branch=gsprobe-branch
# mkdir は verbose にエイリアスされているので command で回避する。
pty_run "command mkdir -p /tmp/gsrepo >/dev/null && cd /tmp/gsrepo && git init -q -b $branch . && print -r -- ready" \
	|| fatal "vcs セグメント検証用の git リポジトリを作れなかった"

if [[ $REPLY != ready ]]; then
	fatal "vcs セグメント検証用の git リポジトリを作れなかった: $REPLY"
else
	assert_output_contains "プロンプトに git のブランチ名が出る" \
		'print -rP -- "$PROMPT"' \
		$branch
fi
