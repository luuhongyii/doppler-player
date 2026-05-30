# GitHub 自动打包 IPA

在 GitHub Actions 的 macOS 虚拟机上完成 **签名 + 导出 IPA**，下载后可用 **Sideloadly** 装进 iPhone。

**不需要自己的 Mac**，但需要：

1. GitHub 账号  
2. 普通 **Apple ID**（不必付费开发者）  
3. 在仓库里配置 3 个 **Secrets**

---

## 第一步：准备 Apple 信息

### 1. Apple ID

你的 iCloud 邮箱，例如 `you@example.com`。

### 2. 应用专用密码

1. 打开 [appleid.apple.com](https://appleid.apple.com)  
2. 登录 → **登录与安全性** → **App 专用密码**  
3. 生成一个密码（例如标签填 `GitHub Actions`）  
4. 复制 **xxxx-xxxx-xxxx-xxxx**（只显示一次）

### 3. Team ID（开发团队 ID）

任选一种方式查看 **10 位** 字母数字：

- [developer.apple.com/account](https://developer.apple.com/account) → 会员资格 / Membership → **Team ID**  
- 或借 Mac：Xcode → Settings → Accounts → 选中账号 → Team 一栏括号里的 ID  

免费个人账号的 Team ID 一般就是你的 **Personal Team**。

### 4. Bundle ID（可选）

默认使用 `com.doppler.player`。若签名提示 ID 已被占用，在 GitHub 增加 Secret：

| Secret | 值 |
|--------|-----|
| `APP_BUNDLE_ID` | 唯一 ID，如 `com.你的名字.dopplerplayer` |

并在本地 Xcode 里把 **Bundle Identifier** 改成相同值后 push。

---

## 第二步：推送代码到 GitHub

在项目目录（`C:\Games\player`）执行：

```bash
git init
git add .
git commit -m "Add Doppler Player"
git branch -M main
git remote add origin https://github.com/你的用户名/你的仓库名.git
git push -u origin main
```

---

## 第三步：配置 GitHub Secrets

仓库页面 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Name | 填什么 |
|------|--------|
| `APPLE_ID` | 你的 Apple ID 邮箱 |
| `APPLE_APP_SPECIFIC_PASSWORD` | 应用专用密码（带横杠那串） |
| `DEVELOPMENT_TEAM` | 10 位 Team ID |
| `APP_BUNDLE_ID` | （可选）自定义 Bundle ID |

⚠️ 不要把密码写进代码或发到聊天里，只放在 GitHub Secrets。

---

## 第四步：运行打包

1. 仓库 → **Actions**  
2. 左侧选 **Build IPA**  
3. 右侧 **Run workflow** → 选 `main` → **Run workflow**  
4. 等待约 10～20 分钟（首次可能更久）  
5. 绿色 ✓ 后点进该次运行 → 底部 **Artifacts** → 下载 **DopplerPlayer-ipa**  
6. 解压得到 **DopplerPlayer.ipa**

---

## 第五步：装进 iPhone

见 [INSTALL-WITHOUT-MAC.md](INSTALL-WITHOUT-MAC.md) 的 Sideloadly 部分：

1. Windows 安装 Sideloadly  
2. 数据线连 iPhone  
3. 拖入 `DopplerPlayer.ipa` → 安装 → 手机里信任开发者  

免费签名约 **7 天** 有效，过期后重新下载 Artifact 再装一次（或重新 Run workflow）。

---

## 常见问题

### Workflow 红色失败：Authentication failed

- 检查 `APPLE_APP_SPECIFIC_PASSWORD` 是否为 **应用专用密码**，不是 Apple ID 登录密码  
- Apple ID 是否开启双重认证（开应用专用密码通常需要）

### No profiles for 'com.doppler.player'

- 添加 Secret `APP_BUNDLE_ID` 为唯一字符串  
- 在 Xcode 或 `project.pbxproj` 中同步修改 Bundle Identifier 后 push  

### 私有仓库 Actions 分钟数不够

- 改为 **Public** 仓库（公开代码），或购买 GitHub 额度  

### 和「iOS Build」workflow 的区别

| Workflow | 产物 | 用途 |
|----------|------|------|
| **iOS Build** | 模拟器 `.app` | 检查能否编译 |
| **Build IPA** | 真机 `.ipa` | Sideloadly 安装 |

---

## 安全说明

- Secrets 仅用于 GitHub Actions，不会出现在日志里（Fastlane 会掩码）  
- 建议使用 **专用 Apple ID** 或应用专用密码，不要用主账号密码  
- IPA 在 Artifacts 保留 30 天，到期可重新 Run workflow 生成
