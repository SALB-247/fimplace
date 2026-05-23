# Google Maps 리스트 → fimplace 노트 일괄 임포트 가이드

구글 맵에서 저장한 장소 리스트(예: <https://maps.app.goo.gl/m2K7wdMEJ1XbdRzg7>)를
파싱해서 `_notes/*.md` 스켈레톤을 자동 생성한다.

## 0. 사전 준비 (1회)

```powershell
# Python 패키지 (PowerShell 또는 cmd)
pip install beautifulsoup4
```

전체 워크플로우는 3단계로 구성됩니다:

1. **`import_gmaps_list.py`** — DOM → 노트 스켈레톤 생성
2. **`normalize_drafts.py`** — 사용자 스타일(꾸라/즈하 짧은 형태, DAY-OFF 하이픈, MV_촬영지 등)에 맞춰 일괄 정리
3. **`fill_addresses.py`** — Nominatim 지오코딩으로 `## 위치` 자동 채움 (캐시: `_data/address_cache.yml`)


## 1. 구글 맵 리스트 DOM 추출

1. PC 크롬에서 리스트 URL을 연다.
2. 모든 항목이 보일 때까지 스크롤을 끝까지 내린다 (lazy-load 때문).
3. F12 (DevTools) → Elements 탭.
4. 리스트 항목 하나를 우클릭 → **Inspect**.
5. 위로 거슬러 올라가서 항목들을 모두 감싸는 부모 컨테이너를 찾는다.
   - 보통 `div.m6QErb[role="feed"]` 또는 `div[role="region"]` 안의 `.m6QErb` 컨테이너.
   - 자식 항목들은 `div[role="article"]` 또는 `.m6QErb.XiKgde`.
6. 그 부모 div를 우클릭 → **Copy → Copy outerHTML**.
7. 메모장이나 VS Code에 붙여넣고 `input.html`로 저장.
   - 추천 위치: `E:\fimplace-Claude\scripts\gmaps_import\input.html` (gitignore 대상)

> 한 번에 잡기 어려우면 리스트를 두세 덩어리로 잘라서 여러 번 파싱해도 된다.

## 2. dry-run으로 미리보기

```powershell
cd E:\fimplace-Claude
python scripts\gmaps_import\import_gmaps_list.py scripts\gmaps_import\input.html --dry-run
```

출력 예시 (샘플 데이터):

```
  [WOULD] _notes_import_output/스시 사이토.md
  ---
    ---
    title: 스시 사이토
    tags:
      - 자체컨텐츠_촬영지
      - 인스타그램
      - 음식점
      - 사쿠라
      - 즈하
    ---
  ---
총 5개 중 생성 예정 5, 기존 스킵 0, 리스트 중복 0
dry-run 모드 — 실제 파일은 생성되지 않았습니다.
```

이 단계에서 확인할 것
- 장소 개수가 실제 리스트 항목 수와 맞는지
- 태그가 적절히 자동 추출되었는지 (멤버, 컨텐츠 유형, 장소 유형, 지역)
- 이미 `_notes/`에 존재하는 항목이 SKIP으로 표시되는지

만약 0건이 나오면 DOM 구조가 바뀐 것이므로 스크립트의 `parse_dom()`
셀렉터 (`.m6QErb.XiKgde`, `.fontHeadlineSmall`, `.IIrLbb`, `.SwaGS`) 를 조정.

## 3. 실제 생성

```powershell
python scripts\gmaps_import\import_gmaps_list.py scripts\gmaps_import\input.html --out _notes_import_output
```

- 출력 디렉토리는 일부러 `_notes/`와 분리. 검수 후 옮긴다.
- `_notes/`에 이미 있는 파일은 자동 스킵 (`--overwrite`로 강제 덮어쓰기 가능).

## 4. 검수 (가장 중요)

각 생성된 `.md`에 대해:

1. **구글맵 iframe 삽입** — 가장 중요.
   - 구글맵 검색 → 해당 장소 → 공유 → **지도 퍼가기** → HTML 복사 → `<!-- TODO ... -->` 자리에 붙여넣기.
   - `places_generator.rb`는 iframe 안의 `!2z` base64 검색어를 우선적으로 geocode에 사용하므로,
     iframe 하나만 잘 넣어주면 좌표가 자동으로 잡힌다.

2. **태그 검토**
   - 자동 추출은 메모 텍스트에만 의존하므로 누락될 수 있다.
   - 특히 일본 도시(도쿄/오사카/교토 등)와 멤버는 다시 확인.

3. **본문 보강** — 사진/영상/추가 메모 등.

4. **파일 이동**: 검수가 끝난 파일을 `_notes/`로 옮긴다.

```powershell
# 한꺼번에 옮기기 (PowerShell)
Move-Item _notes_import_output\*.md _notes\
```

## 5. 로컬 빌드로 확인

```powershell
bundle exec jekyll serve --livereload
```

- <http://localhost:4000/map/> 에서 마커가 정상 표시되는지 확인.
- 좌표가 안 나오면 `_data/places_db.yml`에 `lat`/`lon`을 수동 보정하거나,
  iframe의 검색어를 더 구체적으로 (도시명 포함) 다시 넣는다.

## 6. 커밋 & 배포

```powershell
git add _notes _data\places_db.yml
git commit -m "import: gmaps list (n places)"
git push
```

Netlify가 자동 빌드 → 배포.

---

## 한계 & 알려진 이슈

- 구글맵 DOM은 클래스명이 자주 바뀐다. 셀렉터 깨지면 `parse_dom()` 수정 필요.
- 메모가 비어 있으면 멤버/컨텐츠 유형이 비어 있다 — 수동 입력 필요.
- 일본 사찰/관광지처럼 한국어 한자 주소만 있는 경우, fimplace의 한국어 기반 geocoder가
  잡지 못할 수 있다. 이때는 frontmatter에 `lat`/`lon`을 직접 박는 것이 가장 안전.
- "% Arabica" 처럼 특수문자가 들어간 이름은 파일명 그대로 사용. URL에는 인코딩되지만
  Jekyll이 잘 처리한다.

## 파일 위치 요약

```
E:\fimplace-Claude\
├── scripts\
│   └── gmaps_import\
│       ├── import_gmaps_list.py   # 스크립트 본체
│       ├── GUIDE.md               # 이 파일
│       ├── input.html             # (사용자가 만들 것 — gitignore 권장)
│       └── sample\
│           ├── sample_input.html  # 동작 검증용
│           └── output\            # 샘플 실행 결과
└── _notes_import_output\          # 생성 결과 (검수 후 _notes/로)
```
