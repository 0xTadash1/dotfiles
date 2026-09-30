# Verification container

An environment for starting this repo's zsh config in a Linux container and checking it, without polluting the real machine.

| Use            | Command                    | What happens |
| -------------- | -------------------------- | ------------ |
| Try it by hand | `.container/run sh full`   | Enters an interactive shell with the config in place |
| Run the tests  | `.container/run test full` | Starts the config and checks automatically that the combination is not broken |

> The directory name starts with a dot, so chezmoi ignores it. It is never placed on the real machine.

## Overview

```
Host                           Container (Arch Linux, user dev)

.container/run ─┬─ build ─▶ image: packages, etc.
                ├─ sh ────▶ entrypoint ─▶ place config in $HOME ─▶ interactive shell
                └─ test ──▶ entrypoint ─▶ place config in $HOME ─▶ runner

repo ──(mounted read-only)──▶ zsh config and .container/ (entrypoint, tests, stubs)
volume ◀──(kept across runs)──▶ antidote itself, bundles, caches
```

- **Baked into the image:** only what the `Dockerfile` says (packages, walk, the user, the build input digest). Changing the `Dockerfile` needs `run build`.
- **Read from the mount:** the zsh config, and everything in `.container/` except the `Dockerfile`. Changes take effect on the next run as is.
- **Kept in the volume:** antidote itself, cloned bundles, and caches such as p10k's gitstatusd. Dropped by `cold` or `run clean`.

## Files

```
.container/
├── run               host command (build / sh / test / clean)
├── Dockerfile        the image. Layers tools on base to make minimal and full
├── entrypoint.zsh    container entry. Checks volume freshness, places the config, starts an interactive shell or runner
├── stubs/
│   └── xclip         xclip stub put on PATH in the full tests
└── tests/
    ├── runner.zsh    test entry. Image contents check, first start, and running the tests in the session
    ├── lib.zsh       session control (running commands, sending keys) and assertion helpers
    ├── 10-state.zsh  tests for load conditions, hook wiring and layer overrides
    └── 20-keys.zsh   tests that real keys reach the intended widget
```

## Usage

```sh
.container/run build full        # build the image
.container/run sh full           # enter an interactive shell and try it by hand
.container/run test full         # run the tests (warm)
.container/run test full cold    # drop the cache, then run
.container/run clean full        # drop the cache
```

`minimal` can be passed instead of `full`. The difference is in "How the tests work".

| Goal | What to run |
| ---- | ----------- |
| Quick check after changing the config | `test full` and `test minimal` (warm) |
| Check a new machine's first start | `test full cold` and `test minimal cold` |
| Pick up upstream HEAD changes | cold (fetches the bundles again) |

> `run` runs the image for the host arch natively. The environment variables `run` takes are listed in its header comment.

## How the tests work

### Flow of one run

```
run test <variant> <mode>
│  drops the volume on cold
▼
entrypoint     checks volume freshness, decodes chezmoi names and places the config
▼
runner         overall limit 45s, 120s when the cache is empty (set by entrypoint)
├─ ① image contents match the variant                  FATAL if not
├─ ② first start  zsh -l -i -c exit
│      output is only fetch progress                     (1 check)
└─ ③ session      interactive login shell under script
       ├─ wait for deferred loading to finish
       ├─ stderr so far is empty                         (1 check)
       ├─ 10-state.zsh  loading, hooks, layer overrides, final state
       └─ 20-keys.zsh   real keys reach the intended widget
```

- **First start:** starts the config once and checks that nothing extra is printed. On cold, this corresponds to a new machine's first start.
- **Session:** runs a real interactive login shell. Most plugins are deferred and load after the prompt shows, so under `zsh -i -c` the functions and keys under test do not exist.
- **Waiting for deferred loading:** queues a sentinel at the end of the zsh-defer queue and waits until it runs. The queue runs in order, so once the sentinel runs, every deferred task queued before it has finished.

### How the session works

```
runner ── in (FIFO) ──▶ script ──▶ pty ──▶ zsh -l -i (zle)
   ▲                      │
   │                      └──▶ log (pty output. Read by the terminal title test)
   └──── out (FIFO) ◀─── { command } >out   (opened and closed once per command)
```

