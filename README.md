# Fimplace — 르세라핌 장소 아카이브

핌플레이스는 르세라핌 관련 장소를 기록하는 정적 웹사이트입니다.
사이트: https://fimplace.netlify.app

문의: **fim.hlight@gmail.com**

---

## 빠른 시작 (로컬 테스트)

```powershell
cd E:\fimplace-Claude
bundle exec jekyll serve --livereload --force_polling
```

브라우저: http://localhost:4000

## 배포

`main` 브랜치에 push → Netlify 자동 빌드/배포.

```powershell
git add .
git commit -m "..."
git push
```

---

## 디렉토리 구조

```
_notes/         노트 (마크다운). 한 파일 = 한 장소
_pages/         일반 페이지 (홈, 검색, 지도, 태그, about)
_layouts/       레이아웃 (default, note, page, term_index)
_includes/      공용 부분 (head, nav, footer, 지도 위젯)
_sass/          SCSS 스타일
_data/          빌드 시 참조하는 데이터 파일
  ├ places_db.yml       노트별 좌표 DB (사람이 편집 가능, 알파벳 순)
  ├ known_places.yml    역/사옥/공항 등 알려진 장소 좌표
  ├ tag_categories.yml  태그 카테고리 매핑
  └ geocode_cache.yml   Nominatim/Photon 응답 캐시 (자동 생성)
_plugins/       Ruby 플러그인 (Jekyll generator/hook)
assets/         이미지 파일
_site/          빌드 산출물 (.gitignore)
```

## 노트 작성

`_notes/` 폴더에 마크다운 파일 생성. frontmatter 예:

```yaml
---
title: 카페 이름
tags:
  - 카페
  - 용산
  - 사쿠라
---
```

본문에 `## 상호명`, `## 위치`, Google Maps embed `<iframe>` 등 자유 작성.
좌표는 빌드 시 자동 추출/지오코딩 → `_data/places_db.yml`에 캐싱.

## 좌표 수동 보정

지도에 표시된 위치가 잘못된 경우, 두 가지 방법:

**방법 1**: `_data/places_db.yml` 직접 편집
```yaml
"노트 제목":
  lat: 37.5232
  lng: 126.9648
  source: manual
  note: "수동 보정 사유"
```

**방법 2**: 노트 frontmatter에 `coords` 명시
```yaml
coords: [37.5232, 126.9648]
```

## 환경 설정

`_config.yml` 의 주요 항목:
- `vworld_api_key` — VWorld(한국 정부 무료 지도) API 키. 발급: https://www.vworld.kr/dev/v4api.do

---

## Git workflow 주의사항

- `_site/`, `.jekyll-cache/`, `_includes/notes_graph.json`, `.obsidian/` 는 `.gitignore` 처리됨
- `_data/places_db.yml` 은 **알파벳 순 정렬 유지** (자동 정렬됨) → merge conflict 최소화
- `_data/geocode_cache.yml` 은 캐시 누적되어도 OK, atomic write 적용

크레딧: 원본 템플릿 [maximevaillancourt/digital-garden-jekyll-template](https://github.com/maximevaillancourt/digital-garden-jekyll-template) (MIT). 핌플레이스 확장: 지도/검색/카테고리/지오코딩 등.
