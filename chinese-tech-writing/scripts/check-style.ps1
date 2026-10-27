#Requires -Version 5.1
<#
.SYNOPSIS
    检查中文技术文档中的机械性写作问题。

.DESCRIPTION
    按《中文技术文档的写作规范》检查可机器判定的项目：中英文间距、全角数字、
    半角标点夹在中文里、重复标点、非标准省略号、全角标点旁的空白、标题跳级、
    标题末尾点号。代码块与行内代码会被跳过。

    需要保留“错误示例”的段落，可以用 <!-- style-check: off --> 和
    <!-- style-check: on --> 包起来，这一段不参与检查。

.PARAMETER Path
    要检查的文件或目录。目录会递归查找 .md、.markdown、.txt。

.PARAMETER FailOnIssues
    存在“必须修改”的问题时返回退出码 1，便于接入 CI 或提交前钩子。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\check-style.ps1 -Path ..\references

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\check-style.ps1 -Path .\docs -FailOnIssues
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path,

    [switch]$FailOnIssues
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Cjk = '[\u4e00-\u9fff]'

$rules = @(
    [pscustomobject]@{
        Id       = 'S01'
        Severity = 'error'
        Name     = '中英文之间缺少空格'
        Pattern  = "$Cjk[A-Za-z]|[A-Za-z]$Cjk"
        Hint     = '中文字符与英文字母之间加一个半角空格'
    }
    [pscustomobject]@{
        Id       = 'S02'
        Severity = 'info'
        Name     = '数字与汉字之间没有空格'
        Pattern  = "$Cjk[0-9]|[0-9]$Cjk"
        Hint     = '允许不加空格，但全文必须统一；不要两种风格混用'
    }
    [pscustomobject]@{
        Id       = 'S03'
        Severity = 'error'
        Name     = '全角数字、字母或百分号'
        Pattern  = '[０-９Ａ-Ｚａ-ｚ％]'
        Hint     = '数字、字母、百分号一律用半角'
    }
    [pscustomobject]@{
        Id       = 'S04'
        Severity = 'error'
        Name     = '中文语句里的半角标点'
        Pattern  = "$Cjk[,;:!?]|[,;:!?]$Cjk"
        Hint     = '中文语句用全角标点；整句英文才用半角标点'
    }
    [pscustomobject]@{
        Id       = 'S05'
        Severity = 'error'
        Name     = '重复标点'
        Pattern  = '[!！]{2,}|[?？]{2,}|[，,]{2,}|[、]{2,}|[；;]{2,}'
        Hint     = '去掉重复的标点，只保留一个'
    }
    [pscustomobject]@{
        Id       = 'S06'
        Severity = 'error'
        Name     = '非标准省略号'
        Pattern  = '。{3,}|\.{3,}|(?<!…)…(?!…)'
        Hint     = '中文省略号写 ⋯⋯（两个汉字宽、六个点），不用 。。。 或 ...'
    }
    [pscustomobject]@{
        Id       = 'S07'
        Severity = 'warn'
        Name     = '全角标点旁有空格'
        Pattern  = '[，。；：、！？][ \t]+|[ \t]+[，。；：、！？]'
        Hint     = '删除全角标点前后的空格；Markdown 语法需要的空格除外'
    }
    [pscustomobject]@{
        Id       = 'S08'
        Severity = 'error'
        Name     = '标题跳级'
        Pattern  = ''
        Hint     = '标题逐级下降：一级到二级到三级到四级，不跳级'
    }
    [pscustomobject]@{
        Id       = 'S09'
        Severity = 'error'
        Name     = '标题末尾有点号'
        Pattern  = ''
        Hint     = '标题末尾不加句号、逗号、分号、冒号'
    }
)

function Get-TargetFiles {
    param([string]$Root)

    $item = Get-Item -LiteralPath $Root -ErrorAction Stop
    if ($item.PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction Stop |
            Where-Object { $_.Extension -in @('.md', '.markdown', '.txt') })
    }
    else {
        $files = @($item)
    }
    return @($files | Sort-Object FullName)
}

function Get-Snippet {
    param([string]$Text, [int]$Index, [int]$Length)

    $start = [Math]::Max(0, $Index - 12)
    $end = [Math]::Min($Text.Length, $Index + $Length + 12)
    $snippet = $Text.Substring($start, $end - $start)
    $snippet = ($snippet -replace '\s+', ' ').Trim()
    if ($snippet.Length -gt 90) {
        $snippet = $snippet.Substring(0, 87) + '...'
    }
    return $snippet
}

$files = @(Get-TargetFiles -Root $Path)
if ($files.Count -eq 0) {
    Write-Host '没有可检查的文件（只支持 .md、.markdown、.txt）。'
    exit 0
}

$findings = New-Object System.Collections.Generic.List[object]
$checked = 0

