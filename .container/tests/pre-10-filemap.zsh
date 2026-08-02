#
# FILE_MAP の drift 検出と、配置された内容の照合。
#
# chezmoi を使わない代わりに entrypoint が対応表を持っている。ここで見るのは
# 「対象範囲のソースが全部登録されているか」と「配置された内容が一致するか」。
#
# 配置先そのものの期待値は書かない。対応表を丸ごと複製しても、現実的な失敗
# モード (ファイルを増やして登録し忘れる) は下の drift 検出で捕まり、配置先を
# 誤れば設定がロードされず他の群が落ちる。
#
# ソースの実在と配置の成否は entrypoint が先に検査して落ちるので、ここでは
# 見ない (install が失敗すればコンテナが起動しない)。
#

typeset SRC=${DOTFILES_SRC:-/mnt/dotfiles}
source $SRC/.container/file-map.zsh

##
# 対象範囲のソースが全部 FILE_MAP に載っているか
#
# 新しい chezmoi ソースを足して FILE_MAP の更新を忘れる障害は、既存 5 件の
# 機能テストでは検出できない。
#

typeset -a watched=()
# 値を伴わない typeset は、同名の変数が既にあると宣言内容を印字する。
# runner の run_test_file が f をローカルに持っているので、必ず代入を付ける。
typeset p= f=
for p in $WATCHED_PATTERNS; do
	for f in ${SRC}/${~p}(N.); do
		watched+=(${f#$SRC/})
	done
done

typeset -a missing=()
for f in $watched; do
	(( ${+FILE_MAP[$f]} )) || missing+=($f)
done

if (( ${#watched} && ${#missing} == 0 )); then
	ok "対象範囲のソース ${#watched} 件が全部 FILE_MAP に載っている"
else
	fail "対象範囲のソースが全部 FILE_MAP に載っている" \
		"対象 ${#watched} 件 / FILE_MAP に無い: ${(j:, :)missing}"
fi

typeset src dest=

##
# 配置された内容が repo とバイト単位で一致するか
#
# コマンド置換で比較すると末尾改行が落ちるため、ハッシュで比較する。
#

typeset -a differ=()
typeset h1= h2=
for src dest in ${(kv)FILE_MAP}; do
	h1=$(sha256sum < $SRC/$src)
	h2=$(sha256sum < $HOME/$dest 2>/dev/null)
	[[ -n $h2 && $h1 == $h2 ]] || differ+=("$src -> $dest")
done

if (( ${#differ} == 0 )); then
	ok "配置された内容が repo のソースとバイト単位で一致する"
else
	fail "配置された内容が repo のソースとバイト単位で一致する" "差異: ${(j:, :)differ}"
fi
