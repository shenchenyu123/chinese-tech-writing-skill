# chinese-tech-writing

面向 [DeepSeek Harness](https://github.com/deepseek-ai)（DSH）的中文技术文档写作技能：工作流、规范详版、正反例、交付清单，以及一个可执行的机械检查脚本。

底本为阮一峰《中文技术文档的写作规范》（公共领域），按 skill 的加载方式重排，并补充了报告、教程、API 文档等场景的实践。

## 特性

- `SKILL.md` 保持短小，细则放在 `references/`，按需读取，不占满上下文。
- 约 30 组正反例，覆盖中英文混排、长句、语态、数值、标点、结构和文件名。
- `check-style.ps1` 检查可机器判定的项目：中英文间距、全角数字、中文里的半角标点、重复标点、非标准省略号、标题跳级等。
- 一条命令装进 DSH，并写入全局默认规则，之后写中文文档自动遵守。

## 安装

要求：Windows 10/11、PowerShell 5.1 或更高、已安装 DSH。

```powershell
git clone https://github.com/<your-name>/chinese-tech-writing-skill.git
cd chinese-tech-writing-skill
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

安装脚本会：

1. 把 `chinese-tech-writing` 复制到 `%USERPROFILE%\.dsh\skills\chinese-tech-writing\`；
2. 把默认写作规则追加到 `%USERPROFILE%\.dsh\AGENTS.md`，用 `<!-- chinese-tech-writing:begin/end -->` 包住，不覆盖已有内容。

设置过 `DSH_HOME` 时优先使用它。装完新开一个会话，问「你现在默认遵守哪些写作规范？」，能答出技能名和 `AGENTS.md` 路径即成功。

### 参数

| 参数 | 作用 |
| --- | --- |
| `-Force` | 技能目录已存在时覆盖 |
| `-NoDefault` | 只装技能，不写 `AGENTS.md` |
| `-Uninstall` | 删除技能，并移除规则段 |
| `-DshHome <路径>` | 安装到指定的 DSH 目录 |

### 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## 使用

装上之后有三种用法：

- 斜杠命令：`/chinese-tech-writing`；
- 提示里点名：「用 `chinese-tech-writing` 技能整理这些资料写一份报告」；
- 自动匹配：任务与技能描述相符时自动加载。

如果安装了默认规则，中文文档任务会一并遵守，不需要每次提醒。

## 目录结构

```text
.
├─ install.ps1              Windows 安装脚本（复制技能、写 AGENTS.md）
├─ INSTALL.md               安装、验证、卸载、常见问题
├─ agents-snippet.md        手动安装时复制到 AGENTS.md 的规则片段
└─ chinese-tech-writing\
   ├─ SKILL.md              技能入口：工作流与硬规则
   ├─ references\
   │  ├─ style-guide.md     规范详版
   │  ├─ examples.md        正例与反例
   │  └─ checklist.md       交付检查清单
   ├─ scripts\
   │  └─ check-style.ps1    机械检查脚本
   ├─ LICENSE
   └─ ATTRIBUTION.md
```

## 检查脚本

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\chinese-tech-writing\scripts\check-style.ps1 -Path .\docs
```

输出每处问题的文件、行号、规则编号和修改提示。`-FailOnIssues` 可在存在错误时返回退出码 1，便于接入 CI。需要保留错误示例的段落，用 `<!-- style-check: off -->` 和 `<!-- style-check: on -->` 包起来。

## 来源与许可

- 规范来源：阮一峰《中文技术文档的写作规范》，<https://github.com/ruanyf/document-style-guide>，公共领域。
- 本项目的重写、编排与脚本同样以公共领域发布，见 [LICENSE](LICENSE) 与 [ATTRIBUTION.md](chinese-tech-writing/ATTRIBUTION.md)。
