# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

`kde-catppuccin-setup.sh` 是一个单文件 Bash 自动化脚本，用于在 Fedora/RPM 系发行版的 KDE Plasma 桌面上安装并配置 Catppuccin Mocha Mauve 主题套件。脚本面向非 root 用户——内部会强制检查，必要时通过 `sudo` 执行特权操作。

**必须在已登录的 KDE 图形会话中运行**：脚本依赖 `lookandfeeltool` 应用主题、通过 D-Bus 重载 KWin；在 TTY 或 SSH 中执行这两步会跳过或失败。

## 常用命令

```bash
# 运行脚本
./kde-catppuccin-setup.sh

# 静态检查
shellcheck kde-catppuccin-setup.sh
```

## 架构

脚本是单文件线性执行，结构分两层：

**顶部工具层**
- `info()`、`ok()`、`warn()`、`die()` — 彩色输出
- `TMPDIR_SETUP=$(mktemp -d)` + `trap 'rm -rf "$TMPDIR_SETUP"' EXIT` — 下载工作区，退出时自动清理
- Root 用户检测（立即退出）

**主体：顺序执行的安装阶段**（约 20 个，用 `# ─────` 注释分隔）

各阶段涵盖：系统包（dnf）、字体、KDE 全局主题、SDDM、图标（Qogir）、KWin 特效、Konsole、输入法（fcitx5-rime）、壁纸、CLI 工具、zsh/btop/fastfetch/neovim 配置、git delta、tldr 缓存。

## 关键模式

**幂等检查**：每个阶段在执行前检查目标是否已存在（文件、目录、命令），避免重复操作。新增阶段必须遵循此约定：

```bash
if [[ ! -f "$TARGET" ]]; then
    # 执行安装
else
    ok "已安装，跳过"
fi
```

**配置文件写入**：用户配置（`~/.config/...`）仅在文件不存在时写入，以保留用户自定义内容；系统级文件（`/etc/`、`/usr/share/`）用 `sudo tee` 或 `sudo unzip -o` 覆盖写入。

**D-Bus 重载**：KWin 配置变更后通过 `dbus-send --session ...` 实时重载，使用 `/run/user/<uid>/bus`（`$XDG_RUNTIME_DIR/bus`）以兼容不同 uid。

**新增安装阶段约定**：
1. 在末尾追加，用 `# ─────` 注释块分隔并编号
2. 下载文件放入 `$TMPDIR_SETUP/`
3. 用户级安装不需要 sudo；写入 `/usr/`、`/etc/` 时使用 sudo
4. 结束时调用 `ok "..."`，开始时调用 `info "..."`
