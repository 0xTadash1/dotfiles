# dotfiles 検証用コンテナ
#
#   minimal: zsh, git, less, tar だけ。.zinit.zsh の has ガードが効くかを見る。
#   full:    外部ツール入り。関数・alias・キーバインドまで検証する。
#
# 対話 / 非対話はイメージではなく起動引数で切り替える (entrypoint.zsh 参照)。
#
# ベースイメージはホストの arch に合わせて run スクリプトが差し替える。
# amd64 をエミュレーションで動かすことはできない: qemu-user 下では Arch の
# zsh が外部コマンドを fork した時点でハングする (組み込みだけなら動く)。
# Alpine の musl 版 zsh は同じエミュレーションで動くので、glibc + qemu-user +
# zsh の組み合わせ固有の問題。
#   x86_64 ホスト: docker.io/library/archlinux:base (公式)
#   arm64  ホスト: docker.io/lopsided/archlinux    (非公式の multi-arch リビルド)

ARG BASE_IMAGE=docker.io/library/archlinux:base

# プラグインが入る環境の指紋。run が Dockerfile とビルド引数から計算して渡す。
# named volume に同じ値を書き込んでおき、食い違ったら entrypoint が止める。
# イメージ側でパッケージが変わっても、古い volume に残った壊れたインストールは
# warm では直らない (tar を足したあと実際に踏んだ)。
#
# entrypoint と stubs は入力に含めない。あれらはハーネスの振る舞いであって
# プラグインの入り方には影響せず、別途イメージ鮮度チェックが見ている。
ARG IMAGE_STAMP=unknown

FROM ${BASE_IMAGE} AS minimal

# pacman 7 のダウンロードサンドボックスは環境によって seccomp の設定に失敗する
# (error restricting syscalls via seccomp: 22)。使い捨てのコンテナなので
# ビルド中は一律で無効化しておく。
#
# less はベースイメージに無いが、.profile が PAGER=less を設定し
# .zprofile が READNULLCMD=$PAGER を参照するので minimal にも入れる。
#
# tar は Arch の base メタパッケージの一部で実機には必ずある。公式の amd64
# イメージにも入っているが、arm64 のリビルドには無い。無いと zinit の
# 展開が全部失敗し (gh-r のバイナリも p10k の gitstatusd も)、実機と違う姿を
# 見せてしまう。
#
# 端末ごとの terminfo は焼き込まない。使う端末は変わるので、run sh がホスト側の
# 定義を渡して entrypoint が tic で取り込む。tic は ncurses に付属する。
RUN pacman --disable-sandbox -Syu --noconfirm --needed \
        zsh git less tar \
    && rm -rf /var/cache/pacman/pkg/*

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 実機は非 root。root だと $HOME もパーミッションの前提も変わるため揃える。
RUN useradd --create-home --shell /usr/bin/zsh --uid 1000 dev

# named volume のマウント先を先に作る。イメージ側に無いと podman が
# root 所有で作ってしまい、dev が書き込めなくなる。
RUN install -d -o dev -g dev -m 0700 /home/dev/.zsh /home/dev/.zsh/.zinit \
    && install -d -o dev -g dev -m 0755 /home/dev/.cache /home/dev/.local

# グローバルスコープの ARG は、このステージで参照するために再宣言が必要。
ARG IMAGE_STAMP
RUN install -d -m 0755 /usr/local/lib/dotfiles \
    && printf '%s\n' "$IMAGE_STAMP" > /usr/local/lib/dotfiles/image-stamp

# イメージに焼くのは entrypoint とスタブだけ。設定・対応表・tests は実行時に
# mount した repo 側から読む。焼いたものと mount 側の食い違いは entrypoint が
# 起動時に検出して止める。
COPY entrypoint.zsh /usr/local/bin/dotfiles-entrypoint
# スタブは PATH には載せない。テスト群が自分の分だけ PATH に足して使う。
# 群ごとにディレクトリを分ける。今あるのは ext 群の分だけだが、1 か所に
# まとめると別の群のスタブまで効いてしまい、群の名前と実際の前提が食い違う。
COPY stubs /usr/local/lib/dotfiles/stubs
RUN chmod 0755 /usr/local/bin/dotfiles-entrypoint \
    && chmod 0755 /usr/local/lib/dotfiles/stubs/*/*

USER dev
ENV HOME=/home/dev
WORKDIR /home/dev
ENTRYPOINT ["/usr/local/bin/dotfiles-entrypoint"]


FROM minimal AS full
USER root

# zoxide と translate-shell は公式リポジトリにもあるが、.zinit.zsh が
# gh-r / sbin で自前取得する経路を検証したいので入れない。
#
# クリップボード系 (xclip, wl-clipboard) も入れない。入れると
# zsh-system-clipboard がロードされる一方 X/Wayland が無いため実行時に
# 失敗し、ガードが効いた状態より紛らわしくなる。
# git-delta は入れない。git/config は使うが zsh 設定からは参照されず、
# このコンテナの検証対象 (zsh の起動経路) に関係しない。
RUN pacman --disable-sandbox -Syu --noconfirm --needed \
        bat eza fd fzf vivid \
    && rm -rf /var/cache/pacman/pkg/*

# walk は Arch 公式リポジトリに無い (AUR)。単一バイナリなので
# GitHub Releases から直接取る。lk 関数と walk-lk-widget が依存する。
#
# version だけでなく checksum も固定する。GitHub Releases は差し替え可能なので、
# version 指定だけでは同じ物を取った保証にならない。
ARG WALK_VERSION=v1.13.0
ARG WALK_ARCH=amd64
ARG WALK_SHA256=7c3b6e28fd0eee20170a07be5ceae001e466d8948b32feb005c447f4cf7c3c21
RUN curl -fsSL -o /usr/local/bin/walk \
        "https://github.com/antonmedv/walk/releases/download/${WALK_VERSION}/walk_linux_${WALK_ARCH}" \
    && printf '%s  /usr/local/bin/walk\n' "$WALK_SHA256" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/walk

USER dev
