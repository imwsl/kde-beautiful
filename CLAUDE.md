# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指引。

## 项目概述

`kde-catppuccin-setup.sh` 是一个单文件 Bash 自动化脚本，用于在 Fedora/RPM 系发行版的 KDE Plasma 桌面上安装并配置 Catppuccin Mocha Mauve 主题套件。脚本面向非 root 用户——内部会强制检查，必要时通过 `sudo` 执行特权操作。

## 运行脚本

```bash
./kde-catppuccin-setup.sh
```

前提条件：Fedora/RPM 系 KDE Plasma 系统、可用的网络连接以及 `sudo` 权限。

## 代码检查

脚本启用了 `set -euo pipefail`。手动静态检查：

```bash
shellcheck kde-catppuccin-setup.sh
```

## 架构

脚本按顺序执行 19 个相互独立的安装阶段：

1. **系统软件包** — 通过 `dnf` 安装 Kvantum、Klassy、Papirus、字体、git、curl
2. **Ghostty 终端** — 若尚未安装，从 COPR 源安装
3. **AdwaitaMono Nerd Font** — 从 GitHub Releases 下载，安装至 `~/.local/share/fonts/`
4. **HarmonyOS Sans 字体** — 从 GitHub（huawei-fonts/HarmonyOS-Sans）下载完整字体包，安装至 `~/.local/share/fonts/HarmonyOS-Sans/`；写入 `~/.config/fontconfig/conf.d/60-harmonyos-default.conf` 设为默认 sans-serif；通过 `kwriteconfig6` 将 KDE 全部字体项设为 HarmonyOS Sans SC
5. **Catppuccin KDE 主题** — 克隆上游仓库，以 Mocha/Mauve/Modern 参数运行其安装器，通过 `lookandfeeltool` 应用主题
6. **SDDM 登录主题** — 下载预构建包，安装至 `/usr/share/sddm/themes/`，写入 `/etc/sddm.conf.d/theme.conf`
7. **Papirus 图标文件夹** — 对所有 Papirus 变体应用 Catppuccin mauve 配色
8. **KWin 特效** — 通过 `kwriteconfig6` 配置合成器与动画；禁用果冻窗口（`wobblywindowsEnabled=false`）；动画时长系数降至 0.5；经由 D-Bus（`/run/user/<uid>/bus`）重载
9. **Ghostty 配置** — 写入 `~/.config/ghostty/config`，包含 Catppuccin Mocha 主题与 AdwaitaMono 字体
10. **fcitx5 输入法** — 安装 fcitx5-rime，部署 rime-ice 雾凇拼音（10 候选词、左右 Shift 切换中英），应用 Catppuccin Mocha Mauve 皮肤（背景 80% 不透明），写入环境变量配置
11. **Catppuccin 壁纸** — 下载 evening-sky（桌面）与 dark-cat（锁屏），通过 `plasma-apply-wallpaperimage` 应用，写入 `~/.config/kscreenlockerrc`
12. **现代 CLI 工具** — 通过 `dnf` 安装：`fd-find fzf eza zoxide git-delta procs duf tealdeer hyperfine btop ncdu`；缺什么装什么，不重复安装
13. **btop 主题** — 写入 `~/.config/btop/themes/catppuccin_mocha.theme` 与 `btop.conf`，使用 braille 图形
14. **zsh 配置** — 克隆 `zsh-autosuggestions`、`zsh-syntax-highlighting`、`powerlevel10k` 至 OMZ custom 目录；备份并写入完整 `~/.zshrc`（p10k instant prompt、fzf/zoxide 集成、Catppuccin fzf 配色、eza/bat/delta 等 alias）
15. **fastfetch 配置** — 写入 `~/.config/fastfetch/config.jsonc`：Fedora logo 使用 Catppuccin Blue+Mauve 配色、内存/磁盘显示进度条、CPU/GPU 显示温度、自动检测 WiFi 接口前缀过滤网络显示
16. **Konsole 配置** — 写入 `~/.local/share/konsole/mine.profile`：Catppuccin Mocha 配色、JetBrains Mono 字体、50000 行滚动缓冲；设为 Konsole 默认 profile
17. **git delta** — 全局配置 `delta` 为 git pager：分栏显示、行号、Catppuccin Mocha 语法主题、`zdiff3` 冲突样式
18. **Neovim 插件** — 追加 which-key.nvim（快捷键面板）、mini.animate（平滑动画）、todo-comments.nvim（注释高亮）到 `~/.config/nvim/lua/plugins/ui.lua`
19. **tldr 缓存** — 首次运行时自动更新 tealdeer 缓存

## 关键模式

- **彩色输出辅助函数：** `info()`、`ok()`、`warn()`、`die()`，提供统一的用户反馈
- **临时目录清理：** `TMPDIR_SETUP=$(mktemp -d)` 配合 `trap 'rm -rf "$TMPDIR_SETUP"' EXIT`
- **幂等性：** 各阶段在下载或安装前检查是否已存在，避免重复操作
- **无交互提示：** 全程无需用户输入；结束时打印编号检查清单，引导手动验证
