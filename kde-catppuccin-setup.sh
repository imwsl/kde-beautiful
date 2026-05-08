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
# 4. HarmonyOS Sans 字体
# ─────────────────────────────────────────────
HARMONY_FONT_DIR="$HOME/.local/share/fonts/HarmonyOS-Sans"
if [[ -f "$HARMONY_FONT_DIR/HarmonyOS_Sans/HarmonyOS_Sans_Regular.ttf" ]]; then
    ok "HarmonyOS Sans 已安装，跳过下载"
else
    info "下载 HarmonyOS Sans 字体包（约 50 MB）..."
    mkdir -p "$HARMONY_FONT_DIR"
    curl -L --progress-bar \
        "https://github.com/huawei-fonts/HarmonyOS-Sans/raw/main/HarmonyOS%20Sans.zip" \
        -o "$TMPDIR_SETUP/HarmonyOS-Sans.zip"
    info "解压字体..."
    unzip -q "$TMPDIR_SETUP/HarmonyOS-Sans.zip" -d "$TMPDIR_SETUP/harmony-extracted/"
    cp -r "$TMPDIR_SETUP/harmony-extracted/HarmonyOS Sans/." "$HARMONY_FONT_DIR/"
    fc-cache -f "$HARMONY_FONT_DIR"
    ok "HarmonyOS Sans 字体安装完毕"
fi

HARMONY_FC_CONF="$HOME/.config/fontconfig/conf.d/60-harmonyos-default.conf"
if [[ -f "$HARMONY_FC_CONF" ]]; then
    ok "fontconfig 配置已存在，跳过"
else
    info "写入 fontconfig 优先级配置..."
    mkdir -p "$(dirname "$HARMONY_FC_CONF")"
    cat > "$HARMONY_FC_CONF" << 'FONTCONFIG_EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>

  <!-- 默认 sans-serif：英文用 HarmonyOS Sans，中文回落到 SC -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>HarmonyOS Sans</family>
      <family>HarmonyOS Sans SC</family>
    </prefer>
  </alias>

  <!-- 中文环境优先使用 HarmonyOS Sans SC -->
  <match target="pattern">
    <test name="lang" compare="contains">
      <string>zh</string>
    </test>
    <test name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="prepend">
      <string>HarmonyOS Sans SC</string>
    </edit>
  </match>

</fontconfig>
FONTCONFIG_EOF
    ok "fontconfig 配置写入完毕"
fi

info "配置 KDE Plasma 字体..."
kwriteconfig6 --file kdeglobals --group General \
    --key font                 "HarmonyOS Sans SC,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General \
    --key menuFont             "HarmonyOS Sans SC,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General \
    --key toolBarFont          "HarmonyOS Sans SC,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General \
    --key smallestReadableFont "HarmonyOS Sans SC,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General \
    --key activeFont           "HarmonyOS Sans SC,9,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group WM \
    --key activeFont           "HarmonyOS Sans SC,9,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
ok "KDE 字体配置完毕"

# ─────────────────────────────────────────────
# 5. Catppuccin KDE 全局主题（Plasma + 配色 + 光标）
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
# 6. SDDM 登录主题
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
# 7. Papirus 图标 + Catppuccin 文件夹颜色
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
# 8. KWin 合成器与特效
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
# 9. Ghostty 配置
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
# 10. fcitx5 输入法 + rime-ice + Catppuccin 主题
# ─────────────────────────────────────────────
info "安装 fcitx5 输入法相关包..."
sudo dnf install -y \
    fcitx5 \
    fcitx5-rime \
    fcitx5-qt \
    fcitx5-gtk \
    fcitx5-configtool \
    librime \
    librime-lua
ok "fcitx5 安装完毕"

# 写入 KDE Plasma 自动加载的环境变量，确保 GTK/Qt 应用使用 fcitx5
mkdir -p "$HOME/.config/plasma-workspace/env"
cat > "$HOME/.config/plasma-workspace/env/fcitx5.sh" << 'FCITX_EOF'
export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
FCITX_EOF

# rime-ice 雾凇拼音
RIME_DIR="$HOME/.local/share/fcitx5/rime"
if [[ ! -f "$RIME_DIR/rime_ice.schema.yaml" ]]; then
    info "安装 rime-ice 雾凇拼音..."
    if [[ -d "$RIME_DIR" ]]; then
        cp -r "$RIME_DIR" "${RIME_DIR}.bak.$(date +%Y%m%d%H%M%S)"
        warn "已备份原有 Rime 配置"
    fi
    mkdir -p "$RIME_DIR"
    git clone --depth=1 https://github.com/iDvel/rime-ice.git "$TMPDIR_SETUP/rime-ice"

    # 复制全部文件，再删除平台特定和无关文件
    cp -r "$TMPDIR_SETUP/rime-ice/." "$RIME_DIR/"
    rm -rf "$RIME_DIR/.git" "$RIME_DIR/.github" "$RIME_DIR/.gitignore" \
           "$RIME_DIR/README.md" "$RIME_DIR/LICENSE" "$RIME_DIR/AGENTS.md" \
           "$RIME_DIR/squirrel.yaml" "$RIME_DIR/weasel.yaml" \
           "$RIME_DIR/recipe.yaml" "$RIME_DIR/go.work" "$RIME_DIR/others"

    # 候选词 10 个，右 Shift 同左 Shift 切换中英
    sed -i 's/page_size: 5/page_size: 10/' "$RIME_DIR/default.yaml"
    sed -i 's/Shift_R: noop/Shift_R: commit_code/' "$RIME_DIR/default.yaml"
    ok "rime-ice 安装完毕"
