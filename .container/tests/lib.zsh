#
# テスト用ヘルパ。
#
# zpty で疑似端末を張り、その中で本物の対話ログインシェルを動かす。
# zsh -i -c を使わない理由: .zinit.zsh はほぼ全部が zinit wait lucid
# (turbo mode) で、turbo は precmd フック経由でプロンプト表示後に
# ロードされる。zsh -i -c では precmd が回らないため、検証したい
# 関数・alias・キーバインドがそもそも存在しない。
#
# zpty のバッファはサブシェルに持ち越せない。$(pty_run ...) の形で呼ぶと
# 読み残しが失われて次の読み取りが崩れるので、結果は REPLY で返す。
#
# 検証する設定は「OMZ の基本設定 -> .zinit.zsh の ice -> rc」の層構造に
# なっている。仕様は全層適用後の最終状態であって、途中の層の記述ではない。
# したがってテストは settle 後の最終状態だけを主張し、.zinit.zsh に何が
# 書いてあるかを根拠に期待値を立ててはいけない。
#

zmodload zsh/zpty

typeset -g PTY_NAME=dotfiles

typeset -gi TESTS_RUN=0 TESTS_FAILED=0

# セッション内では変数経由でセンチネルを出力する。こうするとコマンドの
# エコー行には変数名しか現れず、出力行と確実に区別できる。
typeset -g MARK_BEG='@@BEG@@' MARK_END='@@END@@'
typeset -g MARK_TRUE='@@TRUE@@' MARK_FALSE='@@FALSE@@'
typeset -g MARK_STATUS='@@ST@@'

# pty_run の結果。REPLY_STATUS はセッション内で実行したコマンドの終了コード。
typeset -g REPLY=
typeset -gi REPLY_STATUS=-1

# 直前の読み取りの、マーカーで切り出す前の全文 (端末制御は落としてある)。
# マーカーより前に出た起動時のエラー出力を捨てないために保持する。
typeset -g PTY_LAST_RAW=

# セッション起動時の出力。runner がエラーの有無を検査する。
typeset -g PTY_START_OUTPUT=

# セッション開始から現在までの出力を溜めたもの。settle 中に出たエラーは
# 起動時の 1 回だけの検査では拾えないので、蓄積して後で見る。
# 際限なく伸びるとメモリを食うので末尾だけ残す。
typeset -g PTY_OUTPUT_LOG=
typeset -gi PTY_OUTPUT_LOG_MAX=65536

##
# 出力の整形
#

