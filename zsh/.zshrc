# =============================================================================
#  .zshrc - Interactive Zsh Configuration (fast & lightweight)
# =============================================================================

# ===============================================================================
# 1. Powerlevel10k instant prompt - must stay near the top
#    Uncomment the block below to enable instant prompt (prompt renders before plugins load)
#    Leave commented if not using p10k: zero overhead.
# ===============================================================================
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#     source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ===============================================================================
# 2. Base options (zero-cost, set early)
# ===============================================================================
setopt extended_glob             # extended globbing (many plugins rely on it)
setopt no_beep                   # disable beep
unsetopt nomatch                 # pass unmatched globs through literally

# ===============================================================================
# 3. History - minimal + fast
# ===============================================================================
HISTFILE=~/.histfile
HISTSIZE=10000                   # 50000->10000, lower memory usage
SAVEHIST=10000
setopt hist_ignore_all_dups      # don't store duplicate commands
setopt hist_ignore_space         # ignore commands starting with a space
setopt hist_reduce_blanks        # collapse extra whitespace
# setopt inc_append_history      # uncomment to append history immediately

# ===============================================================================
# 4. Interactive options (enable as needed)
# ===============================================================================
setopt auto_cd                   # cd by typing a directory name
setopt auto_pushd                # push dirs on cd
setopt pushd_ignore_dups         # don't push duplicate dirs
setopt interactive_comments      # allow # comments in interactive shells
# glob_complete disabled - expanding globs in completion is slow
# setopt glob_complete

bindkey -e                       # emacs-style key bindings

# ===============================================================================
# 5. Completions - key optimization: zcompdump cache + compinit -C stays fast
# ===============================================================================
# Create cache dir if missing
[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh

# Only a few third-party completions; avoid 192 files slowing compinit
# Uncomment for full zsh-completions (cost: ~50ms first zcompdump build)
# fpath+=(${HOME}/.zsh_packages/zsh-completions/src/)

autoload -Uz compinit
# Strategy: -C skips the security audit when zcompdump exists (~35ms saved);
#           full build only on first run or after zcompdump is deleted
if [[ -f ~/.cache/zsh/zcompdump ]]; then
    compinit -C -d ~/.cache/zsh/zcompdump
else
    compinit -d ~/.cache/zsh/zcompdump
    # zcompile to bytecode right after the first build for faster loading
    zcompile ~/.cache/zsh/zcompdump
fi

# Completion cache (faster completion results)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/zcompcache

# Menu behavior
zstyle ':completion:*' menu select=2
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

# Case: case-insensitive file/arg matching, but keep command names sensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:*:-command-:*' matcher-list ''

# Colors
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:options' list-colors '=(#b)(-- *)=34'

# ===============================================================================
# 6. Plugins - load only what's needed
# ===============================================================================
# fast-syntax-highlighting is heavy (~5-6ms of startup); defer loading to the
# first precmd. The loader is registered BEFORE autosuggestions' precmd hook so
# fsh wraps widgets first and autosuggestions binds over them (outer wrapper):
# its suggestion highlight is applied last and survives fsh's region_highlight
# rebuild. The shell appears immediately; fsh registers before the first prompt.
typeset -gi _fsh_loaded=0
load_fast_syntax_highlighting() {
  (( _fsh_loaded )) && return
  _fsh_loaded=1
  [[ -r ${HOME}/.zsh_packages/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] &&
    source ${HOME}/.zsh_packages/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
}
precmd_functions+=(load_fast_syntax_highlighting)

source ${HOME}/.zsh_packages/zsh-autosuggestions/zsh-autosuggestions.zsh

# ===============================================================================
# 7. Prompt - time + exit status + command duration + path
# ===============================================================================
# Prompt fully precomputed in precmd into plain strings; rendering only does
# percent expansion: no prompt_subst, no $(...) subprocesses
zmodload zsh/datetime
autoload -Uz add-zsh-hook

# shorten path - internal version writes a global (no subprocess; used by precmd)
function _short_pwd() {
  local p="${PWD/#$HOME/~}"
  local parts=(${(s:/:)p})
  local total=${#parts[@]}

  if (( total <= 1 )); then
    _pwd_short=$p
    return
  fi

  local result=""

  # first component (abbreviated)
  [[ "${parts[1]}" == "~" ]] && result="~" || result="/${parts[1][1,2]}"

  # middle components (abbreviated)
  for ((i=2; i<total; i++)); do
    result+="/${parts[i][1,2]}"
  done

  # last component (full)
  result+="/${parts[-1]}"
  _pwd_short=$result
}

# keep the echo version for manual use
function short_pwd() {
  _short_pwd
  echo "$_pwd_short"
}

# Command duration: shown on demand (only above threshold), formatted as h/m/s;
# built-in integer arithmetic and string ops only, no external commands
typeset -gi cmd_start cmd_time
typeset -gi CMD_TIME_THRESHOLD=3      # show when >= this many seconds; 0 = always
typeset -g _time_str _pwd_short _exit_seg _cmd_seg

update_cmd_start() { cmd_start=$EPOCHSECONDS }

update_cmd_time() {
  local last_status=$? h m s seg=''
  cmd_time=$((cmd_start ? EPOCHSECONDS - cmd_start : 0))
  cmd_start=0                          # reset; avoid inflated time on empty enter/redraw
  strftime -s _time_str '%H:%M:%S' $EPOCHSECONDS   # current time (zsh builtin, no subprocess)
  _exit_seg=''
  (( last_status )) && _exit_seg="%F{red}[${last_status}]%f"
  _short_pwd                           # writes path into _pwd_short, no subprocess
  if (( cmd_time >= CMD_TIME_THRESHOLD )); then
    h=$((cmd_time / 3600))
    m=$((cmd_time % 3600 / 60))
    s=$((cmd_time % 60))
    if (( h )); then
      seg="${h}h ${m}m ${s}s"
    elif (( m )); then
      seg="${m}m ${s}s"
    else
      seg="${s}s"
    fi
  fi
  # SSH marker assembled here too
  [[ -n "$SSH_CONNECTION" ]] && seg="SSH $seg"
  _cmd_seg=${seg:+%F{yellow}[$seg]%f}
  # Assemble the full prompt: percent escapes only, no $(...) or ${...}
  PROMPT="%F{green}${_time_str}%f ${_exit_seg:+${_exit_seg} }${_cmd_seg:+${_cmd_seg} }%F{blue}${_pwd_short}%f
${_SECOND_LINE}"
}
add-zsh-hook preexec update_cmd_start
add-zsh-hook precmd update_cmd_time

_PROMPT='%F{blue}>%f '

_SECOND_LINE="${_PROMPT}"

# ===============================================================================
# 8. P10k config - uncomment to enable p10k
# ===============================================================================
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================================================
# 9. Extra config
# ===============================================================================
source ${HOME}/.zsh_extra
