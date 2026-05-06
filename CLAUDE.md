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

脚本按顺序执行 8 个相互独立的安装阶段：

1. **系统软件包** — 通过 `dnf` 安装 Kvantum、Klassy、Papirus、字体、git、curl
2. **Ghostty 终端** — 若尚未安装，从 COPR 源安装
3. **AdwaitaMono Nerd Font** — 从 GitHub Releases 下载，安装至 `~/.local/share/fonts/`
4. **Catppuccin KDE 主题** — 克隆上游仓库，以 Mocha/Mauve/Modern 参数运行其安装器，通过 `lookandfeeltool` 应用主题
5. **SDDM 登录主题** — 下载预构建包，安装至 `/usr/share/sddm/themes/`，写入 `/etc/sddm.conf.d/theme.conf`
6. **Papirus 图标文件夹** — 对所有 Papirus 变体应用 Catppuccin mauve 配色
7. **KWin 特效** — 通过 `kwriteconfig5` 配置合成器与动画，经由 D-Bus 重载
8. **Ghostty 配置** — 写入 `~/.config/ghostty/config`，包含 Catppuccin Mocha 主题与 AdwaitaMono 字体

## 关键模式

- **彩色输出辅助函数：** `info()`、`ok()`、`warn()`、`die()`，提供统一的用户反馈
- **临时目录清理：** `TMPDIR_SETUP=$(mktemp -d)` 配合 `trap 'rm -rf "$TMPDIR_SETUP"' EXIT`
- **幂等性：** 各阶段在下载或安装前检查是否已存在，避免重复操作
- **无交互提示：** 全程无需用户输入；结束时打印编号检查清单，引导手动验证
