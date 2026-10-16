# DV 手枪控制对抗模式

本模式是 ZoneMod 的独立变体，在《求生之路 2》对抗模式中保留感染者的控制技能，按伤害来源决定是否扣血。服务器玩家可以通过 `!match` 菜单选择 **ZoneMod 残疾人对抗**。这是可部署测试的初版，伤害分类仍须在实际服务器上逐项验证。

## 现有方案调查

| 项目 | 链接 | 能解决的部分 | 缺口与决定 |
| --- | --- | --- | --- |
| L4D Weapon Limits | [上游源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d_weapon_limits.sp) | 通过 `SDKHook_WeaponCanUse` 限制拾取 | 不处理已有背包和感染者伤害；参考接口，不直接复用插件 |
| L4D2 Tank Damage Cvars | [上游源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_tank_damage_cvars.sp) | 以 `weapon_tank_claw`、`tank_rock` 识别拳头和石头 | 主要调整倒地拳击与石头数值，不能覆盖本玩法；DV 模式不加载它 |
| L4D2 Spit Blocker | [上游源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_spitblock.sp) | 以 `insect_swarm` 及酸液伤害标记识别酸液 | 用于特定地图区域，不能统一关闭酸液伤害；参考识别方法 |
| Incapped Charger Damage | [上游源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/charger_incap_damage.sp) | 展示了 Charger 砸地时 `inflictor=player`、`DMG_CLUB`、`m_pummelVictim` 的实际观察 | 只处理倒地目标；DV 模式不加载它 |
| L4D2 Playstats、Hittable Control | [统计源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_playstats.sp)、[物理物件源码](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_hittable_control.sp) | 分别提供控制状态 netprop 和 Tank 推动物件的识别思路 | 用于统计或物理规则，并非完整玩法插件 |
| Left 4 DHooks Direct | [AlliedModders 页面](https://forums.alliedmods.net/showthread.php?t=321696) | 提供更深的游戏函数回调 | 初版使用 SDKHooks、实体和事件即可编译，未增加该依赖 |
| Weapon Remove | [AlliedModders 讨论](https://forums.alliedmods.net/showthread.php?t=133726) | 搜索结果显示可限制拾取 | 论坛页面在本次检查中停在安全验证，未能核对源码和许可证，故未复用 |

本插件的 SourcePawn 代码由 night 编写；没有直接复制上表的插件函数。所依据的伤害识别证据来自本仓库内上述公开源码。新插件按本仓库 GPL-3.0 许可证发布，可在遵守 GPL-3.0 条款时修改和重新分发。DV 模式的 Confogl 配置从 ZoneMod 配置改编，保留原配置的 Sir 署名及 CC-BY-SA 3.0 声明；修改与重新分发须遵守该声明的署名和相同方式共享要求。ReadyUp 仅去除了模式名 ConVar 的 `FCVAR_PRINTABLEONLY` 标记并重新编译，在原作者 CanadaRox、Target 后追加了 night。Left 4 DHooks 本身没有被新插件引用。

## 实现方式

- 生还者：拾取与装备时拦截非 P220 武器；出生、规则变化后及每秒检查背包，移除主武器、非 P220 副武器和投掷物，缺少 P220 时补发一把。即使别的插件短暂给了主武器，该武器对玩家特感和 Tank 的伤害也会被拦截。默认不允许双持。药包、除颤器、止痛药、肾上腺素仍可使用。
- 感染者：只在受害者为生还者时检查 `SDKHook_OnTakeDamage`。优先检查 `inflictor` 实体 classname，再结合 `weapon`、伤害类型、控制状态 netprop 和技能事件。无法确认来源时保持游戏原伤害，并可打开日志供复核。友伤、世界伤害不按感染者技能处理。
- Smoker：`DMG_CHOKE` 与 `m_tongueOwner`；Spitter：`insect_swarm` 和酸液伤害标记；Jockey：`m_jockeyAttacker`；Hunter：`m_pounceAttacker`、`m_isAttemptingToPounce` 和 `lunge_pounce`；Charger：`m_carryAttacker`、`m_pummelAttacker`、`charger_impact` 等；Tank：`weapon_tank_claw` 与 `tank_rock`。普通 claw 优先检查 claw 实体，不能只看攻击者类别或当前持有武器。
- Tank 物件：追踪被 Tank 拳击的 `prop_physics*` 和 `prop_car_alarm`。物件在 3 秒内命中生还者时按 `dv_tank_hittable_damage` 处理；默认关闭。非此类实体、无法追踪来源的物件会保持原伤害。
- 禁伤时在伤害回调中将数值改为 0 并返回 `Plugin_Changed`，不阻止技能命中事件或攻击动作。**Tank 拳头击退是否在 0 伤害时仍完整保留，以及 Hunter/Charger 首次命中的精确时序，必须通过真实游戏验证。** 单靠 `OnTakeDamage` 的攻击者和伤害类型无法可靠区分全部子类型，因此首击与持续伤害还结合事件和配对计数；不同游戏版本或其他插件改变事件顺序时可能需要调整。

## 文件与部署

| 文件 | 用途 |
| --- | --- |
| `addons/sourcemod/scripting/dv_versus.sp` | 完整源码 |
| `addons/sourcemod/plugins/optional/dv_versus.smx` | 已编译插件 |
| `addons/sourcemod/configs/matchmodes.txt` | `!match` 菜单中的 DV 条目 |
| `cfg/cfgogl/zonemod_dv/` | 与 `zonemod/` 相同的八文件 Confogl 结构，沿用 ZoneMod 的比赛及地图配置 |
| `cfg/cfgogl/zonemod_dv/zonemod.cfg` | ZoneMod 参数及 DV 功能开关 |
| `addons/sourcemod/plugins/optional/readyup.smx` | 修正 ReadyUp 模式名 ConVar 对中文字符的过滤 |

将上述运行文件按原目录层级覆盖到服务器 `left4dead2/`：整个 `cfg/cfgogl/zonemod_dv/` 文件夹、`matchmodes.txt`、`dv_versus.smx` 和 `readyup.smx`，共 11 个文件。覆盖 ReadyUp 后完整重启服务器，使新编译插件重新创建 `l4d_ready_cfg_name`。目标环境为本整合包所用的 SourceMod 1.12、MetaMod 和 L4D2；DV 插件只需要 SourceMod 标准的 `sourcemod`、`sdktools`、`sdkhooks` include 和对应运行组件。整个 Confogl 模式仍依赖本整合包已有的插件。无需为 DV 插件另外安装 Left 4 DHooks。

模式规则必须写在 `cfg/cfgogl/zonemod_dv/zonemod.cfg` 中调用 `shared_settings.cfg` **之前**。后者末尾执行 `confogl_setcvars`；如果把 DV ConVar 写在它之后，Confogl 会忽略这些规则，`dv_enable` 将保持 0。

在本仓库根目录的 `addons/sourcemod/scripting/` 执行以下命令可重新编译：

```powershell
& '.\sourcemod\spcomp64.exe' '-iinclude' '-o..\plugins\optional\dv_versus.smx' 'dv_versus.sp'
```

服务器重启后，玩家使用 `!match` 选择 **ZoneMod 残疾人对抗**。管理员也可执行 `sm_forcematch zonemod_dv`。通过 `sm_resetmatch` 退出比赛模式，或使用 `sm_forcechangematch zonemod` 恢复普通 ZoneMod。Confogl 卸载配置会重置 DV ConVar；也可在控制台手动执行 `dv_enable 0`。切换成功后在服务器控制台核对 `sm plugins list` 中的 `dv_versus.smx`、`sm_cvar dv_enable` 应为 1、`sm_cvar l4d_ready_cfg_name` 应为完整中文模式名。

推荐配置已经写在 `cfg/cfgogl/zonemod_dv/zonemod.cfg`。各 `dv_*_damage`：`0` 为阻止扣血，`1` 为保留原伤害；`dv_survivor_pistol_only 1` 限制武器，`dv_dual_pistol 0` 禁止双持。修改此文件后重新切换模式使 Confogl 应用配置。调试时临时设 `dv_debug_damage 1`，SourceMod 日志会记录 attacker、inflictor、weapon、伤害类型和分类名称。

## 服务器测试清单

每项建议让两名玩家在本地测试服对抗模式实测，记录血量变化、动画、控制状态和 `dv_debug_damage 1` 的日志。源码编译成功并不等于游戏机制已验证。

- [ ] 生还者出生持有单把 P220，能够正常射击；第二把 P220 被拒绝，`dv_dual_pistol 1` 时允许双持。
- [ ] 主武器、马格南、近战和投掷物无法长期持有；地图拾取、脚本强制给予、倒地和被救起后均检查；短暂持枪时不能用它伤害玩家特感或 Tank；药品仍可使用。
- [ ] Smoker 舌头正常抓人，拖拽与勒住均不扣血，右键 claw 扣血。
- [ ] Boomer 正常呕吐与爆炸，爆炸直接伤害若存在为 0，右键 claw 扣血。
- [ ] Hunter 正常扑倒，首次扑击与后续压制伤害为 0，未扑人时 claw 扣血；检查事件时序分类。
- [ ] Spitter 酸液不扣血，右键 claw 扣血；检查特殊地图上的酸液来源。
- [ ] Jockey 正常骑乘，骑乘持续伤害为 0，未骑人时 claw 扣血。
- [ ] Charger 正常冲锋抓人，冲撞、撞墙和持续砸地均不扣血，未抓人时 claw 扣血；检查首次伤害是 impact 还是 slam。
- [ ] Tank 拳头动画正常、命中不扣血，核对击退与起身动作；石头正常扣血。
- [ ] Tank 打车、垃圾箱等物件时分别测试 `dv_tank_hittable_damage 0` 和 `1`；核对追踪不到的物件是否出现在 debug 日志。
- [ ] 世界坠落伤害、友伤、感染者普通 claw、倒地状态、死亡、换队、重生、上下半场切换、终局结束与切回 ZoneMod 均正常。

若日志中的应禁伤条目显示 `source=unknown`，不要靠猜测扩大拦截范围；请保存该次完整日志中的实体 classname、伤害类型、事件和双方状态，再针对服务器实际版本修正分类。
