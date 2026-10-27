<!-- chinese-tech-writing:begin -->
## 中文写作默认遵守技术文档规范

写、改、审中文技术文档（README、API 文档、设计文档、教程、发布说明）或中文报告时，语言与格式默认遵守 `chinese-tech-writing` 技能，不需要用户再次提醒。

1. 动笔前先加载技能：调用 skill 工具，name 为 `chinese-tech-writing`。
2. 按技能里的工作流执行；需要细则时读 `references/style-guide.md`，交付前按 `references/checklist.md` 自检。
3. 报告、方案、总结类文档：章节结构按该文体的惯例，语言与格式仍按技能规范。
4. 交付前运行 `scripts/check-style.ps1`（Windows 下用 `powershell -NoProfile -ExecutionPolicy Bypass -File` 调用），把告警数量和修改项写进交付说明。
5. 规范与用户的明确要求冲突时，以用户要求为准，并在交付时说明原因。

不要在每次回复里复述规范条款，直接按其写作；用户没有要求时，也不要主动解释你加载了什么技能。
<!-- chinese-tech-writing:end -->
