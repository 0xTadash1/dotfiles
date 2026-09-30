# dotfiles verification container. Pick the variant with --target (minimal / full)
#
#   base ─┬─────────── minimal
#         └─ tools ─── full
#
# Baked in: packages, walk, the user and volume mount points, the build input digest
# entrypoint, tests and stubs are used from the mounted repo

# run passes BASE_IMAGE, WALK_ARCH and WALK_SHA256 for the host arch (see run for why)
ARG BASE_IMAGE

# Digest of the build inputs (run computes it from the Dockerfile and build args)
# entrypoint compares it with the one in the volume
ARG BUILD_DIGEST=unknown


FROM ${BASE_IMAGE} AS base

# --disable-sandbox: pacman 7's download sandbox fails to set up seccomp in some environments
# (error restricting syscalls via seccomp: 22). Disposable container, so turn it off
# less: .zprofile refers to it as READNULLCMD=$PAGER
# tar: missing from the arm64 rebuild base image; p10k cannot unpack gitstatusd without it
# No terminfo baked in: run sh passes the host definition and entrypoint imports it with tic (from ncurses)
RUN pacman --disable-sandbox -Syu --noconfirm --needed \
        zsh git less tar \
    && rm -rf /var/cache/pacman/pkg/*

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Non-root user: match the real machine
# Create the volume mount points first: otherwise podman creates them as root and dev cannot write
# gpg-agent SSH support: without ssh-agent or gpg-agent, rc prints a warning at startup
# (the file goes in the XDG location rc sets as GNUPGHOME)
RUN useradd --create-home --shell /usr/bin/zsh --uid 1000 dev \
    && install -d -o dev -g dev -m 0700 \
        /home/dev/.zsh /home/dev/.zsh/.antidote /home/dev/.local/share/gnupg \
    && install -d -o dev -g dev -m 0755 /home/dev/.cache /usr/local/lib/dotfiles-verify \
    && chown dev:dev /home/dev/.local /home/dev/.local/share \
    && printf 'enable-ssh-support\n' \
        | install -o dev -g dev -m 0644 /dev/stdin /home/dev/.local/share/gnupg/gpg-agent.conf

WORKDIR /home/dev
USER dev
ENTRYPOINT ["zsh", "/mnt/dotfiles/.container/entrypoint.zsh"]


FROM base AS tools
USER root

# zoxide and translate-shell: the config does not fetch them, so install them here
# No clipboard tools: without X or Wayland they fail at runtime, which is confusing
# No git-delta: the zsh config does not use it
RUN pacman --disable-sandbox -Syu --noconfirm --needed \
        bat eza fd fzf translate-shell vivid zoxide \
    && rm -rf /var/cache/pacman/pkg/*

# walk: AUR only, so take the single binary from GitHub Releases
# Pin the checksum too: tags can be replaced
ARG WALK_VERSION=v1.13.0
ARG WALK_ARCH
ARG WALK_SHA256
RUN curl -fsSL -o /usr/local/bin/walk \
        "https://github.com/antonmedv/walk/releases/download/${WALK_VERSION}/walk_linux_${WALK_ARCH}" \
    && printf '%s  /usr/local/bin/walk\n' "$WALK_SHA256" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/walk
USER dev


# Digest last: it changes with every Dockerfile edit, so placing it earlier would rebuild
# even the package layers
# RUN, not ENV: podman reuses a cached ENV layer even when the ARG value changes

FROM base AS minimal
ARG BUILD_DIGEST
RUN printf '%s\n' "$BUILD_DIGEST" > /usr/local/lib/dotfiles-verify/build-digest

FROM tools AS full
ARG BUILD_DIGEST
RUN printf '%s\n' "$BUILD_DIGEST" > /usr/local/lib/dotfiles-verify/build-digest
