<div align="center">
  <img width="160" height="160" src="assets/images/logo/logo.png" alt="PiliNara logo">
  <h1>PiliNara</h1>
  <p>面向 Windows 桌面的第三方哔哩哔哩客户端</p>

  <a href="https://github.com/Justice-ocr/PiliNara/actions/workflows/win_x64.yml"><img src="https://github.com/Justice-ocr/PiliNara/actions/workflows/win_x64.yml/badge.svg?branch=feat/windows-eui-neo" alt="Windows build"></a>
  <a href="https://github.com/Justice-ocr/PiliNara/releases"><img src="https://img.shields.io/github/v/release/Justice-ocr/PiliNara?include_prereleases" alt="Release"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/Justice-ocr/PiliNara" alt="License"></a>
</div>

## 项目定位

PiliNara 基于 [Starfallan/PiliNara](https://github.com/Starfallan/PiliNara) 维护，并沿用 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 的功能基础。当前分支 `feat/windows-eui-neo` 是 Windows 特化版本，重点不是简单换肤，而是重新组织桌面端的信息层级、导航方式和媒体工作流。

> [!IMPORTANT]
> `Windows Neo` 是本项目的 Windows 工作区和视觉设计名称。当前实现仍使用 Flutter，并非 EUI-NEO 技术栈重写。

本分支只面向 Windows。若需要与上游接近的通用版本，请使用 [`main`](https://github.com/Justice-ocr/PiliNara/tree/main) 分支。

## Windows Neo

- **桌面工作区**：窗口标题栏、侧栏、工作区标签和内容区形成稳定的三层导航，宽度变化时可切换为紧凑布局。
- **多标签页**：主页、搜索、视频、直播、用户、动态、下载、消息和设置可在同一窗口中并行保留；支持关闭、关闭其他标签以及快捷切换。
- **页面状态保留**：非当前标签继续保留导航栈和页面状态，关闭后台标签不会重播当前页面动画。
- **统一页面导航**：主页、动态、收藏、关注、历史、稍后再看、下载和搜索结果采用一致的二级标签与返回逻辑。
- **Miku 主题语言**：以明亮青绿色为主信号，通过不同白色混合度区分工作区、侧栏与选中状态，并使用克制的 Miku 元素建立主题辨识度。
- **轻量动效**：页面切换、卡片反馈、加载状态和标签增删使用短时、非循环动画；系统要求减少动态效果时会自动收敛。
- **桌面媒体布局**：视频评论保留在右侧上下文区域；直播聊天、贡献榜与 SuperChat 分区展示，弹幕输入在页面内完成。
- **键鼠操作**：支持播放器方向键快进/快退、直播输入框正常编辑与回车发送，以及常用标签快捷键。

### 标签快捷键

| 操作 | 快捷键 |
| --- | --- |
| 关闭当前标签 | `Ctrl + W` |
| 切换到下一标签 | `Ctrl + Tab` |
| 切换到上一标签 | `Ctrl + Shift + Tab` |
| 返回当前标签的上一页 | `Alt + Left` |

Windows Neo 工作区默认启用，可在“设置 → 播放设置 → Windows Neo 工作区”中关闭。

## 主要功能

除 Windows 专属界面外，本项目保留并持续同步上游的主要能力，包括：

- 视频、番剧、直播、动态、用户空间、收藏、历史和稍后再看
- 弹幕、字幕与双语字幕，支持 WEBVTT、SRT 等字幕导出
- 离线缓存、文件夹管理、继续播放与本地字幕
- SponsorBlock、分段进度、播放列表和系统媒体控制
- 直播弹幕、SuperChat、表情、DLNA 投屏与流偏好记忆
- 推荐流、动态、搜索结果和评论的本地过滤
- 应用内小窗、多账号、WebDAV 备份与自定义字体
- AI 字幕分析，可配置 OpenAI 兼容接口

更完整的版本变化见 [CHANGELOG.md](CHANGELOG.md)。

## 下载

在 [Releases](https://github.com/Justice-ocr/PiliNara/releases) 下载 Windows x64 安装包或便携版。GitHub Actions 的 Windows 工作流也会生成构建产物。

安装新版本前建议先在应用内导出设置，尤其是在跨分支或跨上游版本升级时。

## 本地构建

### 环境要求

- Windows 10/11 x64
- Flutter `3.44.6`，Dart `>= 3.12.0`
- Visual Studio 2022，并安装“使用 C++ 的桌面开发”工作负载
- 已启用 Flutter Windows desktop 支持

仓库提供 `.fvmrc`，使用 FVM 时会自动选择对应 Flutter 版本。

```powershell
git clone https://github.com/Justice-ocr/PiliNara.git
cd PiliNara
git switch feat/windows-eui-neo

flutter pub get
flutter run -d windows
```

生成 Debug 或 Release 构建：

```powershell
flutter build windows --debug
flutter build windows --release
```

提交改动前建议运行：

```powershell
flutter analyze
flutter test
```

## 分支与同步

| 分支 | 用途 |
| --- | --- |
| `main` | 与上游功能演进保持接近的主分支 |
| `feat/windows-eui-neo` | Windows 专属工作区、主题与交互优化 |

Windows 分支会在上游功能基础上继续维护 Windows 特化改动。合并上游时优先保留业务能力，同时单独处理与桌面导航、播放器生命周期和响应式布局有关的冲突。

## 反馈与贡献

欢迎通过 [Issues](https://github.com/Justice-ocr/PiliNara/issues) 报告问题或提出建议。提交 UI 问题时，请尽量附上：

- Windows 版本、应用版本和所在分支
- 窗口大小或缩放比例
- 可复现步骤、截图或录屏
- 是否涉及视频、直播或多个工作区标签

本项目仍在持续调整，播放器生命周期、多标签状态保持和不同 DPI 下的布局是 Windows 分支重点关注的区域。

## 声明

PiliNara 是非官方第三方客户端，与哔哩哔哩及其关联公司无关。本项目仅供学习、研究和个人使用，不提供任何破解内容；所使用的接口信息来源于公开网络。请遵守所在地法律法规、平台服务条款以及内容版权要求。

项目采用 [GNU General Public License v3.0](LICENSE) 许可。

## 致谢

- [Starfallan/PiliNara](https://github.com/Starfallan/PiliNara)
- [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)
- [orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)
- [guozhigq/pilipala](https://github.com/guozhigq/pilipala)
- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)
- [media-kit](https://github.com/media-kit/media-kit)
- [SponsorBlock](https://github.com/ajayyy/SponsorBlock)

感谢所有上游作者、贡献者和测试者。
