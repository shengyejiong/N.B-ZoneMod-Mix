# ZoneMod 2.9.2 服务器更新清单（2026-10-15）

本文适用于已经部署本仓库 N&B ZoneMod 2.9.1b 整合包、EXP 分队兼容修复和 2026 年 9 月上游更新的 Linux 服务器。此前的本地提交为 `b5ca82970d3974a5453f4177e1a5bde8f3794418`；本次合入的上游提交为 `8809937d0f1fd00d961c51367e5d08057f13c5d6`，包含 ZoneMod 2.9.2 和武器生成插件 1.2 的两次热修复。

上游对比：[本次 11 个提交](https://github.com/SirPlease/L4D2-Competitive-Rework/compare/d9b09c55...8809937d)。如果服务器比上述前提更旧，本清单不能替代之前的部署步骤。

## 1. 路径对应方式

本地文件根目录：

```text
D:\download\插件\zone\N.B-ZoneMod-Mix\
```

服务器文件根目录（按此前日志记录）：

```text
/home/steam/Steam/steamapps/common/l4d2/left4dead2/
```

下表的路径都是相对于这两个根目录的相同路径。例如：

```text
本地：D:\download\插件\zone\N.B-ZoneMod-Mix\addons\sourcemod\plugins\optional\l4d2_m2_control_eq.smx
远端：/home/steam/Steam/steamapps/common/l4d2/left4dead2/addons/sourcemod/plugins/optional/l4d2_m2_control_eq.smx
```

Linux 文件名区分大小写，保留表中的目录层级和文件名。

## 2. 普通 ZoneMod：建议一起上传的 15 个文件

这 15 个文件包含本次运行文件变化，以及新启用插件的必要配套文件。上传本地合并后的版本，保留 N&B 的配置修改；不要另外下载上游纯净 CFG 覆盖。

| 序号 | 本地与服务器相同的相对路径 | 操作及用途 |
| --- | --- | --- |
| 1 | `addons/sourcemod/plugins/fixes/l4d_vomit_trace_patch.smx` | 新增；喷吐碰撞修复 2.5 |
| 2 | `addons/sourcemod/gamedata/l4d_vomit_trace_patch.txt` | 新增；必须与上面的插件配套 |
| 3 | `cfg/generalfixes.cfg` | 覆盖；加载喷吐修复插件 |
| 4 | `addons/sourcemod/plugins/optional/l4d_boss_percent.smx` | 覆盖；3.2.8，修复低百分比 Tank 流程解析 |
| 5 | `addons/sourcemod/plugins/optional/l4d2_m2_control_eq.smx` | 覆盖；1.17，增加胖子被推后的喷吐延迟 |
| 6 | `addons/sourcemod/plugins/optional/l4d2_allow_cs_weapons.smx` | 覆盖；1.1，允许刷新点使用 CS 武器 |
| 7 | `addons/sourcemod/gamedata/l4d2_allow_cs_weapons.txt` | 已有依赖文件，建议一并补齐；本次上游未修改 |
| 8 | `addons/sourcemod/plugins/optional/l4d2_weapon_spawn_variety.smx` | 新增；1.2，调整 T1 武器种类，保持对抗两半场随机结果一致 |
| 9 | `addons/sourcemod/plugins/optional/fix_pill_pass.smx` | 已有插件，本次开始在 ZoneMod 中启用；建议一并上传，避免服务器缺文件 |
| 10 | `addons/sourcemod/gamedata/fix_pill_pass.txt` | 传药修复的配套文件；本次变动为 Windows 支持，Linux 也可直接使用这份完整文件 |
| 11 | `cfg/cfgogl/zonemod/confogl.cfg` | 覆盖；准备面板版本号更新为 2.9.2 |
| 12 | `cfg/cfgogl/zonemod/shared_cvars.cfg` | 覆盖；增加药品流程筛选、CS 武器刷新及终局 Tank 参数；保留 N&B 自动开局等设置 |
| 13 | `cfg/cfgogl/zonemod/shared_plugins.cfg` | 覆盖；加载两个武器插件，以 `fix_pill_pass` 替换 `pill_passer`；保留 Bot 吃药设置 |
| 14 | `cfg/cfgogl/zonemod/shared_settings.cfg` | 覆盖；MP5、冲锋枪和马格南数值及替换规则；保留 Lerp 上限 0.100 等 N&B 设置 |
| 15 | `cfg/cfgogl/zonemod/zonemod.cfg` | 覆盖；把 MP5 纳入冲锋枪数量限制，保留 N&B 自动暂停开关 |

其中 7 和 9 是未发生变化的依赖文件；已经确认服务器有同版本文件时，可以不重复传。

依赖本整合包现有的 SourceMod、SDKHooks、SDKTools、DHooks、Left 4 DHooks 和 Source Scramble。尤其确认服务器 `addons/sourcemod/extensions/sourcescramble.ext.so` 存在并能加载。新增喷吐修复和传药修复依赖 Source Scramble；本次没有修改这些扩展，不要求重新覆盖整套扩展。

`pill_passer.smx` 可留在 `plugins/optional/`，其他比赛模式仍可能使用它。普通 ZoneMod 的加载项已经换成 `fix_pill_pass`，不要在 `cfg/sharedplugins.cfg` 或其他自定义链里重复加载旧 `pill_passer`；重启并进入 ZoneMod 后检查两个插件没有同时运行。

## 3. 按实际使用情况补充

### 3.1 玩 Haunted Forest（三方图）

再覆盖下面一个文件：

```text
cfg/stripper/zonemod/maps/hf01_theforest.cfg
```

修复第一关的多处卡点、越界、梯子和显示问题，缩短开场镜头，在卡车后增加弹药。想保持本地与服务器完整一致，也可以直接上传；没有运行这张图时不会触发该文件。

### 3.2 更新 !match 菜单版本文字

服务器文件：

```text
addons/sourcemod/configs/matchmodes.txt
```

上游只把普通 ZoneMod、ZoneMod Retro、ZoneHunters 的显示版本改成 2.9.2。本地这个文件同时有尚未提交的 `zonemod_dv` 菜单入口，合并时会保留。

如果服务器也部署了完整 DV 模式，可以上传合并后的本地文件。否则只在服务器原文件中把这三处版本文字 `2.9.1b` 改成 `2.9.2`，保留服务器实际已有的模式条目；不要为了菜单文字引入未安装的 DV 模式。菜单文字不决定玩法是否升级成功。

### 3.3 使用 1v1、2v2、3v3、ZoneHunters 或 Retro

本次这些文件只修改准备面板版本文字；按实际启用的模式覆盖：

```text
cfg/cfgogl/zm1v1/confogl.cfg
cfg/cfgogl/zm2v2/confogl.cfg
cfg/cfgogl/zm3v3/confogl.cfg
cfg/cfgogl/zonehunters/confogl.cfg
cfg/cfgogl/zh1v1/confogl.cfg
cfg/cfgogl/zh2v2/confogl.cfg
cfg/cfgogl/zh3v3/confogl.cfg
cfg/cfgogl/zoneretro/confogl.cfg
```

部分模式共用普通 ZoneMod 配置或同一个 SMX，因此共用插件的更新也可能影响它们；不能仅凭版本文字判定所有模式具有完全相同的 2.9.2 武器规则。

### 3.4 本地 DV 与 ReadyUp 修改

合并前已有的 `zonemod_dv` 目录、`dv_versus.sp/.smx`、ReadyUp 源码/SMX 和《DV手枪控制对抗模式.md》保留为原先的本地修改，不属于这次上游更新，也没有把 DV 的武器、伤害规则顺带升级。

这次不需要重新上传 `readyup.smx` 或整套 DV 文件。共享的 `generalfixes.cfg` 和更新后的共用 SMX 仍可能影响 DV；如果同时运营该模式，更新后补做一次 DV 测试。原 DV 部署说明位于本地 `docs/DV手枪控制对抗模式.md`，与上述 DV 文件一起保持原先的未提交状态。

## 4. 本次不需要上传或修改的内容

- `cfg/server.cfg`、服务器自己的 `cfg/server1.cfg`、启动脚本、RCON、管理员配置和大厅密钥。
- `cfg/sharedplugins.cfg`（注意与 `cfg/cfgogl/zonemod/shared_plugins.cfg` 区分）。
- `exp_interface.smx`、`exp_roundstate.smx`、`mt_experience.smx`、`mix_team.smx`：本次没有改动。
- `pause.smx` 和 `l4d2_antibaiter.smx`：如果之前已经部署 6.9.0 和 1.4.0，本次不用再次替换。
- `confoglcompmod.smx`：本次与此前版本相同；仓库现有版本已包含药品流程筛选参数。
- `addons/sourcemod/scripting/` 下的 `.sp/.inc`、README 和本文：用于源码保存、编译和说明，服务器运行不依赖这些文档文件。
- `plugins/disabled/` 内的历史备份。

## 5. 本次会生效的主要玩法变化

- MP5 加入普通 ZoneMod 冲锋枪池，计入同一类武器数量限制；三连发步枪的替换目标改为 MP5。
- 普通 SMG 装填时间 1.7 秒、射程 2000、距离衰减系数 0.83；删除原先强制伤害 22 的配置。
- 消音 SMG 伤害 28、每发散布增长 0.30、距离衰减系数 0.65。
- MP5 弹匣 55、装填 2.7 秒、射程 2000、距离衰减系数 0.75。
- 马格南伤害 90、移动散布上限 1.5、穿透层数 3。
- 药品流程筛选范围 30%～80%，最小间隔为全图流程的 4%；地图专属规则可以覆盖，终局默认豁免。
- 移除强制 Tank 速度 205、石头生命值 100 的配置；移除不等于最终运行数值必然是多少，应以服务器查询为准。
- 胖子被推后新增喷吐延迟，插件默认值为 1.0 秒。

当前 N&B EXP 公式仍只读取普通 SMG、消音 SMG、木喷和铁喷击杀，没有计入 MP5 击杀。本次为保持原评分口径未修改公式；这不会造成加载错误，但 MP5 击杀不会进入该击杀统计部分。

## 6. 推荐更新顺序

1. 保存服务器上将被替换文件的备份，按日期放在服务器游戏目录之外。不要把备份 SMX 放进 `plugins/` 自动加载目录。
2. 停服后上传第 2 节的 15 个文件；按实际地图和模式选择第 3 节文件。
3. 如果服务器 CFG 还有未同步到本地的额外调整，先对比再覆盖，尤其是三个 `shared_*.cfg` 和 `cfg/generalfixes.cfg`。
4. 完整重启服务器，再让它载入 ZoneMod。内存补丁和生成钩子适合在完整重启后验证，不建议仅靠热重载完成这次升级。
5. 按下节检查加载、日志和一轮实测。

不需要删除原 `pill_passer.smx`。若发现普通 ZoneMod 下它仍在运行，检查自定义加载链或 root 自动加载目录是否还有另一份，再移出本模式的加载链；其他模式可能仍依赖 `plugins/optional/pill_passer.smx`。

## 7. 重启后验证

在服务器控制台执行：

```text
sm plugins list
sm exts list
```

确认以下插件在进入普通 ZoneMod 后为运行状态。插件编号可能变化，使用列表中的实际编号执行 `sm plugins info <编号>`：

| 文件 | 预期版本 |
| --- | --- |
| `fixes/l4d_vomit_trace_patch.smx` | 2.5 |
| `optional/l4d_boss_percent.smx` | 3.2.8 |
| `optional/l4d2_m2_control_eq.smx` | 1.17 |
| `optional/l4d2_allow_cs_weapons.smx` | 1.1 |
| `optional/l4d2_weapon_spawn_variety.smx` | 1.2 |
| `optional/fix_pill_pass.smx` | 1.0 |

查询关键参数，确认当前执行的是普通 ZoneMod 新配置：

```text
sm_cvar director_cs_weapon_spawn_chance
sm_cvar confogl_pills_flow_min
sm_cvar confogl_pills_flow_max
sm_cvar confogl_pills_flow_separation
sm_cvar l4d2_m2_boomer_block_vomit_delay
sm_cvar sm_max_lerp
```

预期依次为 `1.0`、`0.30`、`0.80`、`0.04`、`1.0`、`0.100`，浮点显示可能略有差异。如果服务器有个人覆盖配置，以最终加载顺序排查差异。

检查 `addons/sourcemod/logs/errors_YYYYMMDD.log`，以及 Confogl 可能使用的 `addons/sourcemod/logs/confoglcompmod/`。重点排除缺少 gamedata、签名匹配失败、扩展加载失败或找不到 native 等新错误。

真人实测至少包括：胖子正常喷吐/被推后喷吐、传药不异常触发推人、MP5 与 T1 武器刷新及上下半场一致性、`!exp` 和 `!mix`、终局换图。若使用 Haunted Forest，再检查开场和卡车后弹药；若运营 DV，另测其手枪限制与伤害规则。

本文的检查依据为本地合并后的源码、CFG、已有 SMX 和依赖文件；不代表 Linux SRCDS 已实际加载成功，也不代替两半场和真人玩法验证。
