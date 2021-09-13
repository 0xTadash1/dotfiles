#!/usr/bin/env zsh

# Changed directory path to respect ZDOTDIR
### Added by Zinit's installer
if [[ ! -f ${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "${ZDOTDIR:-$HOME}/.zinit" && command chmod g-rwX "${ZDOTDIR:-$HOME}/.zinit"
  command git clone https://github.com/zdharma/zinit "${ZDOTDIR:-$HOME}/.zinit/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
  zinit-zsh/z-a-rust \
  zinit-zsh/z-a-as-monitor \
  zinit-zsh/z-a-patch-dl \
  zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk


# useful function
zinit wait'0a' lucid light-mode for id-as'mansym.plugin.zsh' sbin'mansym.plugin.zsh -> mansym' \
  https://gist.githubusercontent.com/0xTadash1/ccbb7e23e89fc14d8a93d166e8dd856f/raw


# Defined by myself
zinit wait'0aa' lucid light-mode for proto'ssh' @0xTadash1/zsh-noob-init


##
#
# SECTION Lazy Loading  i.e. Asynchronous, Turbo mode
#
#
##
# SECTION Init; like zshrc, zprofile,
#

#zinit ...

# !SECTION Written in Rust


##
# SECTION Written in Rust
#
# NOTE Check crates.io whether the release is up to date
alias zirs='zinit wait"0rb" lucid light-mode'

# zinit wait'0ra' lucid light-mode for \
#   id-as'rust' sbin'bin/*' as'null' rustup \
#   atload'
#     [[ ! -f _rustup ]] && ./bin/rustup completions zsh > _rustup
#     export CARGO_HOME=$PWD
#     export RUSTUP_HOME=$PWD/rustup' @zdharma/null


zirs for \
  sbin'*/bat' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' \
    cp'**/bat.zsh -> _bat' \
    atclone'zinit creinstall bat; mansym $PWD/**/bat.1' atpull'%atclone' \
    atload$'
      export MANPAGER="sh -c \'col -bx | bat -l man -p\'"
      alias cat=\'=bat -pp\'
      alias bat=\'bat --italic-text=always\'
      alias -g B=\'|bat\'' @sharkdp/bat \
  id-as'__theme_Enki-Tokyo-Night' as'null' \
    atclone'
      (){
        local bat="$ZPFX/bin/bat"
        if [[ -x $bat ]] {
          =mv -fv __theme_Enki-Tokyo-Night Enki-Tokyo-Night
          (){
            local tmdir="$($bat --config-dir)/themes"
            [[ ! -d "$tmdir" ]] && =mkdir -p "$tmdir"
            =cp -sfv "$PWD/Enki-Tokyo-Night" "$tmdir/Enki-Tokyo-Night.tmTheme"
          } && $bat cache --build
        }
      }' atpull'%atclone' \
    atload'export BAT_THEME="Enki-Tokyo-Night"' \
    https://raw.githubusercontent.com/enkia/enki-theme/master/scheme/Enki-Tokyo-Night.tmTheme

zirs for sbin'btm' from'gh-r' bpick'*x86_64-unknown-linux-gnu.tar.gz' @ClementTsang/bottom
# TODO: gitconfig
zirs for sbin'*/delta' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' \
  cp'**/delta.zsh -> _delta' atclone'# Completion is not yet surported' atpull'%atclone' \
  atload'' @dandavison/delta

# TODO: Read docs more, Use more
# https://github.com/NerdyPepper/dijo/wiki/Auto-Habits
zirs for sbin'dijo' from'gh-r' bpick'*x86_64-linux' \
  mv'dijo* -> dijo' \
  atclone'#mansym $PWD/**/dijo.1 https://github.com/NerdyPepper/dijo/issues/116' atpull'%atclone' \
  @NerdyPepper/dijo

zirs for sbin'bin/dog' from'gh-r' bpick'*x86_64-unknown-linux-gnu.zip' \
  atclone'=mv -vf **/dog.zsh _dog; mansym $PWD/**/dog.1' atpull'%atclone' @ogham/dog
zirs for sbin'*/dust' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' @bootandy/dust
# zirs for id-as'eva' cargo'!eva' @zdharma/null  # released is old, Alt `bc`, @NerdyPepper/eva
# TODO: Aliases
zirs for sbin'*/exa' from'gh-r' bpick'*linux-x86_64-v*' \
  cp'**/exa.zsh -> _exa' \
  atclone'mansym $PWD/**/exa.1; mansym $PWD/**/exa_colors.5' \
  atpull'%atclone' \
  @ogham/exa

# TODO: Aliases
zirs for sbin'*/fd' from'gh-r' bpick'*x86_64-unknown-linux*' \
  atclone'zinit creinstall fd; mansym $PWD/**/fd.1' atpull'%atclone' \
  atload"" \
  @sharkdp/fd

zirs for sbin'grex' from'gh-r' bpick'*x86_64-unknown-linux*' @pemistahl/grex
zirs for sbin'*/hexyl' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' @sharkdp/hexyl
# zirs for id-as'jql' cargo'!jql' @zdharma/null  # cargo only, @yamafaktory/jql
#zirs for sbin'mcfly' from'gh-r' bpick'*x86_64-unknown-linux*' \
#  atclone'./mcfly init zsh > init.zsh && zcompile init.zsh' atpull'%atclone' \
#  atinit'
#    export MCFLY_KEY_SCHEME=vim
#    export MCFLY_FUZZY=true
#    export MCFLY_RESULTS=8  # Max num of results shown,default=10
#    #export MCFLY_INTERFACE_VIEW=BOTTOM  # TOP(default) or BOTTOM
#    #export MCFLY_RESULTS_SORT=LAST_RUN  # RANK(default) or LAST_RUN' \
#  atload'. ./init.zsh' @cantino/mcfly
# TODO: Read docs more, Use more
zirs for sbin'procs' from'gh-r' bpick'*x86_64-lnx*' @dalance/procs
zirs for sbin'pyflow' from'gh-r' bpick'pyflow' @David-OConnor/pyflow  # TODO: zipy section??
# TODO: Aliases
zirs for sbin'*/rg' from'gh-r' bpick'*x86_64-unknown-linux*' \
  atclone'mansym $PWD/**/rg.1' atpull'%atclone' atload$'alias -g R=\'|rg\'' @BurntSushi/ripgrep

zirs for sbin'sd' from'gh-r' bpick'*x86_64-unknown-linux-gnu' mv'sd* -> sd' @chmln/sd
# TODO: Read docs more, Use more
# A terminal interface for Stack Overflow
zirs for sbin'so' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' @samtay/so
zirs for sbin'tldr' from'gh-r' bpick'*linux-x86_64-musl' bpick'*_zsh' pick"/dev/null" \
  mv'tldr*musl -> tldr' \
  atclone'./tldr -u > /dev/null; =mv -vf *_zsh _tldr' atpull'%atclone' @dbrgn/tealdeer

# @BurntSushi/xsv  # it's sleeping, fork: @jqnatividad/qsv
# TODO: eval script
zirs for sbin'*/zoxide' from'gh-r' bpick'*x86_64-unknown-linux*' \
  atclone'for f in **/man/*; do mansym $PWD/$f; done' atpull'%atclone' \
  atload'eval "$(*/zoxide init zsh)"' @ajeetdsouza/zoxide

unalias zirs
# !SECTION Written in Rust


##
# SECTION Written in Go
#
alias zigo='zinit wait"0gb" lucid light-mode'

# TODO: all
# zinit wait"0ga" lucid light-mode for @stefanmaric/g


zigo for \
  sbin'fzf' from'gh-r' bpick'*linux_amd64.tar.gz' \
    @junegunn/fzf \
  id-as'_fzf' as'completion' \
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh \
  id-as'__fzf_1' atclone'=cp -f __fzf_1 fzf.1; mansym $PWD/fzf.1' atpull'%atclone' \
    nocompile cloneonly \
    https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1 \
  id-as'__fzf-tmux_1' atclone'=cp -f __fzf-tmux_1 fzf-tmux.1; mansym $PWD/fzf-tmux.1' \
    atpull'%atclone' nocompile cloneonly \
    https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf-tmux.1 \
  id-as'__fzf_key-bindings' \
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh


# @dim-an/cod  # a completion daemon for bash/fish/zsh
# @mikefarah/yq  # yq is a lightweight and portable command-line YAML processor
# @irevenko/tsukae  # Show off your most used shell commands
# @muesli/duf  # Alt for df
# @b4b4r07/gist
# @jesseduffield/lazydocker


unalias zigo
# !SECTION Written in Go


##
# SECTION Written in Python
#
# NOTE: Required `nocompletions` mod, to avoid detecting files like `_async.py`
alias zipy='zinit wait"0pb" lucid nocompletions light-mode'

# TODO: Read docs more, Use more
zipy for id-as'gcalcli' pip'!gcalcli' \
  atclone'
    wget -O ./gcalcli.1 https://raw.githubusercontent.com/insanum/gcalcli/master/docs/man1/gcalcli.1
    mansym $PWD/gcalcli.1' \
  atpull'%atclone' \
  @zdharma/null

#zipy for id-as'grip' pip'!grip' @zdharma/null  # GitHub Readme Instant Preview
#zipy for id-as'pywal' pip'!pywal' @zdharma/null
zipy for id-as'rainbowstream' pip'!rainbowstream' @zdharma/null
# TODO: Read docs more, Use more
#zipy for id-as'xxh' pip'xxh <- !xxh-xxh -> xxh' @zdharma/null

unalias zipy
# !SECTION Written in Python


##
# SECTION Written in Node.js
#
alias zijs='zinit wait"0nb" lucid light-mode'

# TODO: more Test, more develop init scripts (install node.js, npm, yran etc)
# zinit wait"0na" lucid light-mode for \
#   atinit'VOLTA_HOME="${HOME}/.local/volta"' 0xTadash1/zsh-quick-volta

# zijs for id-as'add-gitignore' node'!add-gitignore' @zdharma/null
# zijs for id-as'emoj' node'!emoj' @zdharma/null
# zijs for id-as'fkill' node'fkill <- !fkill-cli -> fkill' @zdharma/null
zijs for id-as'readme-md-generator' node'readme <- !readme-md-generator -> readme' @zdharma/null
zijs for id-as'speed-test' node'!speed-test' @zdharma/null


unalias zijs
# !SECTION Written in Node.js


##
# SECTION General
#
alias zigl='zinit wait"0u" lucid light-mode'

## Oh-My-Zsh
zigl svn for OMZP::extract
zigl for if'[[ "$(command -v pbcopy xclip xsel wl-copy)" ]] || [[ $TMUX ]]' OMZL::clipboard.zsh

## Prezto:TODO


# TODO: Read docs more, Use more
zigl for sbin'bin/git-fuzzy' as'null' if'[[ "$(command -v fzf)" ]]' atload'' @bigH/git-fuzzy

# TODO: better BROWSER detecting/setting
# `*.plugin.zsh` in repo just append itself to $PATH
zigl for id-as'git-open' as'null' sbin \
  atload'b="$(which microsoft-edge-dev)" && export BROWSER=$b' \
  https://github.com/paulirish/git-open/blob/master/git-open

# `*.plugin.zsh` in repo just sets an alias
zigl for sbin'translate -> trans' soimort/translate-shell
zigl for atload'bindkey -M vicmd " m" vi-easy-motion' IngoMeyer441/zsh-easy-motion
# Neither worked for me...
# zinit wait'0u' lucid for \
#   if'[[ ! -z "$(command -v pbcopy xclip xsel wl-copy)" ]]' \
#   atload'!
#     set -a cp pt
    
#     cp=( $(command -v pbcopy xclip xsel wl-copy) )
#     cp=${cp[1]##*/}
#     pt=( $(command -v pbpaste xclip xsel wl-paste) )
#     pt=${pt[1]##*/}
    
#     # Regular clipboard
#     cpopt=`([[ $cp[1] =~ xclip ]] && echo "-sel clip -rmlastnl") ||
#         ([[ $cp[1] =~ xsel ]] && echo "-ib")`
#     ptopt=`([[ $pt[1] =~ xclip ]] && echo "-sel clip -rmlastnl -o") ||
#         ([[ $pt[1] =~ xsel ]] && echo "-ob")`
#     zstyle :zle:evil-registers:"+" yank - $cp $cpopt
#     zstyle :zle:evil-registers:"+" put - $pt $ptopt

#     # X11 primary
#     cpopt=`([[ $cp[1] =~ xclip ]] && echo "-i -sel prim -rmlastnl") ||
#         ([[ $cp[1] =~ xsel ]] && echo "-ip") ||
#         ([[ $cp[1] =~ wl-copy ]] && echo "-p")`
#     ptopt=`([[ $pt[1] =~ xclip ]] && echo "-sel prim -rmlastnl -o") ||
#         ([[ $pt[1] =~ xsel ]] && echo "-op") ||
#         ([[ $pt[1] =~ wl-paste ]] && echo "-p")`
#     zstyle :zle:evil-registers:"\*" yank - $cp $cpopt
#     zstyle :zle:evil-registers:"\*" put - $pt $ptopt

#     unset cp pt cpopt ptopt

#     # [[ $EDITOR = nvim && $(command -v nvr) ]] ||
#     #   [[ $EDITOR = vim && $(vim --version | =grep "\+clientserver") ]] &&
#     #     zstyle :zle:evil-registers:"[A-Za-z%#]" editor $EDITOR
        
#     (){
#       local op
#       local -a handler
#       for op in yank put; do
#         # get the current behavior for "+"
#         zstyle -a :zle:evil-registers:"+" $op handler
#         # if there is a handler, assign it for the empty pattern
#         (($#handler)) && zstyle :zle:evil-registers:"" $op $handler
#       done
#     }' \
#   zsh-vi-more/evil-registers
# # ↑ or ↓
# zigl for if'[[ ! -z "$(command -v pbcopy xclip xsel wl-copy)" ]]' kutsan/zsh-system-clipboard

unalias zigl
# !SECTION General


##
# SECTION Completions
#
alias zicomp='zinit wait"0w" lucid light-mode'

# This may be bundled with docker
# zicomp for id-as as'completion' \
#   https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
zicomp for as'completion' OMZP::docker-compose/_docker-compose

unalias zicomp
# !SECTION Completions


##
# SECTION Other  e.g. completion, prompt, syntax-highlight...
#

zinit wait'0x' lucid light-mode for \
  atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' \
    zdharma/fast-syntax-highlighting \
  atload'_zsh_autosuggest_start; ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"' \
    zsh-users/zsh-autosuggestions \
  blockf \
    zsh-users/zsh-completions \
  blockf atload'
    bindkey "$terminfo[kcuu1]" history-substring-search-up
    bindkey "$terminfo[kcud1]" history-substring-search-down
    bindkey -M emacs "^P" history-substring-search-up
    bindkey -M emacs "^N" history-substring-search-down
    bindkey -M vicmd "k" history-substring-search-up
    bindkey -M vicmd "j" history-substring-search-down
    
    # e.g. "standout,bold,underline"
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=0,bg=2,bold,underline"
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=7,bg=8,underline"
    # i=case-insensitive, l=smart, I=sensitive  ("Globbing Flags" in zshexpn(1))
    HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS=l
    HISTORY_SUBSTRING_SEARCH_FUZZY=1
    HISTORY_SUBSTRING_SEARCH_PREFIXED=
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1' \
    zsh-users/zsh-history-substring-search

# Additional completion method `zsh-autocomplete` (Doesn't work well with lazy loading)
# Also `zsh-history-substring-search` may not work with `zsh-autocomplete`
# zinit light-mode for \
#   atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' \
#     zdharma/fast-syntax-highlighting \
#   atload'_zsh_autosuggest_start; ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"' \
#     zsh-users/zsh-autosuggestions \
#   blockf \
#     zsh-users/zsh-completions \
#   blockf depth'1' atinit'
#     zstyle ":autocomplete:*" list-lines 8
#     zstyle ":autocomplete:*" widget-style menu-select
#     [[ $(command -v zoxide) ]] && zstyle ":autocomplete:*" recent-dirs zoxide
#     [[ $(command -v fzf) ]] && zstyle ":autocomplete:*" fzf-completion yes' \
#     marlonrichert/zsh-autocomplete \
#   blockf atload'
#     bindkey "$terminfo[kcuu1]" history-substring-search-up
#     bindkey "$terminfo[kcud1]" history-substring-search-down' \
#     zsh-users/zsh-history-substring-search


# Finalizer: When use wait'' mod with Exclamation mark, it reflesh prompt on loading finished 
zinit wait'!0zz' lucid for id-as'Finalizer' as'null' \
  atload'
    [[ $(command -v docker) ]] && {
      zstyle ":completion:*:*:docker:*" option-stacking yes
      zstyle ":completion:*:*:docker-*:*" option-stacking yes
    }' @zdharma/null

# !SECTION Other
# !SECTION Lazy Loading


##
#
# SECTION Sequential Loading
#
#
# TODO: `atclone''` func; read "SETUP 1/2: for Kitty"; p10k configure && mv $ZDOTDIR/.p10k.zsh ... 
# Doesn't work well with lazy loading
zinit light-mode for \
  depth'1' atclone'[[ ! -f $ZDOTDIR/.p10k.zsh ]] && p10k configure' \
  atload'
    [[ $TERM = "xterm-kitty" ]] && . $ZDOTDIR/.kitty.p10k.zsh || . $ZDOTDIR/.p10k.zsh
    _p9k_precmd; (( ! ${+functions[p10k]} )) || p10k finalize' \
  romkatv/powerlevel10k

# Doesn't work well with lazy loading
# zinit light-mode for depth'1' jeffreytse/zsh-vi-mode


# !SECTION Sequential Loading
