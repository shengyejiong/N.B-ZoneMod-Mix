# 第三方组件说明

本仓库基于 `SirPlease/L4D2-Competitive-Rework`，并加入了若干 SourceMod 插件、扩展、翻译和配置。此文件用于说明来源关系

## 基础工程

- 项目：L4D2 Competitive Rework / ZoneMod
- 上游：https://github.com/SirPlease/L4D2-Competitive-Rework
- 许可证：GPL-3.0
- 说明：N&B 仅维护本 Fork 中的配置和整合修改；上游作者与贡献者名单保留在原 README 和源码中。

## MapChanger

- 名称：MapChanger 3.8
- 作者：Alex Dragokas
- 作者主页：https://github.com/dragokas/
- 本仓库保留了随插件包提供的 `.sp` 源码、编译后的 `.smx`、翻译、数据文件和配置。

## 其他新增插件

带有 `.sp` 源码的插件，其作者、项目地址和版本信息以相应源码中的 `Plugin myinfo`、版权头及原始发布信息为准。本仓库只进行服务器配置整合。

以下插件目前按服务器维护者确认一并保存，但本地整合包内没有找到同名 `.sp` 源码：

- `all4dead2.smx`
- `exp_interface.smx`
- `l4d2_survivorai_trigger_v3.0.smx`
- `l4d_tank_pass.smx`
- `nativevotes_rework.smx`
- `show_exp.smx`

以下第三方二进制扩展也随部署包保存：

- `SteamWorks.ext.dll`
- `SteamWorks.ext.so`
- `custom_fakelag.ext.2.l4d2.so`

如后续确认到上述二进制对应的准确源码仓库、版本和许可证，应在此文件补充链接，并优先提供与二进制一致的源码。若权利人认为署名或来源有遗漏，可通过仓库 Issue 联系维护者进行更正或移除。