- **Running a command:** runner writes the command to in and reads out. out is opened and closed per command, so when the read returns on EOF the command has finished. The last line is the exit status.
- **Sending keys:** writes raw key sequences to in. The edit buffer is read from a file that an installed widget writes.
- **script owns the pty:** it keeps reading the output and writes it to log. If runner owned it, it would have to drain it forever so the shell does not block on unread output.

### variant: both sides of each condition

The config's `conditional`s are evaluated at startup, so one run only takes one side. The variants provide both sides.

| variant   | Image contents | Session environment | Conditions |
| --------- | -------------- | ------------------- | ---------- |
| `full`    | zsh, git, less, tar, bat, eza, fd, fzf, translate-shell, vivid, walk, zoxide | `TERM=xterm-256color`, xclip stub on `PATH` | all hold |
| `minimal` | zsh, git, less, tar | `TERM=linux`, no clipboard tool | none hold |

The conditions are independent of each other, so not every combination is tested. Tests switch expectations on the `TEST_VARIANT` that `run` passes, not on measuring which commands exist. Branching on measured results would pass "no bat" as correct when bat goes missing from full.

> runner sets TERM and the stub to match the variant. The stub goes on PATH only for the full tests: it only shows that xclip exists, so having it on PATH would be confusing when trying `run sh full` by hand.

### cold and warm: cache and network

`warm` (the default) reuses the cache; `cold` drops it before running.

antidote itself, each bundle, and p10k's gitstatusd are fetched only when missing, and what is fetched stays in the volume. So only a start with an empty cache reaches the network.

| mode | First start | Session |
| ---- | ----------- | ------- |
| cold | fetches everything (uses the network) | uses what the first start fetched |
| warm | fetches nothing (if cached) | fetches nothing |

- warm with a cache goes green even with `--network none`. warm right after build or clean has an empty cache, so it fetches like cold.
- cold's first start corresponds to a new machine's first start. Cloning, smartcache cache generation and the gitstatusd fetch only happen there, so their errors only show up there.
- Bundles are not pinned to a revision and track upstream HEAD. A change that fails on cold can pass on warm.

### Reading the results

| Output  | Meaning |
| ------- | ------- |
| `ok`    | as expected |
| `FAIL`  | not as expected |
| `FATAL` | a test premise broke and the result is invalid (image contents mismatch, time limit, etc.) |

`FAIL` and `FATAL` both count as failures. When a run has failures, it prints the resolved bundle revisions. `test` does not pass `COLORTERM`, so the host terminal does not change the results.

### Time limit

The only limit is the one entrypoint puts on the whole run; hitting it is FATAL.

| Cache | Limit | Measured (full, 2026-09-30) |
| ----- | ----- | --------------------------- |
| present (warm) | 45s  | 4–5s   |
| empty (cold, warm right after build or clean) | 120s | 30–52s |

- Only the first start with an empty cache uses the network (see "cold and warm"), so only that case gets more time.
- No limit on a single read inside the session. Giving up on one and moving on would let the next read take the late result, and every result after that would be off. Where it stopped shows in the output just before the cutoff.

> On timeout, the counts and revisions are not printed. script prints "Session terminated, killing shell...", which only means it was stopped by the time limit.

## What is verified

The job of this repo's config is to combine plugins. So it verifies **only what the combination can break**.

### Checked

| Aspect | Examples |
| ------ | -------- |
| Load conditions | fzf-tab loads only when fzf exists, p10k loads only when TERM is not linux |
| Hook wiring | gxx.sh's post hook runs |
| Load order and layer overrides | dirstax unsets the `PUSHD_IGNORE_DUPS` rc set, fzf's `^R` overrides OMZ's `^R` |
| Keys reaching widgets | `(` gets its `)`, alt + ← goes back to the previous directory |
| Startup output | no extra output or errors from the first start or the session start |

### Not checked

