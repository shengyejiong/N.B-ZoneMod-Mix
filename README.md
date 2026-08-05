# N&B服混野配置

本仓库是基于 [SirPlease/L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework) 和 ZoneMod 2.9.1b 整理的《求生之路 2》Linux 混野对抗服务器配置。

这是 N&B 服务器使用的非官方整合版本，不是 Valve、ZoneMod 或 L4D2 Competitive Rework 的官方发行版。上游工程、第三方插件和扩展的版权归各自作者所有；

主要的 N&B 自定义内容包括：

- 服务器常驻插件；
- 动态大厅、Tank Pass、旁观者特感轮廓、经验与队伍管理等混野功能；
- MapChanger 3.8 地图菜单、评分及终局自动换图；
- 对 ZoneMod 准备阶段、Bot 行为、大厅保留和部分比赛参数的调整。

> [!CAUTION]
>
> 仓库不包含的真实 `cfg/server1.cfg`、RCON 密码、搜索密钥或管理员列表。部署者必须在服务器上自行填写私密配置，不要将实际密码提交到 Git。

本仓库延续上游 GPL-3.0 许可证。第三方组件仍遵循其各自许可证和发布条件，补充说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。配置与插件是否成功加载仍应以 Linux 服务器上的 `sm plugins list`、控制台和 SourceMod 日志为准。

---

# **上游项目说明：L4D2 Competitive Rework**

> [!IMPORTANT]
>
> It is recommended to host servers on Linux, but Windows is supported.  
>
> When running Linux ensure that your setup is running a minimum of **`GLIBC 2.35`** (Ubuntu 22.04 or higher) or you will run into issues loading certain extensions.  
>
> This repository only supports Sourcemod **1.12** and up (which comes with the repository for ease of use)

---

> [!NOTE]
>
> ConVar **`mv_maxplayers`** was added which replaces **`sv_maxplayers`** in **`cfg/server.cfg`**, this is used to prevent it from being overwritten every map change.  
>
> On config unload, the value will be reset to the value used in the **`cfg/server.cfg`**.
>
> [!NOTE]
>
> Every confogl matchmode will now execute 2 additional files; **`cfg/sharedplugins.cfg`** and **`cfg/generalfixes.cfg`**.  
>
> **`generalfixes.cfg`** contains all the crucial fixes that will be loaded in every matchmode.  
>
> **`sharedplugins.cfg`** is for you, the server owner. You can load any custom plugin that you want to be loaded in every matchmode here.
>
> [!CAUTION]
>
> Plugin load locking and unlocking is no longer handled by the configs themselves, refrain from doing it manually or you can run into issues.

## **About:**

This project started off with a focus on reworking the very outdated platform for competitive L4D2.  

In its current state it allows anyone to host their own up to date competitive L4D2 servers.

> **Included Matchmodes:**

- **Zonemod 2.9.1b**
- **Zonemod Hunters**
- **Zonemod Retro**
- **NeoMod 0.4a**
- **NextMod 1.0.5**
- **Promod Elite 1.1**
- **Acemod Revamped 1.2**
- **Equilibrium 3.0c**
- **Apex 1.1.2**

---

## **Download & Installation:**

> [!IMPORTANT]
>
> Pick the archive that matches your **Server OS**:
>
> - **Linux:** `L4D2-Competitive-Rework-<version>-linux.tar.gz`
> - **Windows:** `L4D2-Competitive-Rework-<version>-windows.zip`

1. Download the latest archive from the [**Releases**](../../releases/latest) page.
2. Extract it directly into your server's **`left4dead2/`** directory.
3. For first-time server setup on dedicated servers, the [Dedicated Server Install Guide](Dedicated%20Server%20Install%20Guide/README.md) might be of use to you!

> [!NOTE]
>
> Releases only include what the servers need, **no** SourcePawn sources or compiler.  
>
> To modify or recompile plugins, clone the repository instead.

---

## **Credits:**

> **Foundation/Advanced Work:**

- A1m`
- AlliedModders LLC.
- "Confogl Team"
- Dr!fter
- Forgetest
- Jahze
- Lux
- Prodigysim
- Silvers
- XutaxKamay
- Visor

> **Additional Plugins/Extensions:**

- Accelerator74
- Arti
- AtomicStryker
- Backwards
- BHaType
- Blade
- Buster
- Canadarox
- CircleSquared
- Darkid
- DarkNoghri
- Dcx
- Devilesk
- Die Teetasse
- Disawar1
- Don
- Dragokas
- Dr. Gregory House
- Epilimic
- Estoopi
- Griffin
- Harry Potter
- Jacob
- Luckylock
- Madcap
- Mr. Zero
- Nielsen
- Powerlord
- Rena
- Sheo
- Sir
- Spoon
- Stabby
- Step
- Tabun
- Target
- TheTrick
- V10
- Vintik
- VoiDeD
- xoxo
- $atanic $pirit

> **Competitive Mapping Rework:**

- Aiden
- Derpduck
- Mart

> [!NOTE]
>
> If your work is being used and I forgot to credit you, don't hesitate to contact me on Discord (user: `sirplease`)
