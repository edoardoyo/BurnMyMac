# 🔥 BurnMyMac

> 菜单栏一键防休眠，让 Mac 安心跑整夜。

macOS 的电源管理在电池模式下格外激进——系统动不动就睡，后台任务、脚本、下载全被挂起。BurnMyMac 用一个菜单栏开关替你按住系统唤醒，同时**允许屏幕正常熄灭**，兼顾省电和任务连续性。

## 为什么选它

市面上防休眠工具不少，BurnMyMac 有几个实在的区别：

- **双 IOKit 断言**。大多数同类工具只用一个 `PreventUserIdleSystemSleep` 断言，电池模式下容易被 macOS 绕过。BurnMyMac 同时持有 `PreventSystemSleep` + `PreventUserIdleSystemSleep` 两个断言，插电靠前者硬扛，电池靠后者兜底，覆盖更稳。
- **允许屏幕关闭**。不是粗暴地「一切全亮」，而是只阻止系统休眠，屏幕、屏保照常。整晚跑任务屏幕不用一直开着。
- **零残留**。不写配置文件、不留缓存、不注册后台服务，删除 `.app` 即完全卸载。
- **纯 Swift，零依赖**。整个应用不到 500 行代码，只依赖 macOS 自带的 AppKit + IOKit，没有第三方框架，构建产物极小，空闲时几乎不占 CPU。

## 安装

### 下载 Release（推荐）

从 [Releases](../../releases) 页面下载 `BurnMyMac.zip`，解压后拖入「应用程序」文件夹即可。

### 从源码构建

```bash
git clone https://github.com/edoardoyo/BurnMyMac.git
cd BurnMyMac
./scripts/build.sh
open build/BurnMyMac.app
```

要求 macOS 13.0+，Xcode Command Line Tools。

## 使用

启动后自动弹出使用指南窗口，看完点「静默启动」即可回归菜单栏。

- **左键单击** 菜单栏 🔥 图标 → 切换防休眠（图标变橙 = 已开启）
- **右键单击** → 弹出菜单（切换 / 使用指南 / 退出）

## 行为

| 场景 | 是否受影响 |
|------|-----------|
| 系统空闲自动休眠 | ✅ 被阻止 |
| 显示器关闭 / 屏保启动 | ❌ 正常发生 |
| 手动点击  → 睡眠 | ❌ 不阻止 |
| 笔记本合盖 | ❌ 硬件行为，不干预 |
| 低电量强制休眠 | ❌ 系统保护，无法覆盖 |

退出 BurnMyMac 或关闭开关后，系统节能策略立刻恢复默认。

## 原理

```
IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep, ...)     // AC 时最强
IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep, ...)  // 电池时兜底
```

两个断言同时持有。系统只要有一个活跃断言就不会休眠。

## 许可

MIT
