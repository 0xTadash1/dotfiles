zinit wait'0' lucid light-mode for \
	sbin'*/bat' from'gh-r' bpick'*x86_64-unknown-linux-gnu*' nocompile \
		atpull'%atclone' \
		atload"$(<<-'END'
			# Use as a `man` colorizer as you like
			#export MANPAGER="sh -c 'col -bx | bat -l man -p'"
			export LESSOPEN="${LESSOPEN:-"| bat -ppf %s"}"
			alias cat='command bat -pp'
			alias bat='bat --italic-text=always --tabs 6'
			alias -g B='| bat'
			END
			)" \
		@sharkdp/bat \
	id-as'bat_theme_tokyonight_night' as'null' \
		atclone'
			command cp -vf tokyonight_night.tmTheme "$XDG_CONFIG_HOME/bat/themes/"
			command bat cache --build' \
		atpull'%atclone' \
		atload'export BAT_THEME=tokyonight_night' \
		https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme


zinit wait'0' lucid light-mode for \
	sbin'tealdeer* -> tldr' from'gh-r' bpick'tealdeer-linux-x86_64-musl' nocompile \
	atclone'
		./tealdeer* -u > /dev/null
		curl -o _tldr https://raw.githubusercontent.com/dbrgn/tealdeer/main/completion/zsh_tealdeer
		zinit creinstall dbrgn/tealdeer
		zinit cdreplay' \
	atpull'%atclone' \
	@dbrgn/tealdeer

# TODO: eval script
zinit wait'0' lucid light-mode for sbin'zoxide' from'gh-r' bpick'*x86_64-unknown-linux*' nocompile \
	atclone'for f in ./man/*; do mansym $PWD/$f; done' \
	atpull'%atclone' \
	atload'eval "$(zoxide init zsh)"' \
	@ajeetdsouza/zoxide


zinit wait'0' lucid light-mode for \
	sbin'fzf' from'gh-r' bpick'*linux_amd64.tar.gz' nocompile \
		atload"$(<<-'END'
			# @catppuccin/fzf
			export FZF_DEFAULT_OPTS='--height 40% --layout reverse --color=bg+:#302D41,bg:#1E1E2E,spinner:#F8BD96,hl:#F28FAD --color=fg:#D9E0EE,header:#F28FAD,info:#DDB6F2,pointer:#F8BD96 --color=marker:#F8BD96,fg+:#F2CDCD,prompt:#DDB6F2,hl+:#F28FAD'

			export FZF_CTRL_T_COMMAND='fd --type file --hidden --exclude .git'
			export FZF_CTRL_T_OPTS='
				--preview "
					echo \"[1;4m\"${"$(file {})":t:s/\: /\"[0;3;90m \"/}\"[m\"
					bat -pp -f --italic-text=always --tabs 6 -r :200 {}"
				--preview-window border-left'
			END
			)" \
		@junegunn/fzf \
	id-as'_fzf' as'completion' \
		https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh \
	id-as'__fzf_1' atclone'command cp -f __fzf_1 fzf.1; mansym $PWD/fzf.1' atpull'%atclone' \
		nocompile cloneonly \
		https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1 \
	id-as'__fzf-tmux_1' atclone'command cp -f __fzf-tmux_1 fzf-tmux.1; mansym $PWD/fzf-tmux.1' \
		atpull'%atclone' nocompile cloneonly \
		https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf-tmux.1 \
	id-as'__fzf_key-bindings' \
		https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh

# TODO
#zinit wait'0' lucid light-mode for id-as'add-gitignore' node'!add-gitignore' @zdharma-continuum/null
