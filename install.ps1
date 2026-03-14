#Requires -Version 5.1
<#
.SYNOPSIS
    선택한 항목으로 새 폴더 만들기 - 설치 프로그램
    macOS처럼 파일/폴더 여러 개 선택 후 우클릭으로 새 폴더에 정리
    ※ 관리자 권한 불필요 (현재 사용자 전용 설치)
#>

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

# ── 1. run.ps1 파일 설치 ─────────────────────────────────────────────
$installDir = Join-Path $env:LOCALAPPDATA 'NewFolderWithSelection'
$scriptPath = Join-Path $installDir 'run.ps1'

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

$runScript = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# '--' 구분자 제거, 실제 파일 경로만 수집
$files = @($args) | Where-Object { $_ -ne '--' -and (Test-Path $_) }
if ($files.Count -eq 0) { exit }

# 모든 파일이 같은 폴더에 있는지 확인
$parentDirs = $files | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique
if ($parentDirs.Count -gt 1) {
    [System.Windows.Forms.MessageBox]::Show(
        '서로 다른 폴더의 항목은 함께 묶을 수 없습니다.',
        '선택한 항목으로 새 폴더 만들기',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}
$parentDir = $parentDirs[0]

# macOS 스타일 폴더 이름 제안
function Get-SuggestedName {
    param($paths)
    $names = $paths | ForEach-Object {
        $base = Split-Path $_ -Leaf
        $ext  = [System.IO.Path]::GetExtension($base)
        if ($ext) { $base.Substring(0, $base.Length - $ext.Length) } else { $base }
    }
    if ($names.Count -eq 1) { return $names[0] }
    $prefix = $names[0]
    foreach ($name in $names[1..($names.Count - 1)]) {
        while ($prefix.Length -gt 0 -and -not $name.StartsWith($prefix)) {
            $prefix = $prefix.Substring(0, $prefix.Length - 1)
        }
        if ($prefix.Length -eq 0) { break }
    }
    $cleaned = ($prefix -replace '[ _.0-9-]+$', '').Trim()
    if ($cleaned.Length -ge 3) { return $cleaned }
    return $names[0]
}

# 이름 충돌 시 macOS처럼 " 2", " 3" 붙이기
function Get-AvailablePath {
    param($parent, $name)
    $p = Join-Path $parent $name
    if (-not (Test-Path $p)) { return $p }
    $i = 2
    while ($true) {
        $p = Join-Path $parent "$name $i"
        if (-not (Test-Path $p)) { return $p }
        $i++
    }
}

$suggested = Get-SuggestedName $files

# 입력 다이얼로그
$form = New-Object System.Windows.Forms.Form
$form.Text            = '선택한 항목으로 새 폴더 만들기'
$form.Size            = New-Object System.Drawing.Size(420, 155)
$form.StartPosition   = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.TopMost         = $true

$label = New-Object System.Windows.Forms.Label
$label.Text     = "$($files.Count)개 항목을 새 폴더로 이동합니다:"
$label.Location = New-Object System.Drawing.Point(14, 14)
$label.Size     = New-Object System.Drawing.Size(385, 18)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(14, 38)
$textBox.Size     = New-Object System.Drawing.Size(383, 22)
$textBox.Text     = $suggested
$form.Controls.Add($textBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text         = '확인'
$okButton.Location     = New-Object System.Drawing.Point(222, 78)
$okButton.Size         = New-Object System.Drawing.Size(82, 28)
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton     = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text         = '취소'
$cancelButton.Location     = New-Object System.Drawing.Point(314, 78)
$cancelButton.Size         = New-Object System.Drawing.Size(82, 28)
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton         = $cancelButton
$form.Controls.Add($cancelButton)

$form.Add_Shown({ $textBox.SelectAll(); $textBox.Focus() })
$result = $form.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) { exit }
$folderName = $textBox.Text.Trim()
if (-not $folderName) { exit }

# 금지 문자 체크
$invalid = [System.IO.Path]::GetInvalidFileNameChars()
if (($folderName.ToCharArray() | Where-Object { $invalid -contains $_ }).Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show(
        '폴더 이름에 사용할 수 없는 문자가 포함되어 있습니다.',
        '오류',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}

$newFolderPath = Get-AvailablePath $parentDir $folderName

try {
    New-Item -ItemType Directory -Path $newFolderPath -ErrorAction Stop | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "폴더 생성 실패:`n$_",
        '오류',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}

$errors = @()
foreach ($file in $files) {
    try {
        Move-Item -Path $file -Destination (Join-Path $newFolderPath (Split-Path $file -Leaf)) -ErrorAction Stop
    } catch {
        $errors += (Split-Path $file -Leaf)
    }
}

if ($errors.Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "다음 항목을 이동하지 못했습니다:`n" + ($errors -join "`n"),
        '일부 항목 이동 실패',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}
'@

[System.IO.File]::WriteAllText($scriptPath, $runScript, [System.Text.Encoding]::UTF8)

# ── 2. 컨텍스트 메뉴 레지스트리 등록 ────────────────────────────────
$cmd        = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -- %*"
$menuTitle  = '선택한 항목으로 새 폴더 만들기'

foreach ($root in @(
    'HKCU:\SOFTWARE\Classes\*\shell\NewFolderWithSelection',
    'HKCU:\SOFTWARE\Classes\Directory\shell\NewFolderWithSelection'
)) {
    New-Item -Path $root -Force | Out-Null
    Set-ItemProperty -Path $root -Name '(default)'        -Value $menuTitle
    Set-ItemProperty -Path $root -Name 'MultiSelectModel' -Value 'Player'
    Set-ItemProperty -Path $root -Name 'Icon'             -Value 'shell32.dll,4'
    New-Item -Path "$root\command" -Force | Out-Null
    Set-ItemProperty -Path "$root\command" -Name '(default)' -Value $cmd
}

# ── 3. Windows 11 클래식 컨텍스트 메뉴 활성화 ───────────────────────
$clsid = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
New-Item -Path $clsid -Force | Out-Null
Set-ItemProperty -Path $clsid -Name '(default)' -Value '' -Type String
New-Item -Path "$clsid\InprocServer32" -Force | Out-Null
Set-ItemProperty -Path "$clsid\InprocServer32" -Name '(default)' -Value '' -Type String

# ── 4. 탐색기 재시작 ────────────────────────────────────────────────
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

# ── 5. 완료 메시지 ──────────────────────────────────────────────────
[System.Windows.Forms.MessageBox]::Show(
    "설치 완료!`n`n파일/폴더를 여러 개 선택 후 우클릭하면`n'선택한 항목으로 새 폴더 만들기'가 나타납니다.",
    '설치 완료',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
