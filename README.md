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

  演示图片:![应用内小窗演示](https://r2.170529.xyz/PicList/2026/02/IMG_20260222_194923.avif)
- [x] 实现了可以和其他应用同时播放音频的功能
- [x] 播放器新增应用内音量控制功能，并支持在应用内音量模式下增强至 200%
- [x] 支持半屏和全屏独立选择默认画质
- [x] 收藏夹/分P/合集支持随机播放
- [x] 增强系统媒体控制（通知栏/锁屏）可根据多P/合集/播放列表动态显示上一集/下一集按钮
- [x] 在听视频界面的评论中也实现了根据评论时间戳快速跳转的功能
- [x] 直播超级聊天（SC）卡片支持显示发送时间
- [x] 尝试支持直播心跳功能，用于粉丝团亲密度积累

**字幕、AI 与离线缓存**
- [x] 新增 AI 字幕分析功能，支持自定义 OpenAI 兼容 API 地址和模型、时间戳跳转、模板预设和对话持久化
- [x] 在保存字幕的功能中添加了选择保存为原始WEBVTT格式和SRT格式的选项,转换逻辑参考了BiliRoamingx项目中的实现
- [x] 离线缓存新增“全部视频 / 文件夹”双视图，支持文件夹管理、手动排序、批量归类和按文件夹顺序播放
- [x] 离线缓存视频支持 CC 字幕下载与离线播放
- [x] 离线缓存播放支持元数据持久化，播放本地缓存时可恢复章节进度条与 SponsorBlock
- [x] 离线缓存播放与管理能力保留，Windows 端缓存工作流持续优化中

**弹幕与屏蔽**
- [x] 增强合并弹幕功能，添加类[Pakku.js](https://github.com/xmcp/pakku.js)实现，重复弹幕字体随数量而增大,可设置放大阈值和放大速度

  演示图片:![合并弹幕演示](https://r2.170529.xyz/PicList/2026/02/Pakku_Life.avif)
- [x] 增强原有的弹幕屏蔽功能，使用列表式可视化菜单替换了原有的|分割正则，尝试支持了更复杂的正则
- [x] 弹幕屏蔽列表支持导入/导出，方便跨设备迁移、备份或使用 AI 辅助编辑

**推荐、动态与评论过滤**
  对于推荐流、动态流和评论的过滤功能，在原有的基础上基于个人习惯和社区反馈进行了增强和调整，增加了更多的过滤条件和应用场景，并优化了过滤列表的编辑体验。
- [x] 推荐流过滤支持标题关键词、UP 名称关键词、分区关键词、屏蔽用户、视频时长、播放量、点赞率和已关注 UP 豁免，首页 app 端推荐还支持屏蔽无权查看视频（如充电专属视频）
- [x] 推荐流过滤器拓展到可选择应用到相关视频、热门视频、分区视频和搜索结果，搜索结果中仅过滤标题关键词和屏蔽用户
- [x] 动态流过滤支持关键词、屏蔽用户、、带货动态、无权查看动态和充电专属视频动态
- [x] 评论过滤支持关键词、屏蔽用户、低等级用户、带货评论、UP 主点赞评论豁免和 UP 主参与回复评论豁免

**动态、搜索与用户信息**
- [x] UP 主空间页和关注列表新增自定义备注功能，并支持在动态页和视频详情页作者名称后显示备注
- [x] 搜索结果新增客户端本地关键词过滤，支持包含关键词和排除关键词（以增强B站比较难用的搜索功能）
- [x] 首页 App 端推荐视频卡片新增充电专属角标
- [x] 新增“显示视频推荐理由”设置项，可关闭首页视频卡片的“已关注”等推荐理由显示
- [x] 投币页面支持显示当天已获取经验数与经验上限


## 适配平台

- [x] Windows

[![Packaging status](https://repology.org/badge/vertical-allrepos/pilinara.svg)](https://repology.org/project/pilinara/versions)

## refactor

- [ ] gRPC [wip]
- [x] 用户界面
- [x] 其他


## feat
- [x] 编辑动态
- [x] DLNA 投屏
- [x] 离线缓存/播放
- [x] 播放音频
- [x] 跳过番剧片头/片尾
- [x] Windows 支持极验、短信登录 by [@My-Responsitories](https://github.com/My-Responsitories)
- [x] 视频截取动图 by [@My-Responsitories](https://github.com/My-Responsitories)
- [x] AI 原声翻译
- [x] SuperChat
- [x] 播放课堂视频
- [x] 发起投票
- [x] 发布动态/评论支持`富文本编辑`/`表情显示`/`@用户`
- [x] 修改消息设置
- [x] 修改聊天设置
- [x] 展示折叠消息
- [x] 查看用户图文
- [x] 动态话题
- [x] 直播分区
- [x] 分享`视频`/`番剧`/`动态`/`专栏`/`直播`至消息
- [x] 创建/修改/删除关注分组
- [x] 移除粉丝
- [x] 直播弹幕发送表情
- [x] 收藏夹排序
- [x] 稍后再看 ~~`未看`~~ / `未看完` / ~~`已看完`~~ 分类
- [x] WebDAV 备份/恢复设置
- [x] 保存评论/动态
- [x] 高级弹幕 by [@My-Responsitories](https://github.com/My-Responsitories)
- [x] 取消/置顶评论
- [x] 记笔记
- [x] 多账号支持 by [@My-Responsitories](https://github.com/My-Responsitories)
- [x] 屏蔽带货动态/评论
- [x] 互动视频
- [x] 发评/动态反诈
- [x] 高能进度条
- [x] 滑动跳转预览视频缩略图
- [x] Live Photo
- [x] 复制/移动/排序收藏夹/稍后再看视频
- [x] 超分辨率
- [x] 会员彩色弹幕
- [x] 播放全部/继续播放/倒序播放
- [x] Cookie登录
- [x] 显示视频分段信息
- [x] 调节字幕大小
- [x] 调节全屏弹幕大小
- [x] 收藏夹/稍后再看多选删除
- [x] 搜索用户动态
- [x] 直播弹幕
- [x] 修改头像/用户名/签名/性别/生日
- [x] 创建/编辑/删除收藏夹
- [x] 评论楼中楼查看对话
- [x] 评论楼中楼定位点击查看的评论
- [x] 评论楼中楼按热度/时间排序
- [x] 评论点踩
- [x] 私信发图
- [x] 投币动画
- [x] 取消/追番，更新追番状态
- [x] 取消/订阅合集
- [x] SponsorBlock
- [x] 显示视频完整合集
- [x] 三连动画
- [x] 番剧三连
- [x] 带图评论
- [x] 视频TAG
- [x] 筛选搜索
- [x] 转发动态
- [x] 合集图片
- [x] 删除/置顶/撤回私信
- [x] 举报用户/评论/视频/动态
- [x] 删除/发布/置顶文本/图片动态
- [x] 其他

## opt

- [x] 专栏界面
- [x] 私信界面
- [x] 收藏面板
- [x] PIP
- [x] 视频封面
- [x] 回复界面
- [x] 系统通知
- [x] 评论显示
- [x] 亮度调节
- [x] 视频播放
- [x] 视频staff
- [x] 防止bottomsheet遮挡全屏视频
- [x] 其他

## fix

- [x] 番剧分集点赞/投币/收藏
- [x] bugs

<br/>

## 功能

- [x] 推荐视频列表(app端)
- [x] 最热视频列表
- [x] 热门直播
- [x] 番剧列表
- [x] 屏蔽黑名单内用户视频
- [x] 无痕模式（播放视为未登录）
- [x] 游客模式（推荐视为未登录）

- [x] 用户相关
  - [x] 粉丝、关注用户、拉黑用户查看
  - [x] 用户主页查看
  - [x] 关注/取关用户
  - [x] 离线缓存
  - [x] 稍后再看
  - [x] 观看记录
  - [x] 我的收藏
  - [x] 站内私信
  
- [x] 动态相关
  - [x] 全部、投稿、番剧分类查看
  - [x] 动态评论查看
  - [x] 动态评论回复功能

- [x] 视频播放相关
  - [x] 双击快进/快退
  - [x] 双击播放/暂停
  - [x] 垂直方向调节亮度/音量
  - [x] 垂直方向上滑全屏、下滑退出全屏
  - [x] 水平方向手势快进/快退
  - [x] 全屏方向设置
  - [x] 倍速选择/长按2倍速
  - [x] 硬件加速（视机型而定）
  - [x] 画质选择（高清画质未解锁）
  - [x] 音质选择（视视频而定）
  - [x] 解码格式选择（视视频而定）
  - [x] 弹幕
  - [x] 字幕
  - [x] 记忆播放
  - [x] 视频比例：高度/宽度适应、填充、包含等
     
- [x] 搜索相关
  - [x] 热搜
  - [x] 搜索历史
  - [x] 默认搜索词
  - [x] 投稿、番剧、直播间、用户搜索
  - [x] 视频搜索排序、按时长筛选
    
- [x] 视频详情页相关
  - [x] 视频选集(分p)切换
  - [x] 点赞、投币、收藏/取消收藏
  - [x] 相关视频查看
  - [x] 评论用户身份标识
  - [x] 评论(排序)查看、二楼评论查看
  - [x] 主楼、二楼评论回复功能
  - [x] 评论点赞
  - [x] 评论笔记图片查看、保存

- [x] 设置相关
  - [x] 画质、音质、解码方式预设      
  - [x] 图片质量设定
  - [x] 主题模式：亮色/暗色/跟随系统
  - [x] 震动反馈(可选)
  - [x] 高帧率
  - [x] 自动全屏
  - [x] 横屏适配
- [ ] 等等

<br/>

## 下载

在 [Releases](https://github.com/Justice-ocr/PiliNara/releases) 下载 Windows x64 安装包或便携版。GitHub Actions 的 Windows 工作流也会生成构建产物。

### Arch Linux (AUR)

Arch Linux 用户可通过 AUR 安装：

- `pilinara`（源码构建）
- `pilinara-bin`（官方 Release 二进制）

```bash
# 使用 paru 安装二进制版
paru -S pilinara-bin
```

```bash
# 使用 yay 安装二进制版
yay -S pilinara-bin
```

<br/>

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
