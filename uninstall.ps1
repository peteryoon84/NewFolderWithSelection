#Requires -Version 5.1
<#
.SYNOPSIS
    선택한 항목으로 새 폴더 만들기 - 제거 프로그램
#>

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms

# ── 1. 컨텍스트 메뉴 레지스트리 제거 ────────────────────────────────
foreach ($root in @(
    'HKCU:\SOFTWARE\Classes\*\shell\NewFolderWithSelection',
    'HKCU:\SOFTWARE\Classes\Directory\shell\NewFolderWithSelection'
)) {
    Remove-Item -Path $root -Recurse -Force
}

# ── 2. 클래식 컨텍스트 메뉴 설정 제거 (Windows 11 기본값 복원) ───────
Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force

# ── 3. 스크립트 파일 제거 ────────────────────────────────────────────
$installDir = Join-Path $env:LOCALAPPDATA 'NewFolderWithSelection'
Remove-Item -Path $installDir -Recurse -Force

# ── 4. 탐색기 재시작 ────────────────────────────────────────────────
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

# ── 5. 완료 메시지 ──────────────────────────────────────────────────
[System.Windows.Forms.MessageBox]::Show(
    '제거 완료!`n`n우클릭 메뉴와 클래식 메뉴 설정이 원래대로 복원됐습니다.',
    '제거 완료',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
