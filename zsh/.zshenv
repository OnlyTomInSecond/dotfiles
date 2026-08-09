# =============================================================================
#  .zshenv - always loaded (login + non-login); env vars only
# =============================================================================
typeset -U path PATH
path=(${HOME}/bin $path)
export PATH

# Skip /etc/zsh/* global configs to save ~5-10ms (if system defaults aren't needed)
# setopt no_global_rcs
