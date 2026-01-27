# function __setup_conda(){
#     eval "$('/Users/dirichy/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
#     export PATH="/Users/dirichy/miniconda3/bin:$PATH"
# }
# lazyload conda -- '__setup_conda'
# lazyload python -- '__setup_conda'
# lazyload python3 -- '__setup_conda'
# lazyload bypy -- '__setup_conda'
