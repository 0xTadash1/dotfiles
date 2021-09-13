#!/usr/bin/env zsh

btrfs property set $HOME/Downloads compression zstd:3
btrfs property set $HOME/Pictures  compression zstd:3
btrfs property set $HOME/Videos    compression zstd:3
btrfs property set $HOME/Music     compression zstd:3