foreach ($file in $files) {
    $checked++
    $lines = @(Get-Content -LiteralPath $file.FullName -Encoding UTF8)
    if (($lines -join '') -match "$([char]0xFFFD)") {
        # 文件不是 UTF-8（例如 GBK），按系统默认编码重读。
        $lines = @(Get-Content -LiteralPath $file.FullName -Encoding Default)
    }
    $inFence = $false
    $skip = $false
    $previousLevel = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $raw = $lines[$i]
        $lineNumber = $i + 1

        if ($raw -match '^\s*(?:```|~~~)') {
            $inFence = -not $inFence
            continue
        }
        if ($inFence) {
            continue
        }

        if ($raw -match '<!--\s*style-check:\s*off\s*-->') {
            $skip = $true
            continue
        }
        if ($raw -match '<!--\s*style-check:\s*on\s*-->') {
            $skip = $false
            continue
        }
        if ($skip) {
            continue
        }

        # 行内代码用等长的方框占位，避免代码里的标点和字母干扰检查。
        $text = [regex]::Replace($raw, '`[^`]*`', { param($m) '□' * $m.Value.Length })

        $heading = [regex]::Match($text, '^\s{0,3}(#{1,6})\s+(.+?)\s*$')
        if ($heading.Success) {
            $level = $heading.Groups[1].Value.Length
            $title = $heading.Groups[2].Value.Trim()

            if ($previousLevel -gt 0 -and $level -gt $previousLevel + 1) {
                $findings.Add([pscustomobject]@{
                    File     = $file.FullName
                    Line     = $lineNumber
                    Rule     = 'S08'
                    Severity = 'error'
                    Name     = '标题跳级'
                    Snippet  = $raw.Trim()
                    Hint     = '标题逐级下降，不跳级'
                })
            }
            $previousLevel = $level

            if ($title -match '[，。；：、,.;:]$') {
                $findings.Add([pscustomobject]@{
                    File     = $file.FullName
                    Line     = $lineNumber
                    Rule     = 'S09'
                    Severity = 'error'
                    Name     = '标题末尾有点号'
                    Snippet  = $raw.Trim()
                    Hint     = '标题末尾不加句号、逗号、分号、冒号'
                })
            }
        }

        foreach ($rule in $rules) {
            if ($rule.Pattern -eq '') { continue }
            $ruleMatches = [regex]::Matches($text, $rule.Pattern)
            foreach ($match in $ruleMatches) {
                $findings.Add([pscustomobject]@{
                    File     = $file.FullName
                    Line     = $lineNumber
                    Rule     = $rule.Id
                    Severity = $rule.Severity
                    Name     = $rule.Name
                    Snippet  = Get-Snippet -Text $text -Index $match.Index -Length $match.Length
                    Hint     = $rule.Hint
                })
            }
        }
    }
}

# 同一行同类问题只报一次，避免一行里十个告警。
$seen = @{}
$unique = New-Object System.Collections.Generic.List[object]
foreach ($finding in $findings) {
    $key = "$($finding.File)|$($finding.Line)|$($finding.Rule)"
    if ($seen.ContainsKey($key)) {
        $seen[$key] = $seen[$key] + 1
    }
    else {
        $seen[$key] = 1
        $unique.Add($finding)
    }
}
foreach ($finding in $unique) {
    $key = "$($finding.File)|$($finding.Line)|$($finding.Rule)"
    $count = $seen[$key]
    if ($count -gt 1) {
        $finding.Hint = "$($finding.Hint)（本行同类问题共 $count 处）"
    }
}
$findings = $unique

$errorCount = @($findings | Where-Object { $_.Severity -eq 'error' }).Count
$warnCount = @($findings | Where-Object { $_.Severity -eq 'warn' }).Count
$infoCount = @($findings | Where-Object { $_.Severity -eq 'info' }).Count

foreach ($group in ($findings | Group-Object File)) {
    Write-Host ''
    Write-Host $group.Name
    foreach ($finding in $group.Group) {
        if ($finding.Severity -eq 'error') { $mark = '[!]' }
        elseif ($finding.Severity -eq 'warn') { $mark = '[~]' }
        else { $mark = '[i]' }
        Write-Host ("  {0} 第 {1} 行 [{2}] {3}" -f $mark, $finding.Line, $finding.Rule, $finding.Name)
        Write-Host ("      {0}" -f $finding.Snippet)
        Write-Host ("      => {0}" -f $finding.Hint)
    }
}

Write-Host ''
Write-Host ("检查 {0} 个文件：{1} 处必须修改，{2} 处需确认，{3} 处提示。" -f $checked, $errorCount, $warnCount, $infoCount)

if ($errorCount -gt 0 -and $FailOnIssues) {
    exit 1
}
exit 0
