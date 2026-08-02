#
# chezmoi 命名から $HOME への対応表。
#
# このコンテナは chezmoi を使わないので、対応関係の定義はここが唯一の出所。
# entrypoint.zsh と tests/pre-10-filemap.zsh の両方がこれを読む。
#
# private_ が付いているのは private_dot_zsh ディレクトリだけなので、0700 に
# なるのは ~/.zsh のみ。配下のファイルには private_ が無いので 0644。
#

typeset -gA FILE_MAP=(
	['dot_zshenv']='.zshenv'
	['dot_profile']='.profile'
	['private_dot_zsh/dot_zprofile']='.zsh/.zprofile'
	['private_dot_zsh/dot_zinit.zsh']='.zsh/.zinit.zsh'
	['private_dot_zsh/dot_p10k.zsh']='.zsh/.p10k.zsh'
)

# drift 検出の対象範囲。
#
# repo 側でこのパターンに合うファイルが増えたとき、FILE_MAP に書き忘れると
# 黙って無視される。それを失敗として検出するために範囲を明示しておく。
# 検証したいのは zsh の起動経路なので、対象は zsh 関連に限る。
typeset -ga WATCHED_PATTERNS=(
	'dot_z*'
	'dot_profile'
	'private_dot_zsh/**/*'
)
