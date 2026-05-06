# kde-beautiful

在 Fedora KDE Plasma 桌面上一键应用 **Catppuccin Mocha Mauve** 主题套件。

<!-- 建议在此插入效果截图 -->
<!-- ![预览截图](./preview.png) -->

## 效果包含

| 组件 | 内容 |
|------|------|
| 全局主题 | Catppuccin Mocha Mauve（主题色、配色方案、光标） |
| 窗口装饰 | Klassy |
| 图标 | Papirus-Dark + Catppuccin Mauve 文件夹色 |
| 登录界面 | Catppuccin Mocha Mauve SDDM 主题 |
| 终端 | Ghostty + Catppuccin Mocha + AdwaitaMono Nerd Font |
| 合成器 | KWin 三缓冲、模糊、Magic Lamp 动画等 |

## 前置条件

- Fedora Linux（或其他 RPM 系发行版）
- KDE Plasma 桌面环境
- 可用的网络连接
- `sudo` 权限（**不要用 root 直接运行**）

## 安装

```bash
git clone https://github.com/yangjie6020/kde-beautiful.git
cd kde-beautiful
chmod +x kde-catppuccin-setup.sh
./kde-catppuccin-setup.sh
```

脚本全程无交互，完成后会提示需要手动确认的步骤。

## 安装完成后

脚本结束时会列出以下手动确认项（部分设置需在图形界面中点选）：

1. **系统设置 → 外观 → 全局主题** → 选择 `Catppuccin-Mocha-Mauve`
2. **系统设置 → 外观 → 图标** → 选择 `Papirus-Dark`
3. **系统设置 → 外观 → 光标** → 选择 `Catppuccin-Mocha-Mauve-Cursors`
4. **系统设置 → 窗口装饰** → 选择 `Klassy`
5. 注销或重启以使所有更改完全生效

## 致谢

- [Catppuccin](https://github.com/catppuccin) — 主题配色方案
- [Klassy](https://github.com/paulmcauley/klassy) — 窗口装饰
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — 图标主题
- [Ghostty](https://ghostty.org) — 终端模拟器
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) — AdwaitaMono 字体

## 许可证

[MIT](./LICENSE)
