#!/usr/bin/env bash
# KDE Catppuccin Mocha Mauve 美化一键安装脚本
# 适用于 Fedora / RPM-based KDE Plasma 桌面

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "请不要用 root 运行此脚本，需要时会自动 sudo"

TMPDIR_SETUP="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SETUP"' EXIT

# ─────────────────────────────────────────────
# 1. 系统依赖包
# ─────────────────────────────────────────────
info "安装系统依赖包..."
sudo dnf copr enable -y major-tom/klassy
sudo dnf install -y \
    kvantum \
    klassy \
    papirus-icon-theme \
    google-noto-sans-cjk-fonts \
    google-noto-serif-cjk-fonts \
    wqy-zenhei-fonts \
    git \
    curl \
    unzip
ok "系统依赖安装完毕"

# ─────────────────────────────────────────────
# 2. Ghostty 终端
# ─────────────────────────────────────────────
if ! command -v ghostty &>/dev/null; then
    info "安装 Ghostty 终端..."
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf install -y ghostty
    ok "Ghostty 安装完毕"
else
    ok "Ghostty 已安装，跳过"
fi

# ─────────────────────────────────────────────
# 3. AdwaitaMono Nerd Font
# ─────────────────────────────────────────────
FONT_DIR="$HOME/.local/share/fonts/AdwaitaMono"
if [[ ! -f "$FONT_DIR/AdwaitaMonoNerdFont-Regular.ttf" ]]; then
    info "下载 AdwaitaMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -L --progress-bar \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AdwaitaMono.tar.xz" \
        -o "$TMPDIR_SETUP/AdwaitaMono.tar.xz"
    tar -xf "$TMPDIR_SETUP/AdwaitaMono.tar.xz" -C "$FONT_DIR"
    fc-cache -f "$FONT_DIR"
    ok "AdwaitaMono Nerd Font 安装完毕"
else
    ok "AdwaitaMono Nerd Font 已安装，跳过"
fi

# ─────────────────────────────────────────────
# 4. Catppuccin KDE 全局主题（Plasma + 配色 + 光标）
# ─────────────────────────────────────────────
info "安装 Catppuccin KDE 主题..."
git clone --depth=1 https://github.com/catppuccin/kde.git "$TMPDIR_SETUP/catppuccin-kde"
cd "$TMPDIR_SETUP/catppuccin-kde"
# 参数: 1=Mocha, 4=Mauve, 1=Modern窗口装饰
./install.sh 1 4 1
cd - >/dev/null
ok "Catppuccin KDE 主题安装完毕"

info "应用 Catppuccin Mocha Mauve 全局主题..."
lookandfeeltool -a "Catppuccin-Mocha-Mauve" 2>/dev/null || \
    warn "lookandfeeltool 未能自动应用，请在系统设置 → 全局主题中手动选择"

# ─────────────────────────────────────────────
# 5. SDDM 登录主题
# ─────────────────────────────────────────────
info "安装 Catppuccin SDDM 登录主题..."
curl -L --progress-bar \
    "https://github.com/catppuccin/sddm/releases/latest/download/catppuccin-mocha-mauve-sddm.zip" \
    -o "$TMPDIR_SETUP/catppuccin-mocha-mauve-sddm.zip"
sudo unzip -qo "$TMPDIR_SETUP/catppuccin-mocha-mauve-sddm.zip" -d /usr/share/sddm/themes/

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=catppuccin-mocha-mauve
EOF
ok "SDDM 主题配置完毕"

# ─────────────────────────────────────────────
# 6. Papirus 图标 + Catppuccin 文件夹颜色
# ─────────────────────────────────────────────
info "配置 Papirus 图标文件夹颜色（Catppuccin Mocha Mauve）..."
PAPIRUS_FOLDERS="$TMPDIR_SETUP/papirus-folders"
curl -L --progress-bar \
    "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders" \
    -o "$PAPIRUS_FOLDERS"
chmod +x "$PAPIRUS_FOLDERS"

# 确保 Papirus 系列目录存在
for icon_theme in Papirus Papirus-Dark Papirus-Light; do
    if [[ -d "/usr/share/icons/$icon_theme" ]]; then
        sudo "$PAPIRUS_FOLDERS" -C violet --theme "$icon_theme"
    fi
done
ok "Papirus 文件夹颜色配置完毕"

# ─────────────────────────────────────────────
# 7. KWin 合成器与特效
# ─────────────────────────────────────────────
info "配置 KWin 合成器与动效..."
kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 5
kwriteconfig5 --file kwinrc --group Compositing --key TripleBuffering true
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key magiclampEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled true

# 通知 KWin 重新加载配置（桌面会话中运行时有效）
if dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null; then
    ok "KWin 已重新加载配置"
else
    warn "KWin 重载跳过（非图形会话），重启后生效"
fi

# ─────────────────────────────────────────────
# 8. Ghostty 配置
# ─────────────────────────────────────────────
info "写入 Ghostty 配置..."
mkdir -p "$HOME/.config/ghostty"
cat > "$HOME/.config/ghostty/config" << 'GHOSTTY_EOF'
# ── 主题 ────────────────────────────────────────────────────────
theme = Catppuccin Mocha

# ── 字体 ────────────────────────────────────────────────────────
font-family = AdwaitaMono Nerd Font
font-size = 10
font-feature = calt
font-feature = liga
font-feature = ss01
font-feature = ss02
font-feature = ss19
font-feature = ss20

# ── 外观 ────────────────────────────────────────────────────────
background-opacity = 0.95
background-blur-radius = 20
cursor-style = bar
cursor-style-blink = true
cursor-color = #f5c2e7

# 去掉标题栏（KDE 下用窗口装饰）
window-decoration = server

# 内边距
window-padding-x = 12
window-padding-y = 10
window-padding-balance = true

# ── 行为 ────────────────────────────────────────────────────────
shell-integration = zsh
scrollback-limit = 10000
copy-on-select = clipboard
confirm-close-surface = false

# ── 快捷键 ──────────────────────────────────────────────────────
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+w=close_surface
keybind = ctrl+tab=next_tab
keybind = ctrl+shift+tab=previous_tab
keybind = ctrl+shift+n=new_window
keybind = ctrl+equal=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
keybind = ctrl+zero=reset_font_size
GHOSTTY_EOF
ok "Ghostty 配置写入完毕"

# ─────────────────────────────────────────────
# 完成
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Catppuccin Mocha Mauve 美化安装完成！      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "后续手动确认项："
echo "  1. 系统设置 → 外观 → 全局主题 → 选择 Catppuccin-Mocha-Mauve"
echo "  2. 系统设置 → 外观 → 图标    → 选择 Papirus-Dark"
echo "  3. 系统设置 → 外观 → 光标    → 选择 Catppuccin-Mocha-Mauve-Cursors"
echo "  4. 系统设置 → 窗口装饰        → 选择 Klassy"
echo "  5. 注销或重启以使所有更改完全生效"
