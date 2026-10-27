#Requires -Version 5.1
<#
.SYNOPSIS
    安装 chinese-tech-writing 技能到 DeepSeek Harness。

.DESCRIPTION
    把技能复制到 <DSH 目录>\skills\chinese-tech-writing，
    并把默认写作规则写入 <DSH 目录>\AGENTS.md。
    可重复执行；-Uninstall 可完整卸载。

.PARAMETER DshHome
    DSH 配置目录。默认取环境变量 DSH_HOME，未设置时用 %USERPROFILE%\.dsh。

.PARAMETER Force
    覆盖已存在的同名技能目录。

.PARAMETER NoDefault
    只安装技能，不写 AGENTS.md。

.PARAMETER Uninstall
    删除技能目录，并从 AGENTS.md 移除规则段。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$DshHome,
    [switch]$Force,
    [switch]$NoDefault,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BeginMarker = '<!-- chinese-tech-writing:begin -->'
$EndMarker = '<!-- chinese-tech-writing:end -->'

$RuleBlock = @'
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
'@

function Resolve-DshHome {
    param([string]$Explicit)

    if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
        return [System.IO.Path]::GetFullPath($Explicit)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:DSH_HOME)) {
        return [System.IO.Path]::GetFullPath($env:DSH_HOME)
    }
    $profileDir = [Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrWhiteSpace($profileDir)) {
        $profileDir = $HOME
    }
    return (Join-Path $profileDir '.dsh')
}

function Remove-RuleBlocks {
    param([string]$Text)

    $pattern = [regex]::Escape($BeginMarker) + '(?s).*?' + [regex]::Escape($EndMarker)
    $result = $Text
    while ($result -match [regex]::Escape($BeginMarker)) {
        $next = [regex]::Replace($result, $pattern, '')
        if ($next -eq $result) {
            break
        }
        $result = $next
    }
    return $result
}

$dsh = Resolve-DshHome -Explicit $DshHome
$target = Join-Path $dsh 'skills\chinese-tech-writing'
$agentsFile = Join-Path $dsh 'AGENTS.md'

if ($Uninstall) {
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
        Write-Host "已删除技能目录：$target"
    }
    else {
        Write-Host "技能目录不存在，跳过：$target"
    }

    if (Test-Path -LiteralPath $agentsFile) {
        $text = Get-Content -LiteralPath $agentsFile -Raw -Encoding UTF8
        if ($text -and ($text -match [regex]::Escape($BeginMarker))) {
            $cleaned = (Remove-RuleBlocks -Text $text).Trim()
            if ([string]::IsNullOrWhiteSpace($cleaned)) {
                Remove-Item -LiteralPath $agentsFile -Force
                Write-Host "AGENTS.md 已空，已删除：$agentsFile"
            }
            else {
                Set-Content -LiteralPath $agentsFile -Value ($cleaned + "`r`n") -Encoding UTF8 -NoNewline
                Write-Host "已从 AGENTS.md 移除规则段：$agentsFile"
            }
        }
        else {
            Write-Host 'AGENTS.md 中没有本技能的规则段，跳过。'
        }
    }
    else {
        Write-Host 'AGENTS.md 不存在，跳过。'
    }

    Write-Host ''
    Write-Host '卸载完成。新开一个会话生效。'
    return
}

$source = Join-Path $PSScriptRoot 'chinese-tech-writing'
if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) {
    Write-Host "找不到技能目录：$source" -ForegroundColor Red
    Write-Host "请确认 zip 解压完整，install.ps1 和 chinese-tech-writing 文件夹在同一层。" -ForegroundColor Red
    exit 1
}

if ((Test-Path -LiteralPath $target) -and (-not $Force)) {
    Write-Host "技能目录已存在：$target" -ForegroundColor Yellow
    Write-Host "确认覆盖请加 -Force；想保留自己的修改时，先备份再装。" -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
Write-Host "已安装技能：$target"

if ($NoDefault) {
    Write-Host '已跳过 AGENTS.md（-NoDefault）。'
}
else {
    if (Test-Path -LiteralPath $agentsFile) {
        $text = Get-Content -LiteralPath $agentsFile -Raw -Encoding UTF8
        $baseText = ''
        if ($text) {
            $baseText = (Remove-RuleBlocks -Text $text).TrimEnd()
        }
    }
    else {
        $baseText = ''
    }

    if ([string]::IsNullOrWhiteSpace($baseText)) {
        $content = $RuleBlock + "`r`n"
    }
    else {
        $content = $baseText + "`r`n`r`n" + $RuleBlock + "`r`n"
    }

    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($agentsFile)) | Out-Null
    Set-Content -LiteralPath $agentsFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "已写入默认规则：$agentsFile"
}

Write-Host ''
Write-Host '安装完成。接下来这样验证：'
Write-Host '  1. 新开一个 DSH 会话；'
Write-Host '  2. 问：你现在默认遵守哪些写作规范？'
if ($NoDefault) {
    Write-Host '  3. 应能答出 chinese-tech-writing。这次没写 AGENTS.md，不会默认生效。'
}
else {
    Write-Host '  3. 应该能答出 chinese-tech-writing 和 AGENTS.md 的路径。'
}
Write-Host ''
Write-Host '卸载：powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall'
