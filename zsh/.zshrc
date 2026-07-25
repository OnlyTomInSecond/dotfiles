# =============================================================================
#  .zshrc — Interactive Zsh Configuration  (优化版：极致速度 & 轻量)
# =============================================================================

# ===============================================================================
# 1. Powerlevel10k instant prompt — 放在最顶部，MUST stay near top
#    取消注释下面的 if 块即可启用 p10k instant prompt（先渲染提示符再加载插件）
#    如果不用 p10k 则保持注释，无任何开销。
# ===============================================================================
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#     source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ===============================================================================
# 2. 基准选项（零开销，尽早设置）
# ===============================================================================
setopt extended_glob             # 扩展通配符（很多插件依赖）
setopt no_beep                   # 关闭蜂鸣
unsetopt nomatch                 # 无匹配时按原样传递

# ===============================================================================
# 3. History — 精简 + 性能
# ===============================================================================
HISTFILE=~/.histfile
HISTSIZE=10000                   # 50000→10000，减少内存占用
SAVEHIST=10000
setopt hist_ignore_all_dups      # 不记录重复命令
setopt hist_ignore_space         # 空格开头的命令不记录
setopt hist_reduce_blanks        # 去除多余空白
# setopt inc_append_history      # 如需即时追加则取消注释

# ===============================================================================
# 4. 交互选项（需要时再开启）
# ===============================================================================
setopt auto_cd                   # 输入目录名自动 cd
setopt auto_pushd                # cd 时自动压栈
setopt pushd_ignore_dups         # 不重复压栈
setopt interactive_comments      # 交互式 shell 中允许 # 注释
# 注释掉 glob_complete — 补全时展开通配符消耗明显
# setopt glob_complete

bindkey -e                       # Emacs 风格键绑定

# ===============================================================================
# 5. Completions — 关键优化：使用 zcompdump 缓存 + compinit -C 永远快速
# ===============================================================================
# 创建缓存目录（如不存在）
[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh

# 只添加少量第三方补全，避免 192 个文件拖慢 compinit
# 如需完整 zsh-completions，取消下行注释（代价：首次生成 zcompdump 约 50ms）
# fpath+=(${HOME}/.zsh_packages/zsh-completions/src/)

autoload -Uz compinit
# 策略：zcompdump 存在时一律 -C 跳过安全审计（节省 ~35ms）
#       首次运行或 zcompdump 被删除时才完整构建
if [[ -f ~/.cache/zsh/zcompdump ]]; then
    compinit -C -d ~/.cache/zsh/zcompdump
else
    compinit -d ~/.cache/zsh/zcompdump
    # 首次构建后立即用 zcompile 编译为字节码，后续加载更快
    zcompile ~/.cache/zsh/zcompdump
fi

# 补全缓存（加速补全结果生成）
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/zcompcache

# 菜单行为
zstyle ':completion:*' menu select=2
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

# 大小写：文件/参数忽略大小写，命令名保持敏感（避免歧义）
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:*:-command-:*' matcher-list ''

# 着色
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:options' list-colors '=(#b)(-- *)=34'

# ===============================================================================
# 6. Plugins — 仅加载必需的
# ===============================================================================
source ${HOME}/.zsh_packages/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${HOME}/.zsh_packages/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# ===============================================================================
# 7. Prompt — 时间 + SSH状态 + 命令耗时 + 路径 + 退出码
# ===============================================================================
autoload -U colors && colors

setopt prompt_subst
zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -gi cmd_start cmd_time

update_cmd_start() { cmd_start=$EPOCHSECONDS }
update_cmd_time() {
  (( cmd_start )) && cmd_time=$((EPOCHSECONDS - cmd_start)) || cmd_time=0
}
add-zsh-hook preexec update_cmd_start
add-zsh-hook precmd update_cmd_time

ssh_prompt() { [[ -n "$SSH_CONNECTION" ]] && echo "SSH " }

PROMPT='%F{green}%D{%H:%M:%S}%f %(?::%F{red}[%?]%f )%F{yellow}[$(ssh_prompt)${cmd_time}s]%f %F{blue}%~%f
%F{blue}>%f '

# ===============================================================================
# 8. P10k config — 如使用 p10k 取消注释
# ===============================================================================
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================================================
# 9. Extra config
# ===============================================================================
source ${HOME}/.zsh_extra

