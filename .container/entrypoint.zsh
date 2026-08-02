#!/usr/bin/env zsh
#
# chezmoi 命名を解いて $HOME に配置し、zsh を起動する。
#
# 対応表は file-map.zsh にある。設定・対応表・tests はすべて mount した repo
# 側から読む。イメージに焼いてあるのは entrypoint 自身とスタブだけ。

emulate -L zsh
setopt err_exit no_unset pipe_fail

typeset SRC=${DOTFILES_SRC:-/mnt/dotfiles}

if [[ ! -d $SRC ]]; then
	print -ru2 -- "entrypoint: $SRC がない。repo を read-only で bind mount すること。"
	exit 1
fi

# テスト側が同じ SRC を見られるようにする。
export DOTFILES_SRC=$SRC

##
# イメージの鮮度
#
# 設定と tests は mount から読むのに、entrypoint とスタブはイメージから来る。
# 再ビルドを忘れると「新しいテスト + 古い entrypoint」の混成環境になり、
# 何を検証したのか言えなくなる。実際に古い minimal イメージで走らせる事故を
# 踏んだ。焼いたものと mount 側が食い違っていたら止める。
#

typeset -A BAKED=(
	['/usr/local/bin/dotfiles-entrypoint']='.container/entrypoint.zsh'
	['/usr/local/lib/dotfiles/stubs/ext/xclip']='.container/stubs/ext/xclip'
)

typeset -a stale=()
typeset baked rel
for baked rel in ${(kv)BAKED}; do
	if [[ ! -f $baked || ! -f $SRC/$rel ]]; then
		stale+=("$rel (見つからない)")
		continue
	fi
	if [[ "$(sha256sum < $baked)" != "$(sha256sum < $SRC/$rel)" ]]; then
		stale+=("$rel")
	fi
done

if (( ${#stale} )); then
	print -ru2 -- "entrypoint: イメージが古い。'.container/run build <variant>' をやり直すこと。"
	print -ru2 -- "  食い違っているファイル: ${(j:, :)stale}"
	exit 1
fi

##
# volume の鮮度
#
# named volume はイメージを焼き直しても残る。イメージ側でパッケージが変わると、
# 古い volume に残った壊れたインストールが warm では直らない。tar を足したあと、
# tarball だけ落ちて展開されていない zoxide が残り続けたことがある。
#
# イメージに焼いた指紋を volume にも書いておき、食い違ったら止める。
# 自動で捨てはしない。破棄は利用者の判断に委ねる。
#

typeset stamp_image=/usr/local/lib/dotfiles/image-stamp
typeset stamp_volume=$HOME/.zsh/.zinit/.image-stamp

if [[ -f $stamp_image ]]; then
	install -d -m 0700 -- "$HOME/.zsh/.zinit"
	if [[ -f $stamp_volume ]]; then
		if [[ "$(<$stamp_volume)" != "$(<$stamp_image)" ]]; then
			print -ru2 -- "entrypoint: プラグインのキャッシュがこのイメージと食い違っている。"
			print -ru2 -- "  イメージ側の環境 (パッケージ構成など) が変わっているので、"
			print -ru2 -- "  キャッシュを捨ててやり直すこと:"
			print -ru2 -- "    .container/run test <variant> cold"
			print -ru2 -- "    .container/run clean <variant>"
			exit 1
		fi
	elif [[ -n $(print -rl -- $HOME/.zsh/.zinit/*(N)) ]]; then
		# 指紋が無いのに中身がある = この仕組みより前に作られた volume。
		# どのイメージで作られたか分からないので信用しない。
		print -ru2 -- "entrypoint: プラグインのキャッシュに指紋が無い (この仕組みより前のもの)。"
		print -ru2 -- "  どのイメージで作られたか分からないので、捨ててやり直すこと:"
		print -ru2 -- "    .container/run test <variant> cold"
		exit 1
	else
		cp -- "$stamp_image" "$stamp_volume"
	fi
fi

##
# 配置
#

typeset f
for f in file-map gen-zshrc resolve-term; do
	if [[ ! -f $SRC/.container/$f.zsh ]]; then
		print -ru2 -- "entrypoint: $SRC/.container/$f.zsh がない"
		exit 1
	fi
	source $SRC/.container/$f.zsh
done

install -d -m 0700 -- "$HOME/.zsh"

typeset src dest
for src dest in ${(kv)FILE_MAP}; do
	if [[ ! -f $SRC/$src ]]; then
		print -ru2 -- "entrypoint: $SRC/$src がない"
		exit 1
	fi
	install -D -m 0644 -- "$SRC/$src" "$HOME/$dest"
done

gen_zshrc "$HOME/.zsh/.zshrc" "${DIRSTAX_KEYBINDS-}"

case ${1:-shell} in
	shell)
		resolve_term
		case $TERM_RESOLUTION in
			imported) print -ru2 -- "entrypoint: ホストの terminfo から $TERM を取り込んだ" ;;
			fallback) print -ru2 -- "entrypoint: terminfo に無い TERM だったので $TERM で起動する" ;;
		esac
		# ログインシェルとして起動する。.zprofile -> .profile の連鎖は
		# 非ログインシェルでは読まれないため。
		exec zsh -l
		;;
	test)
		shift
		typeset runner=$SRC/.container/tests/runner.zsh
		if [[ ! -f $runner ]]; then
			print -ru2 -- "entrypoint: $runner がない"
			exit 1
		fi
		# zpty -r にタイムアウトが無いので、外側で頭を押さえる。内側は pty
		# セッションごとに初回応答の予算を持つので、外側はその合計より大きく
		# 取る。内訳は README の「タイムアウト」の節にある。
		exec timeout "${TEST_TIMEOUT:-2400}" zsh "$runner" "$@"
		;;
	*)
		exec "$@"
		;;
esac
