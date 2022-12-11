zinit wait'0ra' lucid light-mode for id-as'rust' sbin'bin/*' as'null' rustup \
	atload'
		[[ ! -f _rustup ]] && ./bin/rustup completions zsh > _rustup
		export CARGO_HOME=$PWD
		export RUSTUP_HOME=${PWD}/rustup
		export PATH="${PATH}:${CARGO_HOME}/bin"' \
	@zdharma-continuum/null


# TODO
#zinit wait"0na" lucid light-mode for \
#	atinit'VOLTA_HOME="${HOME}/.local/volta"' 0xTadash1/zsh-quick-volta