| Target | Reason |
| ------ | ------ |
| How plugins behave given settings (prompt contents, fzf options, the autosuggestions strategy, etc.) | the plugins' job |
| Setting values themselves | copying them into expectations only copies the declarations |
| Loading of each bundle with neither a condition nor a hook | a bundle that fails to load prints an error, which the startup output check catches (except "Bundles that silently do nothing" under Known limitations) |
| `e2j` / `j2e` and `trans.stdin` in `plugins.d/trans.zsh` | outside this repo's job. Only the load condition is checked |
| The `run sh` path, rebuilding the dump when `.zsh_plugins.txt` changes | checking once is enough (the dump was checked on 2026-09-30) |

## Maintenance

### Changes that need a rebuild

| Changed | Needed | Reason |
| ------- | ------ | ------ |
| anything but the `Dockerfile` | nothing | read from the mount |
| `Dockerfile` | `run build`, then cold | after a package change, an old install left in the volume is not fixed by warm |

Forgetting cold after building a `Dockerfile` change makes entrypoint detect the mismatch and stop.

> Forgetting to build a `Dockerfile` change is not detected. Even a comment-only `Dockerfile` change alters the build input digest, so it needs cold.

### Adding tests

- **Adding or removing a bundle:** a bundle with neither a condition nor a hook needs no test change. When adding a bundle with a condition, add one `assert_only_in_full` line to `10-state.zsh`. When it has a hook, add an assertion that the hook ran.
- **Adding a condition evaluated at startup:** make its two sides fall into full and minimal. A condition the variants cannot produce (such as a stub like `uname` that changes which branch loads) needs a separate session.
- **Writing a test that deals with the pty:** read the comments on each helper in `tests/lib.zsh` first. Why `zsh -i -c` is not used, how to wait for loading to finish, when to use bracketed paste versus sending real keys: there is a lot to trip over otherwise.

## Known limitations

Going green within this scope does not mean the whole zsh config is verified.

### Failures not detected

- **Bundles that silently do nothing:** a sourced bundle prints an error when the file to load is missing, so the stderr check catches it. A `kind:fpath` bundle whose `path:` points to a missing directory just has that directory added to fpath without output, and the tests pass (checked on 2026-09-30). In this config that is zsh-completions, and completions silently disappear.
- **Dependency on `defer-options`:** deferred plugins' stderr is visible because `init.zsh` sets `defer-options '-12'`. Without it, deferred plugins' errors are discarded and the stderr check silently passes (checked on 2026-09-30). This dependency itself is not tested.
- **`.p10k.zsh` wiring:** when the wiring by which `hook:p10k:post` reads `.p10k.zsh` breaks, p10k shows its configuration wizard and waits for input. It shows up not as FAIL but as a timeout (FATAL) of the whole full run.

### Out of scope

- **Real key coverage:** four are pressed: autopair, surround, history-substring-search and dirstax. fzf widgets, `fzf-tab` completion and `walk-lk-widget` are interactive to run, so they are not pressed. For fzf the tests go only as far as checking that `^R` points to fzf's widget, and for `fzf-tab` and walk only as far as loading. Adding stubs would cover them.
- **Clipboard:** the xclip stub only shows that it exists and neither reads nor writes.
- **The `run sh` path:** generating `.zshrc` (including dirstax keys for macOS), importing terminfo, and passing `TERM` and `COLORTERM` are not tested, because using `run sh` shows them right away.
- **The Darwin branch:** dirstax switches to macOS key bindings on `uname -s`, but both the real Arch machine and the container are Linux, so that branch never runs. macOS is not a target environment of these dotfiles, so the branch is left unverified on purpose. A session with a `uname` stub would cover it.
- **chezmoi naming:** the real `chezmoi apply` is not used; entrypoint decodes the names and places the files. It decodes only `private_` and `dot_`, not other attributes such as `executable_` or `.tmpl`. Using them would change the placed names, the config would fail to load, and the tests would fail.

### Operational notes

- **Volume in use:** if a container (from `run sh`, etc.) is using the same variant's volume, cold and `run clean` stop without removing it. Exit that container and retry.
- **Image tags:** the `minimal` / `full` tag names are shared across arches. Rebuild when switching hosts. Also, a `--target full` build does not update the `minimal` tag, so build both when using both.
