# Verification container

An environment for starting this repo's zsh config in a Linux container and checking it, without polluting the real machine.
`.container/run sh full` enters an interactive shell with the config in place.

> The directory name starts with a dot, so chezmoi ignores it. It is never placed on the real machine.

## Overview

```
Host                           Container (Arch Linux, user dev)

.container/run ─┬─ build ─▶ image: packages, etc.
                └─ sh ────▶ entrypoint ─▶ place config in $HOME ─▶ interactive shell

repo ──(mounted read-only)──▶ zsh config and .container/ (entrypoint)
volume ◀──(kept across runs)──▶ antidote itself, bundles, caches
```

- **Baked into the image:** only what the `Dockerfile` says (packages, walk, the user, the build input digest). Changing the `Dockerfile` needs `run build`.
- **Read from the mount:** the zsh config, and everything in `.container/` except the `Dockerfile`. Changes take effect on the next start as is.
- **Kept in the volume:** antidote itself, cloned bundles, and caches such as p10k's gitstatusd. Dropped by `run clean`.

## Files

```
.container/
├── run             host command (build / sh / clean)
├── Dockerfile      the image. Layers tools on base to make minimal and full
└── entrypoint.zsh  container entry. Checks volume freshness, places the config, starts an interactive shell
```

## Usage

```sh
.container/run build full        # build the image
.container/run sh full           # enter an interactive shell and try it by hand
.container/run clean full        # drop the cache
```

| variant   | Image contents |
| --------- | -------------- |
| `full`    | zsh, git, less, tar, bat, eza, fd, fzf, translate-shell, vivid, walk, zoxide |
| `minimal` | zsh, git, less, tar |

With `minimal`, you can try the side where settings that load only when an external tool exists (`conditional`) do not take effect. Bundles are not pinned to a revision and track upstream HEAD, so a start after `run clean` fetches them again.

> `run` runs the image for the host arch natively. The environment variables `run` takes are listed in its header comment.

## Maintenance

### Changes that need a rebuild

| Changed | Needed | Reason |
| ------- | ------ | ------ |
| anything but the `Dockerfile` | nothing | read from the mount |
| `Dockerfile` | `run build`, then `run clean` | after a package change, an old install left in the volume is not fixed |

Forgetting `run clean` after building a `Dockerfile` change makes entrypoint detect the mismatch and stop.

> Forgetting to build a `Dockerfile` change is not detected. Even a comment-only `Dockerfile` change alters the build input digest, so it needs `run clean`.

## Known limitations

- **The Darwin branch:** dirstax switches to macOS key bindings on `uname -s`, but the container is Linux, so that branch is never taken. When the host is macOS, `run sh` writes a setting into `.zshrc` that swaps in ⌘ + arrows.
- **chezmoi naming:** the real `chezmoi apply` is not used; entrypoint decodes the names and places the files. It decodes only `private_` and `dot_`, not other attributes such as `executable_` or `.tmpl`.
- **Volume in use:** if a container (from `run sh`, etc.) is using the same variant's volume, `run clean` stops without removing it. Exit that container and retry.
- **Image tags:** the `minimal` / `full` tag names are shared across arches. Rebuild when switching hosts. Also, a `--target full` build does not update the `minimal` tag, so build both when using both.
