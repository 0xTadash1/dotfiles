#!/usr/bin/env zsh
#
# テストランナー。
#
# 4 群構成:
#   pre-*.zsh   疑似端末を張る前に走る。同期ロード経路と stderr を見る。
#   pty-*.zsh   疑似端末上の対話セッションで走る。TERM は既定で linux。
#   p10k-*.zsh  TERM != linux の別セッションで走る。p10k を含めるため。
#   ext-*.zsh   PATH にスタブを載せた別セッションで走る。
#
# pty セッションは同じ TERM のテスト間で 1 つを共有する。初回は zinit の
# clone に時間がかかるため、テストごとに張り直すと現実的な時間で終わらない。

emulate -L zsh
setopt no_unset pipe_fail

typeset -g TESTS_DIR=${0:A:h}
source $TESTS_DIR/lib.zsh

# variant は run スクリプトが渡す。実測値ではなく宣言値を期待値の根拠にする。
# これが無いと「full から bat が消えた」を「bat なしが正解」として通してしまう。
typeset -g TEST_VARIANT=${TEST_VARIANT-}
case $TEST_VARIANT in
	minimal|full) ;;
	*)
		print -ru2 -- "FATAL TEST_VARIANT が未設定または不正: '${TEST_VARIANT}'"
		exit 1
		;;
esac

# 既定では p10k をスキップする。.zinit.zsh の if'[[ ! $TERM = "linux" ]]'
# ガードを使うので、設定側に細工を入れずに済む。
export TERM=${PTY_TERM:-linux}

print -r -- "== dotfiles verification =="
print -r -- "variant=$TEST_VARIANT  mode=${TEST_MODE:-unknown}  TERM=$TERM  HOME=$HOME"

# プラグインは revision 固定ではなく上流の HEAD を追う。失敗を後から追える
# ようにするため、解決された revision を記録する。1 回だけ出す。
typeset -g PLUGIN_REVISIONS=
collect_revisions() {
	[[ -n $PLUGIN_REVISIONS ]] && return 0
	if pty_run 'for d in $HOME/.zsh/.zinit/plugins/*(N/); do print -r -- "  ${d:t} $(git -C $d rev-parse --short HEAD 2>/dev/null || print -r -- no-git)"; done'; then
		PLUGIN_REVISIONS=$REPLY
	fi
	return 0
}

# ファイルを 1 つ流す。source の失敗と、assertion を 1 つも実行しない
# ファイルを検出する。壊れたテストファイル自体が green を作らないようにする。
run_test_file() {
	typeset f=$1
	typeset -i before=$TESTS_RUN
	print -r -- ""
	print -r -- "-- ${f:t}"
	if ! source $f; then
		fatal "${f:t} の実行が失敗した (構文エラー、未定義変数など)"
		return 1
	fi
	if (( TESTS_RUN == before )); then
		fatal "${f:t} は assertion を 1 つも実行していない"
		return 1
	fi
	return 0
}

# 起動時に出てはいけない文字列。
#
# 一度は「readiness と機能テストがあれば冗長」として外したが、その直後に
# tar 欠落による `command not found: tar` を手動で踏んだ。zinit の展開が
# 全部失敗しても個別の assertion は素通りするので、この検査は戻した。
#
# パターンは zsh 自身のエラー書式に絞る。プラグインが説明文として同じ語を
# 出す誤検出を避けるため、コロンまで含める。
typeset -a STARTUP_ERROR_PATTERNS=(
	'command not found:'
	'parse error'
	'no matches found:'
)

