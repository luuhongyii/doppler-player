# 无 Mac 自己用：云 Mac 打 IPA + Sideloadly 装进 iPhone

适合：**只有 Windows + iPhone**，想**自己用**、不上架 App Store，也**不必**购买 ¥688/年的 Apple 开发者计划。

> **安装前想先看界面？** 在电脑上双击打开项目里的 [`preview/index.html`](../preview/index.html)，用浏览器预览主要页面（不能代替真机 App）。

---

## 整体流程（两步）

```
① 云 Mac（或借 Mac）用 Xcode 导出 DopplerPlayer.ipa   ← 只需做一次（或每 7 天续签时重做）
② Windows 上用 Sideloadly + 普通 Apple ID 签名并安装
```

Sideloadly **不能**从 Swift 源码编译，只能安装已有的 `.ipa` 文件。

---

## 你需要准备

| 物品 | 说明 |
|------|------|
| iPhone | 系统 **iOS 17.0+**（与项目要求一致） |
| Windows 电脑 | 安装 Sideloadly |
| 普通 Apple ID | 国区/美区均可，**不用**付费开发者 |
| 数据线 | 连接 iPhone 与电脑 |
| 云 Mac 几小时 | 或能借到一台 Mac |

### 云 Mac 可选服务（任选其一）

