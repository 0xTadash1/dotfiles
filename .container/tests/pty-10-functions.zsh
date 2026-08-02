#
# turbo mode でロードされる関数と alias。
#
# 期待値の根拠は TEST_VARIANT (宣言値)。実測したコマンドの有無で分岐すると、
# イメージ側の欠落に適応して green になってしまう。variant と実物の対応は
# pre-05-variant.zsh が固定している。
#

typeset -i FULL=0
[[ $TEST_VARIANT == full ]] && FULL=1

##
# ガードの無いもの (minimal / full の両方で存在するべき)
#

# _zsh_autosuggest_start は実行後に自分を消すのでマーカーに使えない。
# 公開 widget と atload が設定する変数で見る。
assert_cond "zsh-autosuggestions の widget が登録される" \
	'(( ${+widgets[autosuggest-accept]} ))'

assert_output "autosuggestions の strategy が match_prev_cmd" \
	'print -r -- $ZSH_AUTOSUGGEST_STRATEGY' \
	'match_prev_cmd'

# alias は存在ではなく展開先を見る。存在だけだと中身が壊れても通る。
assert_output "gxx.sh の atload が alias g- を張る" \
	'print -r -- ${aliases[g-]}' \
	'git switch -'

assert_output "gxx.sh の atload が alias g.. を張る" \
	'print -r -- ${aliases[g..]}' \
	'git log main..'

assert_output "gxx.sh の atload が alias g1 を張る" \
	'print -r -- ${aliases[g1]}' \
	'g oneline'

##
# bat: setup-bat の has'bat' ガード
#

if (( FULL )); then
	assert_output "bat あり: alias cat が bat に差し替わる" \
		'print -r -- ${aliases[cat]}' \
		'command bat -pp'
	assert_output "bat あり: alias bat にオプションが付く" \
		'print -r -- ${aliases[bat]}' \
		'bat --italic-text=always --tabs 6'
	assert_output "bat あり: グローバル alias B が張られる" \
		'print -r -- ${galiases[B]}' \
		'| bat'
	assert_cond "bat あり: LESSOPEN が bat 経由になる" \
		'[[ $LESSOPEN == *bat* ]]'
else
	assert_cond "bat なし: alias cat が張られない" \
		'(( ! ${+aliases[cat]} ))'
	assert_cond "bat なし: グローバル alias B が張られない" \
		'(( ! ${+galiases[B]} ))'
fi

##
# walk: setup-walk の has'walk' ガード
#

if (( FULL )); then
	assert_cond "walk あり: lk 関数が定義される" \
		'(( ${+functions[lk]} ))'
else
	assert_cond "walk なし: lk 関数が定義されない" \
		'(( ! ${+functions[lk]} ))'
fi

##
# vivid: setup-lscolors の has'vivid' ガード
#

if (( FULL )); then
	# vivid の出力は key=value をコロンで並べたもの。非空も含意する。
	assert_cond "vivid あり: LS_COLORS が key=value の形" \
		'[[ $LS_COLORS == *=*:* ]]'
else
	assert_cond "vivid なし: LS_COLORS を生成しない" \
		'[[ -z $LS_COLORS ]]'
fi

##
# fzf: setup-fzf と fzf-tab の has'fzf' ガード
#

if (( FULL )); then
	assert_cond "fzf あり: FZF_DEFAULT_OPTS が設定される" \
		'[[ -n $FZF_DEFAULT_OPTS ]]'
	assert_output "fzf あり: FZF_CTRL_T_COMMAND が fd を使う" \
		'print -r -- $FZF_CTRL_T_COMMAND' \
		'fd --color=always --type=file --max-depth=5'
	# 設定した内容が fzf に受け付けられるかまで見る。無効なオプションが
	# 混ざっていても、変数が非空なだけでは分からない。
	assert_cond "fzf あり: FZF_DEFAULT_OPTS が fzf に受理される" \
		'print -r -- x | fzf --filter=x >/dev/null'
	assert_cond "fzf あり: fzf-tab がロードされる" \
		'(( ${+functions[fzf-tab-complete]} ))'
	# 内部関数名ではなく、利用者が押すキーで見る。
	assert_output "fzf あり: ^G^B が fzf-git の branch widget" \
		"bindkey '^G^B'" '"^G^B" fzf-git-branches-widget'
else
	assert_cond "fzf なし: FZF_DEFAULT_OPTS を設定しない" \
		'[[ -z $FZF_DEFAULT_OPTS ]]'
	assert_cond "fzf なし: fzf-tab をロードしない" \
		'(( ! ${+functions[fzf-tab-complete]} ))'
fi

##
# zoxide
#
# ガードは has ではなく uname で、Darwin では読み込まない。コンテナは Linux
# なので、読み込まれた側を見る。Darwin 側の枝は検証していない。
#

assert_cond "Linux では z コマンドが使える" \
	'(( ${+functions[z]} && ${+functions[zi]} ))'

assert_cond "zoxide のバイナリが実行できる" \
	'zoxide --version >/dev/null'

# 存在だけでなく、実際にディレクトリが動くことを見る。
assert_output "z で移動できる" \
	'cd /usr; z /tmp >/dev/null 2>&1; print -r -- $PWD' \
	'/tmp'

##
# 補完系
#

assert_cond "zinit の補完が登録される" \
	'(( ${+_comps[zinit]} ))'

##
# 履歴オプション
#
# 設定は「OMZ の基本設定 -> .zinit.zsh の ice -> rc」の層構造で、rc が最新かつ
# 最も変わりやすい層。仕様は全層適用後の最終状態なので、rc/options.zsh が
# 決めた値をここで主張する。.zinit.zsh の atload に何が書いてあるかは根拠に
# しない。
#

assert_cond "rc が決めた HIST_IGNORE_DUPS が最終状態として有効" \
	'[[ -o hist_ignore_dups ]]'

assert_cond "HIST_VERIFY は最終状態として無効" \
	'[[ ! -o hist_verify ]]'

assert_cond "rc の HIST_FCNTL_LOCK が有効" \
	'[[ -o hist_fcntl_lock ]]'

assert_cond "rc の HIST_SAVE_NO_DUPS が有効" \
	'[[ -o hist_save_no_dups ]]'
