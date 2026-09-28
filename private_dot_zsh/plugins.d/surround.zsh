# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/surround
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -a 'cs' change-surround
bindkey -a 'ds' delete-surround
bindkey -a 'ys' add-surround
bindkey -M visual 'S' add-surround

# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-quoted
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
	for c in {a,i}{\',\",\`}; do
		bindkey -M $m $c select-quoted
	done
done

# cf. https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-bracketed
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
	for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
		bindkey -M $m $c select-bracketed
	done
done