else
    ok "rime-ice 已安装，跳过"
fi

# catppuccin-mocha-mauve 皮肤
THEME_DIR="$HOME/.local/share/fcitx5/themes/catppuccin-mocha-mauve"
if [[ ! -f "$THEME_DIR/theme.conf" ]]; then
    info "安装 fcitx5 Catppuccin Mocha Mauve 主题..."
    git clone --depth=1 https://github.com/catppuccin/fcitx5.git \
        "$TMPDIR_SETUP/catppuccin-fcitx5"
    mkdir -p "$(dirname "$THEME_DIR")"
    cp -r "$TMPDIR_SETUP/catppuccin-fcitx5/src/catppuccin-mocha-mauve" "$THEME_DIR"
    # 背景设为 80% 不透明（CC alpha）
    sed -i 's/Color=#313244$/Color=#313244CC/' "$THEME_DIR/theme.conf"
    ok "catppuccin-mocha-mauve 主题安装完毕"
else
    ok "catppuccin-mocha-mauve 主题已安装，跳过"
fi

# 写入 classicui.conf 启用主题
mkdir -p "$HOME/.config/fcitx5/conf"
cat > "$HOME/.config/fcitx5/conf/classicui.conf" << 'CLASSICUI_EOF'
Vertical Candidate List=False
WheelForPaging=True
Font="Sans 10"
MenuFont="Sans 10"
TrayFont="Sans Bold 10"
TrayOutlineColor=#000000
TrayTextColor=#ffffff
PreferTextIcon=False
ShowLayoutNameInIcon=True
UseInputMethodLanguageToDisplayText=True
Theme=catppuccin-mocha-mauve
DarkTheme=catppuccin-mocha-mauve
UseDarkTheme=True
UseAccentColor=True
PerScreenDPI=False
ForceWaylandDPI=0
EnableFractionalScale=True
CLASSICUI_EOF

# 在图形会话中重启 fcitx5 使配置生效
if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    pkill fcitx5 2>/dev/null || true
    sleep 1
    if fcitx5 -d 2>/dev/null; then ok "fcitx5 已重启"; else warn "fcitx5 启动失败，请手动启动"; fi
else
    warn "非图形会话，重启后 fcitx5 自动生效"
fi

# ─────────────────────────────────────────────
# 10. Catppuccin 壁纸（桌面 + 锁屏）
# ─────────────────────────────────────────────
WALLPAPER_DIR="$HOME/.local/share/wallpapers/catppuccin"
mkdir -p "$WALLPAPER_DIR"

DESKTOP_WP="$WALLPAPER_DIR/evening-sky.png"
LOCK_WP="$WALLPAPER_DIR/dark-cat.png"

if [[ ! -f "$DESKTOP_WP" ]]; then
    info "下载桌面壁纸（Catppuccin evening-sky）..."
    curl -L --progress-bar \
        "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/landscapes/evening-sky.png" \
        -o "$DESKTOP_WP"
    ok "桌面壁纸下载完毕"
else
    ok "桌面壁纸已存在，跳过下载"
fi

if [[ ! -f "$LOCK_WP" ]]; then
    info "下载锁屏壁纸（Catppuccin dark-cat）..."
    curl -L --progress-bar \
        "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/minimalistic/dark-cat.png" \
        -o "$LOCK_WP"
    ok "锁屏壁纸下载完毕"
else
    ok "锁屏壁纸已存在，跳过下载"
fi

# 桌面壁纸：plasma-apply-wallpaperimage 是 Plasma 6 原生命令
if command -v plasma-apply-wallpaperimage &>/dev/null; then
    info "应用桌面壁纸..."
    plasma-apply-wallpaperimage "$DESKTOP_WP" \
        && ok "桌面壁纸已应用" \
        || warn "plasma-apply-wallpaperimage 失败，请在系统设置 → 桌面壁纸中手动选择"
else
    warn "plasma-apply-wallpaperimage 未找到，请在系统设置 → 桌面壁纸中手动选择 $DESKTOP_WP"
fi

# 锁屏壁纸：写入 kscreenlockerrc
info "配置锁屏壁纸..."
cat > "$HOME/.config/kscreenlockerrc" << EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=file://${LOCK_WP}
EOF
ok "锁屏壁纸配置写入完毕（Super+L 可验证）"

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
echo "  5. 系统设置 → 字体            → 确认各项已显示 HarmonyOS Sans SC"
echo "  6. 系统设置 → 输入法          → 添加「Rime」并将其置顶"
echo "  7. 注销或重启以使所有更改完全生效"
