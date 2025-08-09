# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#zmodload zsh/zprof

#autoload -Uz promptinit
#promptinit

#prompt_redhatmod_setup () {
#  PS1='[%F{green}%n%f@%F{magenta}%m%f %F{blue}%1~%f]%(#.#.$) '
#  PS2="> "
#}

# Add the theme to promptsys
#prompt_themes+=( redhatmod )

# Load the theme
#prompt redhatmod

#PROMPT='[%F{green}%n%f@%F{magenta}%m%f %F{blue}%1~%f]%(#.#.$) '
#PROMPT2='> '
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=20000
SAVEHIST=20000

# no duplicate history
setopt hist_ignore_all_dups
# 在命令前添加空格，不将此命令添加到记录文件中
setopt hist_ignore_space
# zsh 4.3.6 doesn't have this option
setopt hist_fcntl_lock 2> /dev/null
setopt hist_reduce_blanks

#setopt extendedglob nomatch
#setopt nonomatch 
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
#zstyle :compinstall filename '${HOME}/.zshrc'

#fpath=(/usr/share/zsh/site-functions/ $fpath)
fpath=(${HOME}/.zsh_packages/zsh-completions/src/ $fpath)
#fpath+=(${HOME}/.zsh_packages/pure/)

#autoload -U promptinit; promptinit
#prompt pure
autoload -Uz compinit
compinit

#autoload -U bashcompinit
#bashcompinit

# unsetopt prompt_cr prompt_sp

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1


#source /usr/share/doc/pkgfile/command-not-found.zsh
source ~/.zsh_packages/powerlevel10k/powerlevel10k.zsh-theme
source ${HOME}/.zsh_packages/zsh-autosuggestions/zsh-autosuggestions.zsh
#source ${HOME}/.zsh_packages/zsh-completions/
source ${HOME}/.zsh_packages/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
#source ~/.zsh_packages/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
#source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh_extra

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
zshcache_time="$(date +%s%N)"

autoload -Uz add-zsh-hook

rehash_precmd() {
    if [[ -a /var/cache/zsh/pacman ]]; then
        local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
        if (( zshcache_time < paccache_time )); then
            rehash
            zshcache_time="$paccache_time"
        fi
    fi
}

add-zsh-hook -Uz precmd rehash_precmd
#eval "$(starship init zsh)"

