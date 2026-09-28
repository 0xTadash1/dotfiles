# Source this from .zshrc
export ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/antidote"

if [[ ! -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
	command git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"
fi

# Deferred plugins would otherwise have their output, errors included, sent to /dev/null
zstyle ':antidote:bundle:*' defer-options '-12'

source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
antidote load

# Rebuild completions whenever the bundles change. The dump path is ez-compinit's default
if [[ ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh -nt ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump ]]; then
	command rm -f -- ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
fi
