# 奇门罗盘 · iOS 云端构建仓

这个仓库的用途：让 GitHub 的 macOS 机器把 iOS 工程编译成未签名 `.ipa`，你在 Windows 上用 Sideloadly 重签后装进 iPhone。全程不需要 Mac。

## 仓库结构

仓库根目录采用扁平布局（网页上传无法保留子目录，故源码平铺）：

```
QimenLuopanApp.swift      程序入口
AppModel.swift            状态与重排逻辑
Astro.swift               天文与儒略日
SolarTerm.swift           二十四节气
TrueSolarTime.swift       真太阳时
QimenConstants.swift      盘面常量（九星八门八神、十二长生等）
QimenChart.swift          盘面数据结构
QimenEngine.swift         排盘内核（定局、旬首、值符值使、空亡驿马）
CompassService.swift      罗盘方位与运动传感器
ContentView.swift         主界面
LuopanView.swift          圆形罗盘
NinePalaceView.swift      九宫盘
SettingsView.swift        设置页
Info.plist                权限与包信息
project.yml               XcodeGen 工程描述
.github/workflows/ios-build.yml   云端构建流程
README.md
```

> 注意：`project.yml` 里 `sources` 是逐个文件列出的。新增 `.swift` 文件时必须同步加到 `sources`，否则不会被编译。

## 出包

1. 仓库顶部 **Actions** 标签页，首次提示时点 **I understand my workflows, go ahead and enable them**。
2. 左侧选 **iOS Build (unsigned IPA)**，右侧 **Run workflow → Run workflow**。
3. 等绿色对勾。进入运行详情，底部 **Artifacts** 下载：
   - `QimenLuopan-unsigned-ipa` → `QimenLuopan-unsigned.ipa`
   - `build-log`（失败时才有用）
4. 变红时看 **Summary** 里的"编译报错"区块，或 `build-log` 里 `error:` 行。

## 装到 iPhone（Windows 上完成）

1. 电脑装 **Sideloadly**（sideloadly.io，免费），另装 iTunes（微软商店版即可），否则识别不到设备。
2. iPhone 数据线连电脑，解锁并点"信任此电脑"。
3. 打开 Sideloadly：**IPA 文件** 选 `QimenLuopan-unsigned.ipa`，**Apple ID** 填自己的（免费账号即可），点 **Start**，按提示输入密码；开了双因素会要求填发到设备上的 6 位验证码。
4. 首次打开会提示"不受信任的开发者"：**设置 → 通用 → VPN 与设备管理 → 开发者应用** → 选自己的 Apple ID → **信任**。
5. 打开 App，允许定位权限（真太阳时与磁偏角需要），手机平放即可读数。

## 免费账号的硬限制（苹果规则，绕不开）

- 签名 **7 天**有效，到期 App 打不开，需再用 Sideloadly 装一次（AltStore / SideStore 可自动续签，但要在同一 Wi-Fi 下）。
- 免费账号同时最多 **3 个**自签 App，每周最多 **10 个** App ID。
- 想摆脱 7 天限制只有一条路：99 美元/年的 Apple Developer Program，走 TestFlight（90 天）或上架 App Store。

## 工作流做了什么

| 步骤 | 说明 |
|---|---|
| `xcodegen generate` | 由 `project.yml` 现场生成 `.xcodeproj`，不把 pbxproj 提交进仓库，避免版本冲突 |
| `xcodebuild -target ... CODE_SIGNING_ALLOWED=NO` | 用 `iphoneos` SDK 编 Release 二进制，跳过签名（签名留给本机 Sideloadly） |
| 打包 `Payload/` | 生成标准未签名 ipa 结构，并打印 bundle id / 最低系统版本 / 显示名 |
| 上传 artifact | ipa + 完整构建日志 |

## 改了代码怎么办

直接在网页上编辑 `.swift` 并提交到 `main`，会自动触发一次构建；也可手动 Run workflow。

## 已知事项

- 部署目标 iOS 17.0，仅支持 iOS 17 及以上设备。
- 构建产物未签名，**不能**直接双击安装，必须经 Sideloadly 重签。
- 节气算法为 Meeus 低精度解算，与紫金山天文台数据相差约 2–8 分钟；跨节气交接的分钟级边缘时刻可能有差异。
- 首次云端构建若暴露编译错误，属预期内的第一次真机编译（此前只在本地做过语法级检查）。