- [MacinCloud](https://www.macincloud.com/)（按小时租）
- [AWS EC2 Mac](https://aws.amazon.com/ec2/instance-types/mac/)（按小时，注册稍麻烦）
- 其他「Mac 远程桌面 / Mac 租赁」服务

租 **macOS 14/15 + 已装 Xcode 15+** 的镜像即可，通常 2～4 小时足够完成首次打包。

---

## 第一步：在云 Mac 上打出 IPA

### 1. 上传项目

把整个 `player` 文件夹拷到云 Mac，任选方式：

- 网盘（OneDrive、百度网盘等）
- `git clone` 你的 GitHub 仓库
- 远程桌面上传

### 2. 打开工程

1. 打开 **Xcode**
2. **File → Open** → 选择 `DopplerPlayer.xcodeproj`

### 3. 登录 Apple ID（免费即可）

1. **Xcode → Settings**（或 Preferences）→ **Accounts**
2. 左下角 **+** → **Apple ID** → 登录你的个人账号
3. 选中账号 → **Manage Certificates** → 可点 **+** 生成 **Apple Development**（若没有）

### 4. 配置签名

1. 左侧选中工程 **DopplerPlayer**（蓝色图标）
2. 选中 **TARGETS → DopplerPlayer**
3. 打开 **Signing & Capabilities**
4. 勾选 **Automatically manage signing**
5. **Team** 选你的个人团队（显示为你的名字，Personal Team）
6. **Bundle Identifier** 若冲突，改成唯一值，例如：  
   `com.你的名字.dopplerplayer`

### 5. 导出 IPA（推荐图形界面）

**方式 A：Archive 导出（标准）**

1. 顶部设备选 **Any iOS Device (arm64)**（不要选模拟器）
2. 菜单 **Product → Archive**（先等编译完成）
3. 弹出 **Organizer** 后，选中刚生成的归档 → **Distribute App**
4. 选 **Custom** → **Next**
5. 选 **Development**（自己用选这项）→ **Next**
6. 选项保持默认 → **Next** → 选签名证书 → **Export**
7. 保存到文件夹，得到 **DopplerPlayer.ipa**（或在 `Payload/DopplerPlayer.app` 外层已打好的 zip）

**方式 B：直接装到手机（若云 Mac 能连你的 iPhone）**

1. 数据线连接 iPhone
2. 顶部设备选你的 **iPhone**
3. 点 **Run (▶)**  
4. 手机上信任开发者后可直接使用，**无需 Sideloadly**  
5. 若以后没有 Mac 了，仍建议按方式 A 导出 ipa 留底

### 6. 把 IPA 拷回 Windows

- 网盘 / 邮件 / `scp` 均可  
- 记住文件路径，例如：`D:\Apps\DopplerPlayer.ipa`

---

## 第二步：Windows 上用 Sideloadly 安装

### 1. 下载安装

- 官网：[https://sideloadly.io](https://sideloadly.io)
- 安装后若杀毒软件误报，从官网重新下载

### 2. 手机准备

1. 用数据线连接 iPhone 与 Windows
2. 手机上点 **信任此电脑**
3. **iOS 16+**：**设置 → 隐私与安全性 → 开发者模式** → 打开（若安装后提示）

### 3. 安装 IPA

1. 打开 **Sideloadly**
2. 左侧登录你的 **Apple ID**（与 Xcode 可以是同一个）
3. 将 **DopplerPlayer.ipa** 拖进窗口，或点选文件
4. 确认识别到你的 **iPhone 设备**
5. 点击 **Start** / **开始**
6. 按提示在手机上输入 Apple ID 验证码（若开启双重认证）

### 4. 信任开发者

安装完成后，在 iPhone 上：

**设置 → 通用 → VPN 与设备管理**（或「设备管理」）→ 找到你的 Apple ID → **信任**

然后即可打开 **Doppler Player**。

### 5. 导入音乐

1. 打开 App → **歌曲** 或 **资料库**
2. 点 **导入音乐** 或右上角 **+**
3. 从 **文件** App 选取本机或 iCloud 里的音频  
4. 若有歌词，把同名 `.lrc` 与歌曲一并导入

---

## 免费签名的限制（自己用须知）

| 项目 | 说明 |
|------|------|
| 有效期 | 约 **7 天**，过期后 App 打不开 |
| 续签 | 再次用 Sideloadly 装同一 ipa 即可（可勾选保留数据，视工具版本而定） |
| 数量 | 免费账号同时自签 App 数量有限（通常 3 个左右） |
| 付费开发者 | **不必**，自己听歌用免费 Apple ID 即可 |

建议：日历提醒每 6 天续签一次；ipa 文件保留在 Windows，续签只需 1～2 分钟。

---

## 常见问题

### 安装失败：Invalid / Integrity 相关

- 确认 ipa 是 **真机 (arm64)** 导出，不是模拟器版  
- Bundle ID 与上次安装不一致时，先删掉手机上的旧版再装  

### Sideloadly 找不到设备

- 换原装或 MFi 数据线  
- Windows 安装 [iTunes](https://www.apple.com/itunes/) 或 **Apple 设备支持** 驱动  
- 解锁手机屏幕后再试  

### 打开 App 闪退

- 检查是否已 **信任开发者**  
- 是否超过 7 天未续签  
- iOS 版本是否 ≥ 17  

### 不想每 7 天续签

- 付费 **Apple Developer Program** 可签 1 年（自己用一般不划算）  
- 或长期有 Mac 时用 Xcode 直接 Run  

### AltStore 可以吗？

可以。流程类似：Windows 装 **AltServer**，手机装 **AltStore**，用同一 Apple ID 侧载 ipa。7 天续签需电脑与手机在同一 WiFi。

---

## 和 GitHub Actions 的关系

| 方式 | 能否装真机 |
|------|------------|
| GitHub Actions 默认产物 | ❌ 模拟器版，仅供检查编译 |
| 云 Mac + 本指南 | ✅ 推荐，自己用最实际 |
| 付费开发者 + GitHub 签名 | ✅ 可自动化，个人自用通常不必 |

---

## 最短路径回顾

1. 租 2 小时云 Mac → Xcode 打开工程 → 登录 Apple ID → Archive → 导出 **Development IPA**  
2. Windows 安装 **Sideloadly** → 拖入 ipa → 装到 iPhone → 信任开发者  
3. 打开 App 导入音乐；约 7 天后 Sideloadly 再装一次  

全程 **不需要** 上架 App Store，**不需要** 付费开发者账号。
