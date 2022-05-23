#!/usr/bin/env zsh

# Changed directory path to respect ZDOTDIR
### Added by Zinit's installer
if [[ ! -f "${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh" ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "${ZDOTDIR:-$HOME}/.zinit" && command chmod g-rwX "${ZDOTDIR:-$HOME}/.zinit"
  command git clone https://github.com/zdharma-continuum/zinit "${ZDOTDIR:-$HOME}/.zinit/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-readurl \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

() {
  local d="${ZDOTDIR:-$HOME}/.zinit/polaris/bin"
  [[ ! -d "$d" ]] && =mkdir -p "$d"
}
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

zinit wait'0ra' lucid light-mode for \
  id-as'rust' sbin'bin/*' as'null' rustup \
  atload'
    [[ ! -f _rustup ]] && ./bin/rustup completions zsh > _rustup
    export CARGO_HOME=$PWD
    export RUSTUP_HOME=${PWD}/rustup
    export PATH="${PATH}:${CARGO_HOME}/bin"' @zdharma-continuum/null


zirs for \
  sbin'*/bat' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile \
    atclone'
      =ln -svf "$PWD/"**/bat.zsh "$PWD/_bat" `: "${ZINIT[COMPLETIONS_DIR]}/_bat"` \
      && echo "After the installation/update is completed, please do \`zinit compinit\` "
      mansym $PWD/**/bat.1' \
    atpull'%atclone' \
    atload$'
      export MANPAGER="sh -c \'col -bx | bat -l man -p\'"
      alias cat=\'=bat -pp\'
      alias bat=\'bat --italic-text=always --tabs 6\'
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

zirs for sbin'btm' from'gh-r' bpick'*x86_64-unknown-linux-gnu.tar.gz' nocompile @ClementTsang/bottom
zirs for sbin'*/delta' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile \
  atclone'=cp -vf **/delta.zsh _delta && zinit creinstall delta' atpull'%atclone' \
  atload'' @dandavison/delta

# https://github.com/NerdyPepper/dijo/wiki/Auto-Habits
zirs for sbin'dijo* -> dijo' from'gh-r' bpick'*x86_64-linux' nocompile \
  atclone'#mansym $PWD/**/dijo.1 https://github.com/nerdypepper/dijo/issues/116' atpull'%atclone' \
  @nerdypepper/dijo

zirs for sbin'bin/dog' from'gh-r' bpick'*x86_64-unknown-linux-gnu.zip' nocompile \
  atclone'=mv -vf **/dog.zsh _dog; mansym $PWD/**/dog.1' atpull'%atclone' @ogham/dog
zirs for sbin'*/dust' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile @bootandy/dust
# zirs for id-as'eva' cargo'!eva' @zdharma-continuum/null  # released is old, Alt `bc`, @NerdyPepper/eva
zirs for sbin'*/exa' from'gh-r' bpick'*linux-x86_64-v*' nocompile \
  cp'**/exa.zsh -> _exa' \
  atclone'zinit creinstall exa; mansym $PWD/**/exa.1; mansym $PWD/**/exa_colors.5' \
  atpull'%atclone' \
  @ogham/exa

zirs for sbin'*/fd' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile \
  atclone'zinit creinstall fd; mansym $PWD/**/fd.1' atpull'%atclone' \
  atload"" \
  @sharkdp/fd

zirs for sbin'grex' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile @pemistahl/grex
zirs for sbin'*/hexyl' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile @sharkdp/hexyl
# zirs for id-as'jql' cargo'!jql' @zdharma-continuum/null  # cargo only, @yamafaktory/jql
zirs for sbin'*/rg' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile \
  atclone'mansym $PWD/**/rg.1' atpull'%atclone' atload$'alias -g R=\'|rg\'' @BurntSushi/ripgrep

zirs for sbin'sd' from'gh-r' bpick'*x86_64-unknown-linux-gnu' nocompile cp'sd* -> sd' @chmln/sd
# A terminal interface for Stack Overflow
zirs for sbin'so' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile @samtay/so
zirs for sbin'tealdeer* -> tldr' from'gh-r' bpick'tealdeer-linux-x86_64-musl' nocompile \
  atclone'
    ./tealdeer* -u > /dev/null
    curl -o _tldr https://raw.githubusercontent.com/dbrgn/tealdeer/main/completion/zsh_tealdeer
    zinit creinstall dbrgn/tealdeer
    zinit cdreplay
    ' atpull'%atclone' @dbrgn/tealdeer

# @BurntSushi/xsv  # it's sleeping, fork: @jqnatividad/qsv
# TODO: eval script
zirs for sbin'zoxide' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile \
  atclone'for f in ./man/*; do mansym $PWD/$f; done' atpull'%atclone' \
  atload'eval "$(zoxide init zsh)"' @ajeetdsouza/zoxide

unalias zirs
# !SECTION Written in Rust


##
# SECTION Written in Go
#
alias zigo='zinit wait"0gb" lucid light-mode'


zigo for \
  sbin'fzf' from'gh-r' bpick'*linux_amd64.tar.gz' nocompile \
    atload$'
      # @catppuccin/fzf
      export FZF_DEFAULT_OPTS=\'--height 40% --layout reverse --color=bg+:#302D41,bg:#1E1E2E,spinner:#F8BD96,hl:#F28FAD --color=fg:#D9E0EE,header:#F28FAD,info:#DDB6F2,pointer:#F8BD96 --color=marker:#F8BD96,fg+:#F2CDCD,prompt:#DDB6F2,hl+:#F28FAD\'

      export FZF_CTRL_T_COMMAND=\'fd --type file --hidden --exclude .git\'
      export FZF_CTRL_T_OPTS=\'
        --preview "
          echo \\"\\\\033[1;4m\\"${"$(file {})":t:s/\\: /\\"\\\\033[0;3;90m \\"/}\\"\\\\033[m\\"
          bat -pp -f --italic-text=always --tabs 6 -r :200 {}"
        --preview-window border-left\'
    ' @junegunn/fzf \
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
# SECTION Written in Node.js
#
alias zijs='zinit wait"0nb" lucid light-mode'

# TODO: more Test, more develop init scripts (install node.js, npm, yran etc)
# zinit wait"0na" lucid light-mode for \
#   atinit'VOLTA_HOME="${HOME}/.local/volta"' 0xTadash1/zsh-quick-volta

# zijs for id-as'add-gitignore' node'!add-gitignore' @zdharma-continuum/null
# zijs for id-as'emoj' node'!emoj' @zdharma-continuum/null
# zijs for id-as'fkill' node'fkill <- !fkill-cli -> fkill' @zdharma-continuum/null
zijs for id-as'readme-md-generator' node'readme <- !readme-md-generator -> readme' @zdharma-continuum/null
zijs for id-as'speed-test' node'!speed-test' @zdharma-continuum/null


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
#zigl for sbin'bin/git-fuzzy' as'null' if'[[ "$(command -v fzf)" ]]' atload': pass' @bigH/git-fuzzy

# `*.plugin.zsh` in repo just sets an alias
zigl for sbin'translate -> trans' soimort/translate-shell
zinit for atload'bindkey -M vicmd " m" vi-easy-motion' IngoMeyer441/zsh-easy-motion
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

zinit `: light-mode` for \
  atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' \
    zdharma-continuum/fast-syntax-highlighting \
  atload'_zsh_autosuggest_start; ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"' \
    zsh-users/zsh-autosuggestions \
  blockf \
    zsh-users/zsh-completions \
  blockf atload'
    # Arrow Key
    bindkey "$terminfo[kcuu1]" history-substring-search-up
    bindkey "$terminfo[kcud1]" history-substring-search-down
    bindkey "^[[A" history-substring-search-up
    bindkey "^[[B" history-substring-search-down

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


# Finalizer: When use wait'' mod with Exclamation mark, it reflesh prompt on loading finished 
zinit wait'!0zz' lucid for id-as'Finalizer' as'null' \
  atload'
    [[ $(command -v docker) ]] && {
      zstyle ":completion:*:*:docker:*" option-stacking yes
      zstyle ":completion:*:*:docker-*:*" option-stacking yes
    }' @zdharma-continuum/null

# !SECTION Other
# !SECTION Lazy Loading


##
#
# SECTION Sequential Loading
#
#

# Doesn't work well with lazy loading
#zinit light-mode for \
#  depth'1' atclone'[[ ! -f $ZDOTDIR/.p10k.zsh ]] && p10k configure' \
#  if'[[ ! $TERM = "linux" ]]' \
#  atload'
#    . $ZDOTDIR/.p10k.zsh
#    _p9k_precmd; (( ! ${+functions[p10k]} )) || p10k finalize' \
#  romkatv/powerlevel10k

zinit light-mode for sbin'posh-linux-amd64 -> oh-my-posh' from'gh-r' bpick'posh-linux-amd64' nocompile \
  if'[[ ! $TERM = "linux" ]]' \
  atclone'./posh-linux-amd64 completion > _oh-my-posh' atpull'%atclone' \
  atload'eval "$(./posh-linux-amd64 init zsh --config $XDG_CONFIG_HOME/omp/prompt.omp.json)"' \
  @JanDeDobbeleer/oh-my-posh

# Doesn't work well with lazy loading
# zinit light-mode for depth'1' jeffreytse/zsh-vi-mode


# !SECTION Sequential Loading