# 起動から settle 完了までの出力をまとめて見る。起動時の 1 回だけの検査では、
# turbo のロード中に出たエラーを取りこぼす。
check_startup_output() {
	typeset term=$1 pat
	typeset -a hit=()
	for pat in $STARTUP_ERROR_PATTERNS; do
		[[ $PTY_OUTPUT_LOG == *${pat}* ]] && hit+=($pat)
	done
	if (( ${#hit} )); then
		fail "ロード中にエラー出力がない (TERM=$term)" \
			"検出: ${(j:, :)hit} / 出力: ${PTY_OUTPUT_LOG}"
	else
		ok "ロード中にエラー出力がない (TERM=$term)"
	fi
	return 0
}

# 同じ前提のテスト群を 1 セッションで流す。
run_pty_group() {
	typeset term=$1
	typeset -i need_key_probe=$2
	shift 2
	typeset -a files=("$@")
	typeset f

	print -r -- ""
	print -r -- "-- 対話セッションを起動 (TERM=$term)"
	if ! pty_start $term; then
		fatal "疑似端末の起動に失敗した (TERM=$term)"
		return 1
	fi

	# 前提が成立しないまま流すと、未ロードの状態を仕様として記録してしまう。
	# 警告で済ませずテストを実行しない。
	if ! pty_wait_cond '(( ${+functions[extract]} ))' 60; then
		fatal "turbo mode が動き出さなかった (TERM=$term)"
		print -ru2 -- "  起動時の出力: $PTY_START_OUTPUT"
		pty_stop
		return 1
	fi
	if ! pty_settle; then
		fatal "プラグインのロードが完了しなかった (TERM=$term)"
		print -ru2 -- "  起動時の出力: $PTY_START_OUTPUT"
		pty_stop
		return 1
	fi
	print -r -- "  ロード完了を確認"
	check_startup_output $term

	# 実キー送出のテスト用の widget は、それを使う群だけに仕込む。
	# 全群に必須化すると、probe の問題で無関係な p10k / clipboard の
	# テストまで fatal になる。
	if (( need_key_probe )); then
		if ! pty_install_key_probe; then
			fatal "編集バッファを読む widget を仕込めなかった (TERM=$term)"
			pty_stop
			return 1
		fi
	fi

	collect_revisions

	for f in $files; do
		run_test_file $f
	done

	pty_stop
	return 0
}

##
# ブートストラップ
#
# 初回は zinit の自己インストールで git clone が走り、その進捗が stderr に
# 出る。pre-* の「stderr が空」判定はそれを拾ってしまうので、先に 1 回
# 起動して同期ロード分を揃えておく。終了コードは捨てずに検証する。
#

typeset -g BOOTSTRAP_LOG=${TMPDIR:-/tmp}/dotfiles-bootstrap.log
if [[ ! -f $HOME/.zsh/.zinit/bin/zinit.zsh ]]; then
	print -r -- ""
	print -r -- "-- zinit を初期化 (初回のみ)"
	if zsh -l -i -c 'exit' >$BOOTSTRAP_LOG 2>&1; then
		ok "初回起動が終了コード 0 で終わる"
	else
		fail "初回起動が終了コード 0 で終わる" "$(tail -5 $BOOTSTRAP_LOG)"
	fi
fi

##
# テストの収集と実行
#

typeset -a pre_tests=($TESTS_DIR/pre-*.zsh(N))
typeset -a pty_tests=($TESTS_DIR/pty-*.zsh(N))
typeset -a p10k_tests=($TESTS_DIR/p10k-*.zsh(N))
typeset -a ext_tests=($TESTS_DIR/ext-*.zsh(N))

# 群が空なら失敗させる。ファイルが消えたり改名されたら、その群が無言で
# 省略されて green になる。
if (( ${#pre_tests} == 0 || ${#pty_tests} == 0 || ${#p10k_tests} == 0 || ${#ext_tests} == 0 )); then
	print -ru2 -- "FATAL テスト群が欠けている: pre=${#pre_tests} pty=${#pty_tests} p10k=${#p10k_tests} ext=${#ext_tests}"
	exit 1
fi

typeset f
for f in $pre_tests; do
	run_test_file $f
done

# pty 群にはキー送出のテストが含まれるので probe を仕込む。
run_pty_group $TERM 1 $pty_tests

# p10k は TERM != linux でしかロードされないので、セッションを分ける。
run_pty_group ${P10K_TERM:-xterm-256color} 0 $p10k_tests

# 外部コマンドをスタブに差し替えた枝。has ガードは起動時に評価されるので、
# PATH にスタブを載せた状態でセッションを張り直さないと通せない。
# OMZL::clipboard.zsh の xclip 分岐は $DISPLAY も要求する。
#
# 今ある xclip のスタブは他の枝に影響しないので 1 セッションで足りる。分離が
# 必要になるのは uname のようにロードされる枝そのものを変えるスタブだけ。
() {
	typeset saved_path=$PATH saved_display=${DISPLAY-}
	export PATH=/usr/local/lib/dotfiles/stubs/ext:$PATH
	export DISPLAY=${DISPLAY:-:0}
	run_pty_group $TERM 0 $ext_tests
	export PATH=$saved_path
	if [[ -n $saved_display ]]; then
		export DISPLAY=$saved_display
	else
		unset DISPLAY
	fi
}

# 失敗したときだけ出す。上流の HEAD を追う構成なので、失敗の追跡には要るが
# 成功時に毎回 25 行出す価値はない。
if (( TESTS_FAILED )) && [[ -n $PLUGIN_REVISIONS ]]; then
	print -r -- ""
	print -r -- "-- プラグインの revision"
	print -r -- $PLUGIN_REVISIONS
fi

print -r -- ""
print -r -- "== variant=$TEST_VARIANT run=$TESTS_RUN failed=$TESTS_FAILED fatal=$TESTS_FATAL =="

(( TESTS_FAILED == 0 ))
