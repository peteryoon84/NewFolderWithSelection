# CLAUDE.md — 프로젝트 메모리 / 작업 인수인계

> 이 파일은 Claude Code가 **새 세션마다 자동으로 읽습니다.**
> 새 세션의 Claude는 이전 대화를 기억하지 못하므로, 여기에 맥락·결정사항·할 일을 기록합니다.
> 작업하면서 중요한 변경/결정이 생기면 이 파일을 계속 업데이트하세요.

---

## 1. 프로젝트 개요

- **무엇:** 부부(남편·아내)의 **나트랑(Nha Trang) 여행 일정 PWA** — 단일 파일 `index.html`
- **저장소:** `peteryoon84/NewFolderWithSelection`
- **배포 주소:** https://peteryoon84.github.io/NewFolderWithSelection/ (GitHub Pages, **main 브랜치** 서빙)
- **사용자:** 윤정호(peteryoon84), 한국어로 대화. 호칭 "사이로 작가". 부부가 같이 보고 편집.
- **앱 비밀번호 게이트:** `0629` (캐주얼 프라이버시용 — view-source로 우회 가능, 보안용 아님)

## 2. 여행 기본 정보 (확정 — Agoda 예약 PDF 기준)

| 항목 | 내용 |
|---|---|
| 출발 항공 | **VJ919** 부산(PUS) 10:55 → 나트랑(CXR) 13:35 · 비엣젯 · 탑승객 2명 |
| 귀국 항공 | **LJ116** 나트랑(CXR) 23:55 → 부산(PUS) 익일 **06:40 도착 (7/4 토)** |
| 호텔 1 | **인터컨티넨탈 나트랑** 6/29~7/1 |
| 호텔 2 | **아미아나 리조트(Amiana)** 7/1~7/3 |
| 출발지 | 대구 화암로 120 (06:20 출발) → 강서주차장 발렛(사설 장기주차) → 김해공항 |
| 앱 제목 | "나트랑 4박6일 · 일정 & 체크리스트" |

> DAY 1 일정은 13:35 도착 기준으로 현실적 체류시간(dwell) 반영해 재설계 완료.
> 카페·식당·쇼핑 각 60분, 공항픽업 45분, 나머지는 활동별 차등.

## 3. 배포 워크플로 (중요!)

- **개발 브랜치:** `claude/github-repo-setup-irkhmr`
- **GitHub Pages는 `main`을 서빙** → 변경이 사용자 화면에 반영되려면 **main에 머지 필수**
- 절차: 브랜치에 커밋·푸시 → PR 생성 → **squash 머지 to main** → Pages 1~2분 후 반영
- 머지 후 다음 작업 충돌 방지를 위해 브랜치를 main에 맞춰 reset:
  ```bash
  git fetch origin main && git reset --hard origin/main && git push -f origin claude/github-repo-setup-irkhmr
  ```
- ⚠️ squash 머지라 브랜치 히스토리가 main과 갈라져 머지 충돌이 자주 남 → 위 reset 습관화

### 서비스워커 캐시 주의
- `sw.js`에 `const V = 'vN'` 버전. **HTML/JS 변경 시 V를 올려야** 사용자에게 새 버전이 전달됨 (현재 v4)
- `index.html`은 **network-first**로 서빙(수정), 그 외는 cache-first
- 사용자가 옛 버전 보이면: 브라우저 사이트 데이터 삭제 + 강력 새로고침(Cmd+Shift+R), PWA는 앱 재시작 / Service Worker Unregister

## 4. 앱 주요 기능 (모두 `index.html` 안)

- **3탭:** 일정 / 투두 / 체크리스트
- **지도:** Leaflet + Carto 타일, 마커, 경로(renderRoute), 타일 오프라인 캐시 가능
- **일정 데이터:** `DATA`(원본) → `LIVE_DATA`(편집본) → localStorage `nt_itin` → Firebase
- **편집 모드:** 슬롯 추가/수정/삭제, **드래그 순서변경**(SortableJS, 터치 롱프레스 300ms)
- **위치 검색:** Nominatim(`countrycodes=vn`, 한글 지원) → Google Maps iframe 미리보기 → 2단계 확정
- **자동 도착시간 배분:** `autoSchedule(di)` — OSRM 경로 API, 실패 시 haversine/25km·h 폴백, dwell 합산
- **길찾기:** 선택모드로 2곳+ 선택 → 플로팅 `#navFloat`(**진짜 `<a>` 링크**, 팝업차단 우회) → Google Maps 경로
- **내보내기:** `📤 내보내기` 버튼 → `LIVE_DATA`를 JSON 모달로 표시 + 클립보드 복사 (앱 수정분을 원본에 반영하는 수단)
- **초기화:** 전체 리셋 / `resetDay(di)` 날짜별 리셋

## 5. Firebase 실시간 동기화

- 부부가 같은 일정을 실시간 공유 (last-write-wins, 기기 echo 방지)
- `Sync` 모듈: `firebase/database` ref `trip/v1`, `{data, ts, by}` 구조
- **DB URL:** `https://nha-trang-a9fc6-default-rtdb.asia-southeast1.firebasedatabase.app`
- 테스트 모드(공개 읽기/쓰기) — 약 **2026-07-22 만료** 예정. 만료 전 규칙 갱신 필요할 수 있음.
- 리전: 싱가포르(asia-southeast1)

### 현재 일정 상태를 Firebase에서 읽는 법
사용자가 앱에서 수정한 **실제 현재 일정**은 이걸로 확인:
```bash
curl -s "https://nha-trang-a9fc6-default-rtdb.asia-southeast1.firebasedatabase.app/trip/v1.json"
```
- **전제:** 이 환경("사이로")의 Network access = Custom 에 위 도메인이 egress 허용목록에 등록돼 있어야 함 (사용자가 2026-06-22 등록 완료).
- 막히면(`Host not in allowlist`) → 이 세션 환경에 egress 미적용 상태. 새 세션이거나 [버그(#30112, #52982)]일 수 있음 → 그땐 앱의 **📤 내보내기** JSON을 사용자에게 받아 처리.

## 6. 알려진 한계 / 주의

- 새 세션은 대화 기억 없음 → **이 파일이 유일한 기억**. 중요 변경 시 갱신.
- 이 세션엔 computer-use(화면 클릭) 기능 **없음**. 브라우저 조작은 사용자가 직접.
- 네트워크 egress 제한: github.io, firebase 등 허용된 호스트만 curl 가능.
- 앱에서 한 수정은 원본 `DATA`에 자동 반영 안 됨 → 내보내기 JSON 받거나 Firebase 읽어서 수동 반영.

## 7. 작업 이력 (머지된 PR)

- #17 비행기 시간 확정(VJ919/LJ116)
- #18 Firebase 동기화 + 한글검색 + 드래그 + DAY1 재설계 (대형)
- #19 PC 길찾기 버튼을 진짜 `<a>` 링크로 수정 (팝업차단 우회)
- #20 일정 내보내기 기능 추가, SW v4

## 8. 대기/다음 작업 (TODO)

- [ ] 사용자가 길찾기·내보내기 실제 동작 확인 (캐시 비운 후)
- [ ] (선택) Firebase egress가 새 세션에서 실제 먹히는지 검증 — `curl trip/v1.json`
- [ ] (선택) 앱 수정 확정분을 원본 `DATA`에 영구 반영
- [ ] Firebase 테스트모드 만료(~7/22) 전 보안규칙 점검
