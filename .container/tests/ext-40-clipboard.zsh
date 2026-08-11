#
# クリップボード経路。
#
# .zinit.zsh の has ガード相当 (command -v pbcopy xclip xsel wl-copy) が
# 通った側を検証する。既定の PTY セッションはクリップボードツールを一切
# 持たないので、PATH にスタブを載せた別セッションで走らせる (ext 群)。
#
# 検証するのは dotfiles が使う 3 経路だけ。zsh-system-clipboard、OMZ の
# clipcopy/clippaste、そこから読む trans.stdin。スタブ自身の CLI 仕様は
# この repo の責務ではない。
#
# 書き込みと読み出しは別の assertion にする。1 つのコマンド列にまとめると
# assert_output が見るのは最後のコマンドの終了コードだけになり、書き込み側の
# 失敗が隠れる。
#

assert_output "xclip がスタブを指している" \
	'command -v xclip' \
	'/usr/local/lib/dotfiles/stubs/ext/xclip'

##
# @kutsan/zsh-system-clipboard
#

assert_cond "zsh-system-clipboard-set が成功する" \
	'print -r -- zsc-round-trip | zsh-system-clipboard-set'

assert_output "zsh-system-clipboard-get が同じ内容を返す" \
	'zsh-system-clipboard-get' \
	'zsc-round-trip'

##
# OMZL::clipboard.zsh
#
# .zinit.zsh は非 turbo でこれをロードしている。clipcopy / clippaste は
# trans.stdin も使うので、実際に機能するかまで見る。
#

assert_cond "clipcopy が成功する" \
	'print -r -- omz-round-trip | clipcopy'

# OMZ の xclip 分岐は `... | xclip -selection clipboard -in &>/dev/null &|` で、
# 書き込みを disown した非同期ジョブで走らせる。つまり clipcopy が返った時点では
# まだ書き終わっていない。スクリプトで clipcopy の直後に clippaste すると
# 競合するので、書き込みの完了を待つ。負荷が高い環境でも落ちないよう長めに取る。
assert_output "clippaste が同じ内容を返す (clipcopy は非同期)" \
	'repeat 300 { [[ "$(clippaste 2>/dev/null)" == omz-round-trip ]] && break; sleep 0.1 }; clippaste' \
	'omz-round-trip'

##
# クリップボードから読む経路
#
# e2j / j2e はパイプが無いときクリップボードから入力を取る。その分岐を担うのは
# trans.stdin なので、それを直接呼ぶ。e2j 自体は呼ばない。trans を PATH に
# 持たないセッションなので末尾が必ず失敗し、どこで落ちたか言えなくなる。
#

pty_run 'print -r -- from-clipboard | clipcopy' \
	|| fatal "trans.stdin の入力を用意できなかった"

# clipcopy は書き込みを非同期で走らせるので、完了を待ってから読む。
assert_output "パイプが無いとき trans.stdin がクリップボードから読む" \
	'repeat 300 { [[ "$(clippaste 2>/dev/null)" == from-clipboard ]] && break; sleep 0.1 }; trans.stdin' \
	'from-clipboard'
