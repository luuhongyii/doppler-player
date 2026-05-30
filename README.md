# Doppler Player

一款 **Doppler 风格** 的 iOS 本地音乐播放器：深色极简界面、大封面播放页、底部迷你播放器、专辑/艺术家资料库，以及锁屏与控制中心的播放控制。

> **想先看看界面？** 双击 **[preview/index.html](preview/index.html)** 预览。  
> **没有 Mac？** 用 **[GitHub 打包 IPA](docs/GITHUB-IPA.md)**（配置 Apple ID Secrets → Actions 下载 ipa → Sideloadly 安装）。  
> 也可看 **[无 Mac 安装指南](docs/INSTALL-WITHOUT-MAC.md)**（云 Mac 手动导出）。

## 功能

| 功能 | 说明 |
|------|------|
| 本地导入 | 从「文件」App 选择 MP3、M4A、AAC、WAV、AIFF、ALAC；FLAC 视系统解码支持而定 |
| 歌词 LRC | 导入同名 `.lrc` 自动匹配；播放页支持同步滚动歌词 |
| 资料库 | 歌曲列表、专辑网格、艺术家分组，支持搜索 |
| 收藏 | ♥ 收藏歌曲，「我的收藏」播放列表 |
| 播放列表 | 自建列表、添加/移除/排序、播放全部 |
| 播放 | 播放/暂停、上一首/下一首、进度拖动、随机播放、列表/单曲循环 |
| 播放增强 | 0.75×–2× 倍速、睡眠定时（15–60 分钟）、触觉反馈 |
| 界面 | 全屏「正在播放」+ 模糊专辑色背景、**下滑关闭**、底部迷你播放器 |
| 队列 | 查看、重排、删除待播列表 |
| 设置 | 资料库统计、重新匹配歌词、重新扫描 |
| 系统 | 后台播放、锁屏封面与进度、控制中心操作 |
| 外观 | **浅色 / 深色 / 跟随系统**（设置 → 外观） |

### 歌词用法

将 `歌曲名.lrc` 与 `歌曲名.mp3` **同名** 放在同一目录，一并导入即可。也支持单独导入 `.lrc`，或在设置中点击「重新匹配歌词文件」。

## 快速开始（有 Mac）

1. 用 Xcode 打开 `DopplerPlayer.xcodeproj`
2. 在 **Signing & Capabilities** 中选择你的 Apple 开发团队
3. 连接 iPhone，选择真机目标，点击 **Run** (⌘R)
4. 在 App 内点击 **导入音乐** 或右上角 **+**，从文件选取音频

音乐文件会复制到 App 沙盒的 `Documents/Music`，元数据索引保存在 `library.json`。

## 没有 Mac、自己用（推荐）

完整图文步骤：**[docs/INSTALL-WITHOUT-MAC.md](docs/INSTALL-WITHOUT-MAC.md)**

简要流程：

1. **租几小时云 Mac**（或借 Mac）→ Xcode 打开 `DopplerPlayer.xcodeproj` → 登录免费 Apple ID → **Product → Archive** → 导出 **Development** 类型的 `DopplerPlayer.ipa`
2. **Windows** 安装 [Sideloadly](https://sideloadly.io) → 数据线连 iPhone → 拖入 ipa → 开始安装
3. 手机 **设置 → 通用 → VPN 与设备管理** → 信任你的 Apple ID
4. 约 **7 天** 过期后，用 Sideloadly 再装一次（保留 ipa 即可）

| 需要 | 不需要 |
|------|--------|
| 普通 Apple ID、数据线、云 Mac 几小时 | 付费开发者 ¥688/年、上架 App Store、自己的 Mac |

## 没有 Mac：用 GitHub 云端编译（检查代码）

仓库已包含 [`.github/workflows/ios-build.yml`](.github/workflows/ios-build.yml)。GitHub 提供 **macOS 虚拟机**（`macos-15`），上面装有 Xcode，可以替你编译，**不需要你自己的苹果电脑**。

### 操作步骤

1. 在 [GitHub](https://github.com) 新建仓库（例如 `doppler-player`）
2. 在本机 `player` 目录打开终端，执行：

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/你的用户名/doppler-player.git
git push -u origin main
```

3. 打开仓库 → **Actions** → 选择 **iOS Build** → 查看是否绿色通过
4. 进入本次运行 → 底部 **Artifacts** → 下载 `DopplerPlayer-Simulator.zip`

### 能做什么、不能做什么

| 目标 | 没有 Mac | 说明 |
|------|----------|------|
| **验证能否编译通过** | ✅ | Actions 里看绿色勾即可 |
| **模拟器版 .app** | ✅ | 下载 Artifact，需在 Mac 上拖进模拟器运行 |
| **装到自己的 iPhone** | ⚠️ | 用 [安装指南](docs/INSTALL-WITHOUT-MAC.md)（云 Mac 打 ipa + Sideloadly），不必付费开发者 |
| **在 Windows 里跑 iOS 模拟器** | ❌ | 苹果不提供 Windows 版模拟器 |

### 免费账户说明

- **GitHub Actions**：公开仓库一般有免费 macOS 编译时长；私有仓库额度较少
- **Apple 开发者**：真机安装 App **必须**签名；仅编译模拟器版 **不需要** 付费开发者账号

### 手动触发编译

仓库 → **Actions** → **iOS Build** → **Run workflow**，无需再 push 代码。

## 项目结构

```
DopplerPlayer/
├── DopplerPlayerApp.swift      # 入口
├── Models/Track.swift          # 曲目与专辑模型
├── Services/
│   ├── LibraryManager.swift    # 导入、解析、索引
│   └── AudioPlayerManager.swift # AVPlayer + 锁屏控制
├── Views/                      # SwiftUI 界面
├── Theme/AppTheme.swift        # Doppler 风格配色
└── Info.plist                  # 后台音频等权限
```

## 与官方 Doppler 的差异

官方 [Doppler](https://doppler.app/) 还支持 Dropbox/iCloud、CarPlay、Last.fm 等。本仓库是 **学习/自用向** 的精简实现，专注：

- 本地文件播放
- 类 Doppler 的视觉与交互

若你需要云盘、CarPlay 或 scrobble，可以在此基础上继续扩展。

### v1.3 更新

- **浅色模式**：设置中可切换跟随系统 / 浅色 / 深色
- 浏览器预览支持深色 / 浅色切换

### v1.2 更新

- **我的收藏**：心形按钮、收藏列表、播放全部
- **自建播放列表**：创建、重命名、删除、拖序
- 长按/右滑：收藏、添加到播放列表
- 正在播放页：收藏与添加列表快捷按钮

### v1.1 更新

- LRC 同步歌词与滚动高亮
- 播放页下滑关闭（Doppler 手势）
- 睡眠定时、播放倍速、触觉反馈
- 设置页与歌词重新匹配

## 系统要求

- iOS **17.0+**
- Xcode **15.0+**
- Swift **5.9+**

## 许可证

仅供个人学习与修改使用。Doppler 为 Brushed Type 注册商标，本项目与之无关联。
