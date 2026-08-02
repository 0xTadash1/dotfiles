#
# イメージが宣言された variant どおりに作られていることを確認する。
#
# 以降のテストは TEST_VARIANT を根拠に期待値を決める。その前提として、
# 変数と実物の対応をここで固定しておく必要がある。これが無いと、full から
# bat のインストールが消えても「bat なし」を正解として通してしまう。
#
# zsh と git は載せない。無ければ runner 自体が動かない (zsh) か zinit の
# 初回取得が失敗する (git) ので、独自の失敗モードを持たない。
#

typeset -a full_only=(bat eza fd fzf vivid walk)

# tar は Arch の base に含まれ実機には必ずあるが、arm64 のリビルドには無い。
# 無いと zinit の展開が全部失敗するのに、それが静かに起きる。
typeset c
for c in less tar; do
	if command -v $c >/dev/null 2>&1; then
		ok "$c がある (両 variant 共通)"
	else
		fail "$c がある (両 variant 共通)" "PATH 上に見つからない"
	fi
done

for c in $full_only; do
	if [[ $TEST_VARIANT == full ]]; then
		if command -v $c >/dev/null 2>&1; then
			ok "full: $c がある"
		else
			fail "full: $c がある" "full イメージに含まれていない"
		fi
	else
		if command -v $c >/dev/null 2>&1; then
			fail "minimal: $c がない" "minimal に含まれてしまっている"
		else
			ok "minimal: $c がない"
		fi
	fi
done
