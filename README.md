<div align="center">
  <img src="icon.svg" width="96" height="96" alt="NewFolderWithSelection icon"/>
  <h1>NewFolderWithSelection</h1>
  <p>Windows에서 macOS처럼 — 파일 여러 개 선택 후 우클릭 한 번으로 새 폴더에 정리</p>

  ![Windows](https://img.shields.io/badge/Windows-11%20%2F%2010-0078D4?logo=windows)
  ![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell)
  ![License](https://img.shields.io/badge/License-MIT-green)
</div>

---

## ✨ 기능

- 파일/폴더를 **여러 개 선택 → 우클릭 → 선택한 항목으로 새 폴더 만들기**
- macOS처럼 **공통 접두어로 폴더 이름 자동 제안**
- 이름 충돌 시 자동으로 `폴더명 2`, `폴더명 3` 처리
- 탐색기, 바탕화면 **어디서든** 동작
- 관리자 권한 불필요 (현재 사용자 전용 설치)
- 우클릭 시 **Windows 11 클래식 메뉴**로 바로 표시

## 📦 설치

1. 이 레포를 [다운로드](../../archive/refs/heads/main.zip) 하거나 클론
2. `install.ps1` 우클릭 → **PowerShell로 실행**
3. 완료!

> **처음 실행 시** "Windows의 PC 보호" 경고가 뜰 수 있습니다.
> **추가 정보** 클릭 → **실행** 클릭하면 됩니다.

## 🖱️ 사용법

1. 탐색기 또는 바탕화면에서 파일/폴더를 **여러 개 선택**
2. **우클릭**
3. **선택한 항목으로 새 폴더 만들기** 클릭
4. 자동 제안된 폴더 이름 확인 후 **확인**

## 🗑️ 제거

`uninstall.ps1` 우클릭 → **PowerShell로 실행**
우클릭 메뉴와 클래식 메뉴 설정이 원래대로 복원됩니다.

## 📁 파일 구성

| 파일 | 설명 |
|------|------|
| `install.ps1` | 설치 프로그램 |
| `uninstall.ps1` | 제거 프로그램 |

## 📋 시스템 요구사항

- Windows 10 / 11
- PowerShell 5.1 이상 (기본 내장)

## 📄 라이선스

MIT License
