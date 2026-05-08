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

脚本按顺序执行 10 个相互独立的安装阶段：

1. **系统软件包** — 通过 `dnf` 安装 Kvantum、Klassy、Papirus、字体、git、curl
2. **Ghostty 终端** — 若尚未安装，从 COPR 源安装
3. **AdwaitaMono Nerd Font** — 从 GitHub Releases 下载，安装至 `~/.local/share/fonts/`
4. **HarmonyOS Sans 字体** — 从 GitHub（huawei-fonts/HarmonyOS-Sans）下载完整字体包，安装至 `~/.local/share/fonts/HarmonyOS-Sans/`；写入 `~/.config/fontconfig/conf.d/60-harmonyos-default.conf` 设为默认 sans-serif（英文走 HarmonyOS Sans，中文走 HarmonyOS Sans SC）；通过 `kwriteconfig6` 将 KDE 全部字体项设为 HarmonyOS Sans SC
5. **Catppuccin KDE 主题** — 克隆上游仓库，以 Mocha/Mauve/Modern 参数运行其安装器，通过 `lookandfeeltool` 应用主题
6. **SDDM 登录主题** — 下载预构建包，安装至 `/usr/share/sddm/themes/`，写入 `/etc/sddm.conf.d/theme.conf`
7. **Papirus 图标文件夹** — 对所有 Papirus 变体应用 Catppuccin mauve 配色
8. **KWin 特效** — 通过 `kwriteconfig6` 配置合成器与动画，经由 D-Bus 重载
9. **Ghostty 配置** — 写入 `~/.config/ghostty/config`，包含 Catppuccin Mocha 主题与 AdwaitaMono 字体
10. **fcitx5 输入法** — 安装 fcitx5-rime，部署 rime-ice 雾凇拼音（10 候选词、左右 Shift 切换中英），应用 Catppuccin Mocha Mauve 皮肤（背景 80% 不透明），写入 `~/.config/plasma-workspace/env/fcitx5.sh` 环境变量
11. **Catppuccin 壁纸** — 下载 evening-sky（桌面）与 dark-cat（锁屏），通过 `plasma-apply-wallpaperimage` 应用桌面壁纸，写入 `~/.config/kscreenlockerrc` 设置锁屏壁纸

## 关键模式

- **彩色输出辅助函数：** `info()`、`ok()`、`warn()`、`die()`，提供统一的用户反馈
- **临时目录清理：** `TMPDIR_SETUP=$(mktemp -d)` 配合 `trap 'rm -rf "$TMPDIR_SETUP"' EXIT`
- **幂等性：** 各阶段在下载或安装前检查是否已存在，避免重复操作
- **无交互提示：** 全程无需用户输入；结束时打印编号检查清单，引导手动验证
