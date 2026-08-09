#!/usr/bin/env zsh
# =============================================================================
#  deploy_zsh.sh - deploy optimized zsh configs + precompile + cache init
#  Usage: zsh deploy_zsh.sh
# =============================================================================
set -e

DOTFILES="${0:A:h}"                    # script directory (src/dotfiles/zsh)
HOME_ZSHRC="$HOME/.zshrc"
HOME_ZHENV="$HOME/.zshenv"
HOME_ZSH_EXTRA="$HOME/.zsh_extra"
CACHE_DIR="$HOME/.cache/zsh"
COMPDUMP="$CACHE_DIR/zcompdump"

echo "==> 1/5 复制配置文件到 ~"

cp "$DOTFILES/.zshenv"    "$HOME_ZHENV"
cp "$DOTFILES/.zshrc"     "$HOME_ZSHRC"
cp "$DOTFILES/.zsh_extra" "$HOME_ZSH_EXTRA"

echo "==> 2/5 创建缓存目录"
mkdir -p "$CACHE_DIR"

echo "==> 3/5 生成 compinit dump（首次较慢，约 50ms，后续秒开）"
# Remove the old dump to force a full rebuild
rm -f "$COMPDUMP" "$COMPDUMP.zwc"
zsh -i -c "exit"   # trigger compinit to build zcompdump

echo "==> 4/5 清理旧编译文件 + zcompile 预编译"
# Clean up leftover .zwc files under $HOME
rm -f "$HOME_ZSHRC.zwc" "$HOME_ZSH_EXTRA.zwc"

# Compile only zcompdump (kept in the cache dir, keeps $HOME clean)
zcompile "$COMPDUMP"

echo "==> 5/5 部署完成！"
echo ""
echo "现在启动新终端，startup 时间应降至 ~15-25ms。"
echo "验证: for i in {1..5}; do time zsh -i -c 'exit'; done"
