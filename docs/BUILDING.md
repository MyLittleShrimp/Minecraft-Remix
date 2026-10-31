# 从源码运行与导出

## 环境

- 当前验证引擎：**Godot 4.7.2 stable**，标准版、GDScript、Compatibility 渲染。尚未验证其他引擎版本。
- 平台：Windows x64。运行预编译游戏不需要以下工具。
- 可选：Python 3.11+，仅供自动下载脚本使用，无第三方 Python 依赖。

## 用编辑器打开

安装 Godot 4.7.2，导入仓库根目录 `project.godot`，等待资源首次导入完成，然后按 F6 运行当前场景或 F5 运行主菜单。正式入口为 `scenes/main_menu.tscn`。

不需要复制本机 `.godot` 缓存；编辑器会重新生成。音乐、字体、角色和场景资源已经随源码提供。

## PowerShell 入口

以下命令在仓库根目录运行。自动下载会联网获取版本锁定文件，并校验清单中的 SHA256：

```powershell
python tools/bootstrap_godot.py
powershell -File tools/run_release.ps1 -Mode Import
powershell -File tools/run_release.ps1 -Mode Play
```

已有引擎时可以直接传入路径：

```powershell
powershell -File tools/run_release.ps1 -Mode Import -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
```

示例路径需换成自己的实际路径。下载脚本将引擎和 Windows 导出模板放在 `.tools/`，该目录不提交。

## 检查与导出

```powershell
powershell -File tools/run_release.ps1 -Mode Smoke
powershell -File tools/run_release.ps1 -Mode Export
```

Smoke 使用图形模式检查七章入口、十六首音乐资源、武器架和终章资源。测试使用 `.local/release-check/` 独立存档，不写正式玩家档；这是冒烟检查，不等于完整战斗平衡验收。设置 `REMIX_CAPTURE_DIR` 环境变量可另外输出六张截图。

导出结果位于 `builds/windows/`。如果使用自装编辑器，需先安装匹配的导出模板。导出的 EXE 与 PCK 应一起分发，并保留字体/引擎许可。

## 目录

| 目录 | 用途 |
| --- | --- |
| assets | 角色、背景、音频、字体、图标及许可 |
| resources | 武器、敌人与道具配置 |
| scenes | 主菜单、关卡和测试场景 |
| scripts | 战斗、关卡、UI、输入与存档实现 |
| tests/release_smoke.gd | 可移植的发布冒烟检查 |
| tools | 引擎下载、运行与导出入口 |
| docs | 玩家说明、截图、预告片和版本说明 |

公开快照排除了开发机路径记录、历史验证截图、私有测试存档和引擎缓存；原项目开发历史没有被改写。公开包是 v0.2.0.73 当前文件快照，不是原工作仓库 Git 历史的复制。
