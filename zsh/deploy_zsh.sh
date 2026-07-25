#!/usr/bin/env zsh
# =============================================================================
#  deploy_zsh.sh — 部署优化后的 zsh 配置 + 预编译 + 缓存初始化
#  用法: zsh deploy_zsh.sh
# =============================================================================
set -e

DOTFILES="${0:A:h}"                    # 脚本所在目录 (src/dotfiles/zsh)
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
# 先删除旧的 dump 以强制完整重建
rm -f "$COMPDUMP" "$COMPDUMP.zwc"
zsh -i -c "exit"   # 触发 compinit 生成 zcompdump

echo "==> 4/5 清理旧编译文件 + zcompile 预编译"
# 清理 home 目录下可能残留的 .zwc 文件
rm -f "$HOME_ZSHRC.zwc" "$HOME_ZSH_EXTRA.zwc"

# 仅编译 zcompdump（放在缓存目录，不污染 $HOME）
zcompile "$COMPDUMP"

echo "==> 5/5 部署完成！"
echo ""
echo "现在启动新终端，startup 时间应降至 ~15-25ms。"
echo "验证: for i in {1..5}; do time zsh -i -c 'exit'; done"