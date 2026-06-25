# =============================================================================
#  .zshrc — Interactive Zsh Configuration
# =============================================================================

# -- Powerlevel10k instant prompt (MUST stay near top) ------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -- History ------------------------------------------------------------------
HISTFILE=~/.histfile
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_all_dups      # 不记录重复命令
setopt hist_ignore_space         # 空格开头的命令不记录
setopt hist_reduce_blanks        # 去除多余空白
setopt share_history             # 跨终端共享历史
setopt inc_append_history        # 即时追加历史（而非等 shell 退出）

# -- Basic options ------------------------------------------------------------
setopt auto_cd                   # 输入目录名自动 cd
setopt auto_pushd                # cd 时自动压栈
setopt pushd_ignore_dups         # 不重复压栈
setopt extended_glob             # 启用扩展通配符
setopt no_beep                   # 关闭蜂鸣
setopt no_match                  # 无匹配时不报错（配合 extended_glob）
setopt interactive_comments      # 交互式 shell 中允许 # 注释
setopt glob_complete             # 将通配符展开为补全候选

bindkey -e                       # Emacs 风格键绑定

# -- Completions --------------------------------------------------------------
fpath=(${HOME}/.zsh_packages/zsh-completions/src/ $fpath)
autoload -Uz compinit
# -C 跳过安全扫描（大幅提速），仅当 zcompdump 超过 24h 时完整重建
if [[ -f ~/.cache/zsh/zcompdump(#qN.mh-24) ]]; then
    compinit -C -d ~/.cache/zsh/zcompdump
else
    compinit -d ~/.cache/zsh/zcompdump
fi

# 补全缓存
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/zcompcache

# 菜单：≥2 个匹配时弹出菜单，可 Tab 循环
zstyle ':completion:*' menu select=2
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

# 大小写：命令名大小写敏感，其他（文件/参数/选项）忽略大小写
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:*:-command-:*' matcher-list ''

# 分组显示与着色
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:options' list-colors '=(#b)(-- *)=34'  # 长选项用蓝色

# -- Prompt (p10k manages PROMPT directly; no promptinit needed) ------------
source ${HOME}/.zsh_packages/powerlevel10k/powerlevel10k.zsh-theme

# -- Plugins ------------------------------------------------------------------
source ${HOME}/.zsh_packages/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${HOME}/.zsh_packages/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# -- P10k config --------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -- Extra user config --------------------------------------------------------
source ${HOME}/.zsh_extra

