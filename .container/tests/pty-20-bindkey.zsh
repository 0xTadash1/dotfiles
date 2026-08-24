#
# キーバインドと zle widget の登録。
#
# ここで見ているのは「登録されているか」まで。実際にキーを押したときに
# widget が期待どおり動くかは検証していない。同名の widget の中身が壊れても
# このファイルは green になる。
#
# プラグインマネージャの移行では widget 名が変わらないので、この群は移行後も
# 黙って通り続ける。撤去の検討は移行完了時に行うこと。
#
# S はクォートする。rc がグローバル alias S='| sed' を張っており、裸で書くと
# bindkey -M visual | sed に展開されて sed の usage が返る。同様に
# A G H HD L LP N P R TL V X X0 も張られているので、テストのコマンド内で
# これらを裸の単語として書かないこと。
#

typeset -i FULL=0
[[ $TEST_VARIANT == full ]] && FULL=1

##
# surround (zsh 同梱の Functions/Zle/surround)
#
# .zinit.zsh では zsh-autopair の atinit で仕込んでいる。
#

# cs / ds は pty-30 が実キーで動作まで見ているので、ここでは扱わない。
# ys と visual S は実動作テストが無いので登録を確認する。
assert_output "vicmd ys が add-surround" \
	'bindkey -a ys' '"ys" add-surround'

assert_output "visual S が add-surround" \
	"bindkey -M visual 'S'" '"S" add-surround'

##
# select-quoted / select-bracketed
#
# 件数は実装のループから決まる固定値。
#   select-quoted:    {a,i} x 3 種のクォート        = 6 / keymap
#   select-bracketed: {a,i} x "()[]{}<>bB" の 10 文字 = 20 / keymap
# 1 件でも残っていれば合格にすると、大半が欠落しても検知できない。
#

assert_output "visual の select-quoted が 6 件" \
	'bindkey -M visual | grep -c select-quoted' '6'

assert_output "viopp の select-quoted が 6 件" \
	'bindkey -M viopp | grep -c select-quoted' '6'

assert_output "visual の select-bracketed が 20 件" \
	'bindkey -M visual | grep -c select-bracketed' '20'

assert_output "viopp の select-bracketed が 20 件" \
	'bindkey -M viopp | grep -c select-bracketed' '20'

# 件数だけだと未検査のキーを誤バインドして総数を保てば通るが、実装は二重
# ループなのでその失敗モードは現実的でない。代表 1 件ずつで足りる。
# widget 名だけを取り出すのは、bindkey がキーをどう引用するかに依存しないため。
assert_output "visual a' が select-quoted" \
	$'bindkey -M visual \'a\'"\'"\'\' | awk \'{print $NF}\'' \
	'select-quoted'

assert_output "viopp i( が select-bracketed" \
	"bindkey -M viopp 'i('" '"i(" select-bracketed'

##
# zsh-autopair
#

assert_cond "autopair-insert widget が登録される" \
	'(( ${+widgets[autopair-insert]} ))'

##
# history-substring-search
#

# ^P は pty-30 が実キーで検索動作まで見ている。^N と vicmd j/k は
# 実動作テストが無いので登録を確認する。
assert_output "emacs ^N が history-substring-search-down" \
	"bindkey -M emacs '^N'" '"^N" history-substring-search-down'

assert_output "vicmd k が history-substring-search-up" \
	'bindkey -a k' '"k" history-substring-search-up'

assert_output "vicmd j が history-substring-search-down" \
	'bindkey -a j' '"j" history-substring-search-down'

assert_output "検索が smart-case (globbing flag l)" \
	'print -r -- $HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS' \
	'l'

##
# dirstax (ディレクトリ履歴の前後移動)
#
# has ガードが無いので minimal でもロードされる。キーの登録は扱わない。
# pty-30 が同じ 3 キーを実キーで押して cwd の変化まで見ている。
#

# dirstax は前提として AUTO_PUSHD と NO_PUSHD_IGNORE_DUPS を立てる。これが
# 無いと履歴が積まれない。
#
# 見るのは後者だけにする。AUTO_PUSHD は rc も立てるので、有効でも dirstax が
# ロードされた根拠にならない。PUSHD_IGNORE_DUPS は rc が立てたものを dirstax が
# 落とすので、ロードと順序の両方を確定できる。
assert_cond "dirstax が PUSHD_IGNORE_DUPS を落とす" \
	'[[ ! -o pushd_ignore_dups ]]'



##
# walk の widget: has'walk' ガードで分岐する
#
# キーはプラットフォームで分岐せず、⌘ + ↓ と alt + ↓ の両方を張る。
#

if (( FULL )); then
	assert_cond "walk あり: walk-lk-widget が zle に登録される" \
		'(( ${+widgets[walk-lk-widget]} ))'
	assert_output "walk あり: alt + ↓ が walk-lk-widget" \
		"bindkey '^[[1;3B'" '"^[[1;3B" walk-lk-widget'
	assert_output "walk あり: ⌘ + ↓ も walk-lk-widget" \
		"bindkey '^[[1;9B'" '"^[[1;9B" walk-lk-widget'
else
	assert_cond "walk なし: walk-lk-widget が登録されない" \
		'(( ! ${+widgets[walk-lk-widget]} ))'
fi

##
# fzf: has'fzf' ガードで分岐する
#

if (( FULL )); then
	assert_output "fzf あり: ^T が fzf のファイル選択" \
		"bindkey '^T'" '"^T" fzf-file-widget'
	assert_output "fzf あり: ^R が fzf の履歴検索" \
		"bindkey '^R'" '"^R" fzf-history-widget'
else
	assert_cond "fzf なし: fzf-file-widget が登録されない" \
		'(( ! ${+widgets[fzf-file-widget]} ))'
	assert_cond "fzf なし: fzf-history-widget が登録されない" \
		'(( ! ${+widgets[fzf-history-widget]} ))'
fi
