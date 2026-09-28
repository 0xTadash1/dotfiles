export LS_COLORS="$(vivid generate tokyonight-night)"
zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
