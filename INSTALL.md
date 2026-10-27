# chinese-tech-writing 技能安装说明

中文技术文档写作技能。安装后有两件事生效：

- 技能进入 DSH：可以用 `/chinese-tech-writing` 调用，也会在相关任务里自动匹配。
- 全局规则写进 `AGENTS.md`：之后写中文文档默认遵守，不用每次提醒。

## 系统要求

- Windows 10 或 Windows 11
- 已安装 DeepSeek Harness
- 系统自带的 PowerShell 5.1 即可

## 三步安装

1. 解压 zip。确认 `install.ps1`、`agents-snippet.md` 和 `chinese-tech-writing` 文件夹在同一层。
2. 在解压目录的地址栏输入 `powershell` 并回车，然后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

3. 看到“安装完成”后，新开一个 DSH 会话，输入：`你现在默认遵守哪些写作规范？`
   能答出 `chinese-tech-writing` 和 `AGENTS.md` 的路径，就算装好了。

## 安装做了什么

| 动作 | 位置 |
| --- | --- |
| 复制技能 | `%USERPROFILE%\.dsh\skills\chinese-tech-writing\` |
| 写入规则 | `%USERPROFILE%\.dsh\AGENTS.md`，用 `<!-- chinese-tech-writing:begin -->` 和 `<!-- chinese-tech-writing:end -->` 包住 |

设置了环境变量 `DSH_HOME` 时，会优先使用 `%DSH_HOME%`，不再用 `%USERPROFILE%\.dsh`。

规则段是追加的，不会动 `AGENTS.md` 里已有的内容；重复安装只会替换这一段，不会重复追加。

## 参数

| 参数 | 作用 |
| --- | --- |
| `-Force` | 技能目录已存在时覆盖安装 |
| `-NoDefault` | 只装技能，不写 `AGENTS.md` |
| `-Uninstall` | 删除技能，并从 `AGENTS.md` 移除规则段 |
| `-DshHome <路径>` | 安装到指定的 DSH 目录，用于测试或多套环境 |

## 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

只删本技能加入的内容；`AGENTS.md` 如果还有其他内容会保留，删空了才删除文件。

## 手动安装

不想跑脚本时：

1. 把 `chinese-tech-writing` 整个文件夹复制到 `%USERPROFILE%\.dsh\skills\`。
   正确层级是 `skills\chinese-tech-writing\SKILL.md`，不要多套一层。
2. 把 `agents-snippet.md` 的内容追加到 `%USERPROFILE%\.dsh\AGENTS.md`，没有这个文件就新建。

## 常见问题

**提示“无法加载文件，未对文件进行数字签名”**
执行策略拦截了脚本。用上面那条完整命令，`-ExecutionPolicy Bypass` 不能省。

**新会话里没有这个技能**
检查目录层级，`skills` 只扫描一层；再确认文件名是 `SKILL.md`，不是 `skill.md`。改完新开会话。

**`AGENTS.md` 里本来就有内容**
脚本会保留原内容，只在后面追加规则段。手动安装时注意不要覆盖原文件。

**提示“技能目录已存在”**
说明之前装过。加 `-Force` 覆盖；如果你改过里面的文件，先备份。

**想只对某个项目生效**
把技能放到 `<项目根>\.dsh\skills\chinese-tech-writing\`，规则写进 `<项目根>\AGENTS.md`，再删掉用户级的那一份。

**检查脚本运行报错**
用 `powershell -NoProfile -ExecutionPolicy Bypass -File` 调用，不要直接双击 `.ps1`。脚本支持 UTF-8 和 GBK 编码的 Markdown。
