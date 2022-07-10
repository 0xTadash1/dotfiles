# syntax=docker/dockerfile:1
FROM manjarolinux/base:latest

RUN <<-eot sh
	yes | pacman -Syu svn curl wget unzip man-db zsh
	chsh -s /bin/zsh

	yes | pacman -S bitwarden-cli
	export EMAIL=''
	export BW_PASSWORD=''
	export BW_SESSION="$(bw login $EMAIL $BW_PASSWORD --raw)"
	bw sync

	yes | pacman -Syu chezmoi
	export GITHUB_USERNAME='0xTadash1'
	echo $BW_PASSWORD | chezmoi init --apply $GITHUB_USERNAME

	[[ -e $HOME/.zshenv ]] && source $HOME/.zshenv

	#echo "export BW_SESSION='$BW_SESSION'" >> ${ZDOTDIR:-$HOME}/.zshrc
	echo 'source ${ZDOTDIR:-$HOME}/.zinit.zsh' >> ${ZDOTDIR:-$HOME}/.zshrc
	echo 'repeat 240 { echo y; sleep 1 }' >> ${ZDOTDIR:-$HOME}/.zshrc
eot