# 端末制御シーケンスと CR を落として REPLY に入れる。
# fast-syntax-highlighting と autosuggestions がエコー行に色を差し込むため必要。
_strip_term() {
	emulate -L zsh
	setopt local_options extended_glob
	typeset s=$1
	s=${s//$'\r'/}
	s=${(S)s//$'\e['[0-9;?]#[a-zA-Z]/}
	s=${(S)s//$'\e]'*$'\a'/}
	s=${(S)s//$'\e'[\(\)][A-Za-z0-9]/}
	REPLY=$s
}

# 最後の BEG と END の間から、終了コードの行を抜いて本文を REPLY に入れる。
# turbo のロード中はプラグインの取得メッセージが非同期に混ざるので、後ろから探す。
_extract() {
	emulate -L zsh
	setopt local_options extended_glob
	typeset -a lines=(${(f)1}) body=()
	typeset -i i b=0 e=0
	for (( i = ${#lines}; i >= 1; i-- )); do
		if (( e == 0 )) && [[ ${lines[i]} == *${MARK_END}* ]]; then
			e=i
			continue
		fi
		if (( e != 0 )) && [[ ${lines[i]} == *${MARK_BEG}* ]]; then
			b=i
			break
		fi
	done
	(( b > 0 && e > b )) || return 1

	REPLY_STATUS=-1
	for (( i = b + 1; i <= e - 1; i++ )); do
		# 末尾に改行を出さないコマンドだと、ステータスマーカーが出力の
		# 続きに連結される。行頭にある場合だけでなく、行末に付いている
		# 場合も剥がして本文を残す。
		if [[ ${lines[i]} == (#b)(*)${MARK_STATUS}(<->) ]]; then
			REPLY_STATUS=$match[2]
			[[ -n $match[1] ]] && body+=($match[1])
			continue
		fi
		body+=(${lines[i]})
	done
	REPLY=${(F)body}
	return 0
}

##
# セッション操作
#

# zpty への書き込みは zle にキー入力として渡る。素で送ると zsh-autopair が
# 括弧・角括弧・クォートを自動補完してコマンドを壊し、parse error になる。
# ブラケットペーストで囲むと bracketed-paste widget が literal 挿入するので、
# self-insert のフックを通らない。改行は終了マーカーの外に出す (中に入れると
# バッファに改行が入るだけで確定しない)。
_pty_send() {
	zpty -n -w $PTY_NAME $'\e[200~'"$1"$'\e[201~' || return 1
	zpty -n -w $PTY_NAME $'\n' || return 1
}

# 疑似端末を張って対話ログインシェルを起動する。
# TERM はセッション開始時に決まるので引数で渡す。p10k の検証だけは
# TERM != linux が要るため、別セッションを張り直す必要がある。
pty_start() {
	typeset term=${1:-${TERM:-linux}} saved=$TERM
	typeset -i rc
	export TERM=$term
	zpty $PTY_NAME zsh -l -i
	rc=$?
	export TERM=$saved
	(( rc == 0 )) || return 1

	# センチネルの値を変数に入れておく。右辺を分割して書くのは、この行の
	# エコーに MARK_BEG そのものが現れると _extract が誤検出するため。
	_pty_send "typeset -g __B=@@\${:-BEG}@@ __E=@@\${:-END}@@ __T=@@\${:-TRUE}@@ __F=@@\${:-FALSE}@@ __S=@@\${:-ST}@@" || return 1

	# 最初の応答を待つ。初回はここで zinit の自己インストールと
	# 全プラグインの clone が走るので、読み取りの上限を長めに取る。
	# 外側の全体 timeout (TEST_TIMEOUT) より小さくしておくこと。等しいと
	# 内側の上限に達する前に外側が全体を殺してしまう。
	PTY_START_OUTPUT=
	PTY_OUTPUT_LOG=
	pty_run 'print -r -- started' ${PTY_START_TIMEOUT:-600} || return 1
	# マーカーより前に出た起動時の出力ごと保持する。
	PTY_START_OUTPUT=$PTY_LAST_RAW
	return 0
}

pty_stop() {
	zpty -d $PTY_NAME 2>/dev/null
	return 0
}

# 終了マーカーが出るまで読む。上限付き。
#
# zpty -r にはタイムアウトが無い。パターン付きの読み取りはマーカーが永久に
# 来なければ永久に待つ。zle が widget の引数待ちで止まっていると実際にそう
# なる (キー送出のテストで踏んだ)。ハングはデバッグできないので、上限を
# 超えたら失敗として返す。
_pty_read_until_end() {
	typeset -i limit=$(( ${1:-${PTY_READ_TIMEOUT:-120}} * 10 )) i
	typeset chunk buf=
	for (( i = 1; i <= limit; i++ )); do
		if zpty -r -t $PTY_NAME chunk 2>/dev/null; then
			buf+=$chunk
			if [[ $buf == *${MARK_END}* ]]; then
				REPLY=$buf
				return 0
			fi
		else
			# 読めるものが無い。セッションが死んでいたら打ち切る。
			zpty -t $PTY_NAME 2>/dev/null || break
			sleep 0.1
		fi
	done
	REPLY=$buf
	return 1
}

# セッション内でコマンドを実行し、標準出力を REPLY、終了コードを
# REPLY_STATUS に入れる。always ブロックを使うので、コマンドが失敗しても
# 終了コードとマーカーは必ず返る。
pty_run() {
	typeset cmd=$1
	typeset -i tmout=${2:-0}
	REPLY=
	REPLY_STATUS=-1
	_pty_send "print -r -- \$__B; { $cmd } always { print -r -- \$__S\$?; print -r -- \$__E }" || return 2
	if (( tmout > 0 )); then
		_pty_read_until_end $tmout || return 2
	else
		_pty_read_until_end || return 2
	fi
	_strip_term $REPLY
	PTY_LAST_RAW=$REPLY
	PTY_OUTPUT_LOG+=$REPLY
	(( ${#PTY_OUTPUT_LOG} > PTY_OUTPUT_LOG_MAX )) \
		&& PTY_OUTPUT_LOG=${PTY_OUTPUT_LOG[-PTY_OUTPUT_LOG_MAX,-1]}
	_extract $REPLY || return 2
	return 0
}

# セッション内で条件を評価する。真なら 0、偽なら 1、読めなければ 2。
pty_cond() {
	pty_run "{ $1 } >/dev/null 2>&1 && print -r -- \$__T || print -r -- \$__F" || return 2
	[[ $REPLY == *${MARK_TRUE}* ]] && return 0
	[[ $REPLY == *${MARK_FALSE}* ]] && return 1
	return 2
}

# 条件が真になるまで繰り返す。1 回の pty_run が precmd を 1 周させるので、
# これが zinit のスケジューラを進める役も兼ねる。
pty_wait_cond() {
	typeset cmd=$1
	typeset -i tries=${2:-60} i
	for (( i = 1; i <= tries; i++ )); do
		pty_cond $cmd && return 0
	done
	return 1
}

# 全プラグインのロードが終わるまで待つ。
#
# turbo は precmd ごとに段階的にロードされる。特定のプラグインのマーカーを
# 待つだけでは過渡状態を見てしまい、テストの本数を変えただけで結果が変わる。
#
# zinit がいる場合は @zinit-scheduler burst でキューを一気に消化させる。
# burst は待ち時間を経過扱いにするので、段階ロードを待つ必要がなくなる。
# ZINIT_TASKS は残りキューで、"<no-data>" の 1 要素だけになれば空。
#
# zinit が無い場合はプラグインマネージャの移行後とみなし、定義済みシンボルの
# 数が変わらなくなるまで待つ方式にフォールバックする。
pty_settle() {
	# pty_cond は 真=0 / 偽=1 / 読み取り失敗=2 を返す。if で受けると 1 と 2 が
	# 同じ偽になり、一時的な読み取り失敗を「zinit がいない」と誤認して
	# キュー確認を丸ごと飛ばしてしまう。case で分ける。
	pty_cond '(( ${+functions[@zinit-scheduler]} ))'
	case $? in
		0)
			typeset -i i
			for (( i = 1; i <= 60; i++ )); do
				pty_cond '(( ${#ZINIT_TASKS} <= 1 ))'
				case $? in
					0) break ;;
					1) ;;
					*) return 1 ;;
				esac
				pty_run '@zinit-scheduler burst >/dev/null 2>&1; print -r -- burst' || return 1
			done
			# ループを抜けた理由が上限到達なら失敗させる。キューが残った状態を
			# 「落ち着いた」と扱うと、止まったダウンロードや失敗したジョブを
			# 見逃す。
			pty_cond '(( ${#ZINIT_TASKS} <= 1 ))'
			(( $? == 0 )) || return 1
			;;
		1)
			# zinit がいないので、静止判定だけで進む。
			;;
		*)
			return 1
			;;
	esac
	_pty_settle_quiesce
}

# 関数・widget・alias・補完の定義数が変化しなくなるまで待つ。ダウンロード待ちの
# 空白を静止と誤認しないよう、間隔を空けて複数回続けて一致することを条件にする。
_pty_settle_quiesce() {
	typeset -i stable=0 i tries=${1:-90} need=${2:-5} delay=${3:-1}
	typeset prev= cur
	for (( i = 1; i <= tries; i++ )); do
		pty_run 'print -r -- ${#functions}:${#widgets}:${#aliases}:${#galiases}:${#_comps}' || return 1
		cur=$REPLY
		if [[ -n $cur && $cur == $prev ]]; then
			(( ++stable >= need )) && return 0
		else
			stable=0
		fi
		prev=$cur
		sleep $delay
	done
	return 1
}

##
# 実キー送出
#
# 「widget が登録されているか」ではなく「キーを押したら期待どおり動くか」を
# 見るための経路。コマンド送出とは要件が正反対で、zle に 1 文字ずつ解釈させる
# 必要があるためブラケットペーストを使わない。
#
# 編集バッファは外から覗けないので、バッファをファイルに書き出す widget を
# セッションに仕込んでおき、キー列の最後に ^X^N でそれを呼ぶ。
#
# 2 バイト目に端末の特殊文字を使わないこと。^X^D にしていたときは、リセットに
# 送った ^G (send-break) で zle が抜けた直後の canonical mode で ^D が EOF と
# 解釈され、セッションが死んだ。^N は特殊文字ではない。
#

typeset -g PTY_KEY_BUF=/tmp/dotfiles-zle-buffer

pty_install_key_probe() {
	# widget はバッファを書き出したら空にして main キーマップに戻す。
	# vicmd のまま残すと、次に送るブラケットペーストの ESC 列が
	# vicmd のキーとして解釈されて壊れる。
	_pty_send "function _test_dump_buffer() { print -r -- \"\$BUFFER\" >! $PTY_KEY_BUF; BUFFER=''; CURSOR=0; zle -K main }; zle -N _test_dump_buffer" || return 1
	pty_run 'print -r -- widget-defined' || return 1

	_pty_send "for _m in main emacs viins vicmd visual viopp; do bindkey -M \$_m '^X^N' _test_dump_buffer; done; unset _m" || return 1
	pty_run 'print -r -- keys-bound' || return 1

	# 仕込みが効いていないまま進むと、キー送出のテストが「ファイルが無い」で
	# 落ちて原因が分からなくなる。widget と binding の両方をここで確かめる。
	if ! pty_cond "(( \${+widgets[_test_dump_buffer]} ))"; then
		print -ru2 -- "  probe: widget _test_dump_buffer が登録されていない"
		return 1
	fi
	pty_run "bindkey -M main '^X^N'" || return 1
	if [[ $REPLY != *_test_dump_buffer* ]]; then
		print -ru2 -- "  probe: main の ^X^N が dump widget に向いていない: $REPLY"
		return 1
	fi
	return 0
}

# 生のキー列を送る (ブラケットペーストで包まない)
_pty_send_keys() {
	zpty -n -w $PTY_NAME "$1" || return 1
}

# キー列を送り、その結果の編集バッファを REPLY に入れる。
pty_buffer_after_keys() {
	# 毎回消す。固定パスを使い回すと、widget が発火しなくても前回の値が
	# 残っていて偶然一致する余地が生まれる。
	pty_run "rm -f $PTY_KEY_BUF" || return 2

	# 前のテストがバッファを残している可能性があるので ^U で消す。
	# ^G (send-break) は使わない。zle を抜けた直後の canonical mode に
	# 続く 2 バイト目が渡ると、端末の特殊文字として解釈されてしまう。
	_pty_send_keys $'\x15' || return 2
	_pty_send_keys "$1" || return 2
	_pty_send_keys $'\x18\x0e' || return 2   # ^X^N
	# 読み取りの上限を短くする。zle が引数待ちで止まると永久に返らないので、
	# 早めに失敗にして次のテストへ進ませる。
	pty_run "cat $PTY_KEY_BUF" ${PTY_KEY_TIMEOUT:-20} || return 2
	# ファイルが無ければ widget が発火していない。値の不一致とは区別する。
	(( REPLY_STATUS == 0 )) || return 3
	return 0
}

# キー列を送ったあとの cwd を確認する。dirstax のようにコマンドを実行して
# しまう widget は、編集バッファではなく副作用で検証する。
assert_pwd_after_keys() {
	typeset desc=$1 keys=$2 want=$3
	if ! _pty_send_keys $keys; then
		fail $desc "キー送出に失敗"
		return 0
	fi
	if ! pty_run 'print -r -- $PWD' ${PTY_KEY_TIMEOUT:-20}; then
		fail $desc "キー送出後の PWD を読めなかった"
		return 0
	fi
	if [[ $REPLY == $want ]]; then
		ok $desc
	else
		fail $desc "期待: $want / 実際: $REPLY"
	fi
	return 0
}

assert_buffer_after_keys() {
	typeset desc=$1 keys=$2 want=$3
	pty_buffer_after_keys $keys
	case $? in
		0) ;;
		3)
			fail $desc "dump widget が発火しなかった (バッファファイルが無い)"
			return 0
			;;
		*)
			fail $desc "キー送出後のバッファを読めなかった"
			return 0
			;;
	esac
	if [[ $REPLY == "$want" ]]; then
		ok $desc
	else
		fail $desc "期待: $want / 実際: $REPLY"
	fi
	return 0
}

##
# 判定
#

typeset -gi TESTS_FATAL=0

# テストの前提が崩れた場合。結果は無効なので失敗として扱う。
fatal() {
	(( TESTS_FATAL++, TESTS_FAILED++ ))
	print -ru2 -- "  FATAL $1"
	return 0
}

ok() {
	(( TESTS_RUN++ ))
	print -r -- "  ok    $1"
	return 0
}

fail() {
	(( TESTS_RUN++, TESTS_FAILED++ ))
	print -ru2 -- "  FAIL  $1"
	[[ -n ${2-} ]] && print -ru2 -- "        ${2//$'\n'/ | }"
	return 0
}

# セッション内で条件が真であることを確認する
assert_cond() {
	typeset desc=$1 cmd=$2
	pty_cond $cmd
	case $? in
		0) ok $desc ;;
		1) fail $desc "偽: $cmd" ;;
		*) fail $desc "セッションからの読み取りに失敗: $cmd" ;;
	esac
	return 0
}

# セッション内でコマンドを実行し、終了コードが 0 かつ出力が期待値と
# 完全に一致することを確認する。
assert_output() {
	typeset desc=$1 cmd=$2 want=$3
	if ! pty_run $cmd; then
		fail $desc "セッションからの読み取りに失敗: $cmd"
		return 0
	fi
	if (( REPLY_STATUS != 0 )); then
		fail $desc "終了コード $REPLY_STATUS: $cmd / 出力: $REPLY"
		return 0
	fi
	if [[ $REPLY == "$want" ]]; then
		ok $desc
	else
		fail $desc "期待: $want / 実際: $REPLY"
	fi
	return 0
}

# 部分一致版。プロンプトのように利用者向けの装飾が混ざる出力に使う。
# 既定は assert_output (完全一致) を使うこと。
assert_output_contains() {
	typeset desc=$1 cmd=$2 want=$3
	if ! pty_run $cmd; then
		fail $desc "セッションからの読み取りに失敗: $cmd"
		return 0
	fi
	if (( REPLY_STATUS != 0 )); then
		fail $desc "終了コード $REPLY_STATUS: $cmd / 出力: $REPLY"
		return 0
	fi
	if [[ $REPLY == *"$want"* ]]; then
		ok $desc
	else
		fail $desc "期待 (部分一致): $want / 実際: $REPLY"
	fi
	return 0
}
