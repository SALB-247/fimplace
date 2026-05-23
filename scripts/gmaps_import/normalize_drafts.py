#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
normalize_drafts.py
===================
import_gmaps_list.py가 만든 드래프트 노트를, 사용자가 직접 손본 16개의
스타일에 맞게 일괄 정리한다.

규칙
- 태그
  · 인스타그램 → 인스타
  · DAYOFF / DAY OFF → DAY-OFF
  · LE_PLAY → LE PLAY
  · LE_NIVERSE → 르니버스
  · 뮤직비디오 / Kawaii_MV_촬영지 → MV_촬영지
  · 사쿠라 → 꾸라 (사용자 선호)
- 자체컨텐츠_촬영지: 자체 영상물(FIM-LOG/DAY-OFF/MV/르니버스/LE PLAY)에만 유지,
  인스타/위버스 단독이면 제거.
- 일본 도시/현 키워드가 있으면 region + `일본` 태그 추가.
- 본문: TODO 블록, 원본 컨텐츠 후보, <!-- 원본 메모: --> 주석을 모두 제거.
  메모에서 추출한 날짜/컨텐츠/멤버를 컨텍스트 한 줄로 본문 상단에 삽입.
- 지도 링크: 모두 [🗺️ 구글맵] 으로 통일 (일본/비-한국 가정).
- 위치는 TODO 플레이스홀더로 두고 추후 web search로 채움.

실행
  python scripts/gmaps_import/normalize_drafts.py
  python scripts/gmaps_import/normalize_drafts.py --dry-run
"""
import argparse
import re
import sys
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NOTES_DIR = ROOT / "_notes_import_output"

# 일본 도시/현 키워드 → (region, country)
JAPAN_CITY = {
    "도쿄": "도쿄", "신주쿠": "도쿄", "시부야": "도쿄", "하라주쿠": "도쿄",
    "긴자": "도쿄", "롯폰기": "도쿄", "롯본기": "도쿄", "롯본키": "도쿄",
    "아오야마": "도쿄", "오모테산도": "도쿄", "오다이바": "도쿄",
    "아카사카": "도쿄", "신바시": "도쿄", "우에노": "도쿄",
    "이케부쿠로": "도쿄", "아키하바라": "도쿄", "마루노우치": "도쿄",
    "오사카": "오사카", "도톤보리": "오사카", "신사이바시": "오사카",
    "난바": "오사카", "우메다": "오사카",
    "교토": "교토", "기온": "교토", "아라시야마": "교토",
    "나고야": "나고야", "사카에": "나고야",
    "삿포로": "삿포로", "후쿠오카": "후쿠오카", "요코하마": "요코하마",
    "고베": "고베", "닛코": "닛코", "가마쿠라": "가마쿠라",
    "나라": "나라",
}

JAPAN_PREFECTURE = {
    "야마나시": "야마나시현", "야마나시현": "야마나시현", "후지카와구치": "야마나시현",
    "후지요시다": "야마나시현",
    "카나가와": "카나가와현", "카나가와현": "카나가와현",
    "아이치": "아이치현", "아이치현": "아이치현",
    "미에": "미에현", "미에현": "미에현", "이세": "미에현",
    "홋카이도": "홋카이도", "지토세": "홋카이도", "오타루": "홋카이도",
    "토마무": "홋카이도",
    "효고": "효고현", "효고현": "효고현",
}

CITY_TO_PREFECTURE = {
    "도쿄": None,  # 도쿄도 자체
    "오사카": None,
    "교토": None,
    "나고야": "아이치현",
    "고베": "효고현",
    "요코하마": "카나가와현",
    "가마쿠라": "카나가와현",
}

TAG_REWRITE = {
    "인스타그램": "인스타",
    "DAYOFF": "DAY-OFF",
    "LE_PLAY": "LE PLAY",
    "LE_NIVERSE": "르니버스",
    "뮤직비디오": "MV_촬영지",
    "Kawaii_MV_촬영지": "MV_촬영지",
    "사쿠라": "꾸라",
}

INNER_CONTENT_TAGS = {"FIM-LOG", "DAY-OFF", "MV_촬영지", "르니버스", "LE PLAY"}

DATE_PATTERN = re.compile(r"(?<!\d)(\d{2})(\d{2})(\d{2})(?!\d)")
URL_PATTERN  = re.compile(r"https?://[^\s)\]\>]+")
ORIG_MEMO    = re.compile(r"<!--\s*원본 메모:\s*(.+?)\s*-->", re.S)


def detect_region(text):
    """제목/메모에서 일본 도시 + 현 추출."""
    cities = []
    prefs = []
    for k, v in JAPAN_PREFECTURE.items():
        if k in text and v not in prefs:
            prefs.append(v)
    for k, v in JAPAN_CITY.items():
        if k in text and v not in cities:
            cities.append(v)
    # 도시에 대응되는 현이 있으면 함께
    for c in cities:
        p = CITY_TO_PREFECTURE.get(c)
        if p and p not in prefs:
            prefs.append(p)
    return cities, prefs


def parse_frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    if not m:
        return None, text
    fm_body, rest = m.group(1), m.group(2)
    # title, tags 파싱 (단순)
    title = None
    tags = []
    for line in fm_body.splitlines():
        if line.startswith("title:"):
            title = line.split(":", 1)[1].strip()
        elif line.strip().startswith("- "):
            tags.append(line.strip()[2:].strip())
    return {"title": title, "tags": tags}, rest


def rebuild_frontmatter(title, tags):
    lines = ["---", f"title: {title}", "tags:"]
    for t in tags:
        lines.append(f"  - {t}")
    lines.append("---")
    return "\n".join(lines)


def normalize_tags(title, tags):
    # 1) rewrite
    new = []
    for t in tags:
        new.append(TAG_REWRITE.get(t, t))

    # 2) 자체컨텐츠_촬영지 규칙
    has_inner_video = any(t in INNER_CONTENT_TAGS for t in new)
    has_external_marker = any(t in new for t in ("인스타", "위버스", "위버스라이브", "위버스DM"))
    if "자체컨텐츠_촬영지" in new:
        if not has_inner_video and has_external_marker:
            new.remove("자체컨텐츠_촬영지")
    # 외부컨텐츠 마커도 제거 — 사용자 스타일에선 사용 안 함
    if "외부컨텐츠" in new:
        new.remove("외부컨텐츠")

    # 3) 일본 지역 추가
    cities, prefs = detect_region(title)
    # 메모에서도 보려면 후에 다시 호출
    for c in cities + prefs:
        if c not in new:
            new.append(c)
    if (cities or prefs) and "일본" not in new:
        new.append("일본")

    # 4) 중복 제거 (순서 유지)
    seen = set(); out = []
    for t in new:
        if t and t not in seen:
            seen.add(t); out.append(t)
    return out


def strip_auto_sections(body):
    """TODO 블록, 원본 컨텐츠 후보, 자동 생성된 안내 주석 제거."""
    # 검수 TODO 블록
    body = re.sub(r"<!--\s*\n?\s*검수 TODO:.*?-->\s*\n?", "", body, flags=re.S)
    # 자동 iframe 안내 주석
    body = re.sub(r"<!--\s*아래 iframe은 장소명으로.*?HTML로 교체하세요\.\s*-->\s*\n?", "", body, flags=re.S)
    # 원본 컨텐츠 후보 섹션 ~ 다음 ## 또는 <!--원본 메모 또는 파일 끝
    body = re.sub(r"##\s*원본 컨텐츠 후보\s*\n(.*?)(?=(\n<!--\s*원본 메모|\Z))", "", body, flags=re.S)
    # 지역 미상 안내 주석
    body = re.sub(r"<!--\s*지역 미상:.*?-->\s*\n?", "", body, flags=re.S)
    body = re.sub(r"<!--\s*##\s*\[.+?구글맵.+?-->\s*\n?", "", body, flags=re.S)
    # 위치 TODO 주석
    body = re.sub(r"<!--\s*TODO:\s*정확한 주소.*?-->\s*\n?", "", body, flags=re.S)
    # 위치 fallback 라인
    body = re.sub(r"^검색:\s*.*$\n?", "", body, flags=re.M)
    return body


def extract_memo_and_context(body):
    """<!-- 원본 메모: ... --> 추출 후 제거. context 한 줄로 반환."""
    m = ORIG_MEMO.search(body)
    if not m:
        return body, ""
    memo = m.group(1).strip()
    body = ORIG_MEMO.sub("", body)
    # 컨텍스트 라인: YYMMDD를 YYYY-MM-DD로 변환 + 그대로
    dates = []
    for dm in DATE_PATTERN.finditer(memo):
        y, mm, dd = dm.group(1), dm.group(2), dm.group(3)
        try:
            mi, di = int(mm), int(dd)
            if 1 <= mi <= 12 and 1 <= di <= 31:
                dates.append(f"{y}{mm}{dd}")
        except ValueError:
            pass
    # 컨텍스트: 메모 그대로 한 줄로 정리 (URL은 별도 처리 가능)
    ctx = re.sub(r"\s+", " ", memo).strip()
    return body, ctx


def remove_naver_kakao(body):
    body = re.sub(r"##\s*\[🅽네이버지도\].*$\n?", "", body, flags=re.M)
    body = re.sub(r"##\s*\[🅚카카오 지도\].*$\n?", "", body, flags=re.M)
    return body


def ensure_gmaps_link(body, title):
    q = urllib.parse.quote(title)
    if "## [🗺️ 구글맵]" in body:
        return body
    body = body.rstrip() + f"\n\n## [🗺️ 구글맵](https://www.google.com/maps/search/?api=1&query={q})\n"
    return body


def restructure(body, title, ctx):
    """본문 정렬: iframe들 → 컨텍스트 → ## 상호명 → ## 위치 → ## [🗺️ 구글맵]"""
    # 구글맵 라인 먼저 추출/제거 (## 위치 정규식 충돌 방지)
    gmaps_m = re.search(r"##\s*\[🗺️ 구글맵\][^\n]*", body)
    gmaps_line = gmaps_m.group(0) if gmaps_m else ""
    if gmaps_line:
        body = body.replace(gmaps_line, "", 1)

    # iframe 추출
    iframes = re.findall(r"<iframe[^>]*>.*?</iframe>", body, flags=re.S)
    # 이미지 추출
    imgs = re.findall(r"<img\s+src=[^>]+>", body, flags=re.S)

    # 기존 ## 위치 추출 (line-anchored, ##으로 시작하는 라인까지)
    loc_m = re.search(r"^##\s*위치\s*\n(.*?)(?=^##\s|\Z)", body, flags=re.S | re.M)
    loc_text = loc_m.group(1).strip() if loc_m else ""
    if loc_text and not loc_text.startswith("<!--"):
        loc_line = loc_text
    else:
        loc_line = "<!-- TODO: 정확한 일본어 주소 (web search 또는 수동 입력) -->"

    parts = []
    # YouTube 우선, 인스타, Google Maps 순으로 정렬
    yt = [i for i in iframes if "youtube" in i.lower() or "youtu.be" in i.lower()]
    ig = [i for i in iframes if "instagram" in i.lower()]
    gm = [i for i in iframes if "google.com/maps" in i.lower() or "maps.google" in i.lower()]
    others = [i for i in iframes if i not in yt and i not in ig and i not in gm]

    for x in yt: parts.append(x)
    for x in imgs: parts.append(x)
    for x in ig: parts.append(x)
    for x in gm: parts.append(x)
    for x in others: parts.append(x)

    if ctx:
        parts.append(ctx)

    parts.append(f"## 상호명\n{title}")
    parts.append(f"## 위치\n{loc_line}")
    if not gmaps_line:
        q = urllib.parse.quote(title)
        gmaps_line = f"## [🗺️ 구글맵](https://www.google.com/maps/search/?api=1&query={q})"
    parts.append(gmaps_line)

    return "\n\n".join(parts) + "\n"


def normalize_file(path, dry_run=False):
    text = path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    if not fm:
        return False, "no frontmatter"

    title = fm["title"]
    tags = fm["tags"]

    # 메모를 활용해 더 정확한 지역 감지
    memo_match = ORIG_MEMO.search(body)
    memo_text = memo_match.group(1) if memo_match else ""
    cities_m, prefs_m = detect_region(memo_text)
    for c in cities_m + prefs_m:
        if c not in tags:
            tags.append(c)
    if (cities_m or prefs_m) and "일본" not in tags:
        tags.append("일본")

    new_tags = normalize_tags(title, tags)

    body = strip_auto_sections(body)
    body, ctx = extract_memo_and_context(body)
    body = remove_naver_kakao(body)
    body = restructure(body, title, ctx)
    body = ensure_gmaps_link(body, title)

    new_text = rebuild_frontmatter(title, new_tags) + "\n\n" + body.lstrip("\n")
    if new_text == text:
        return False, "no change"

    if dry_run:
        return True, "would change"
    path.write_text(new_text, encoding="utf-8")
    return True, "rewritten"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", help="특정 파일명만 처리 (substring match)")
    ap.add_argument("--force", action="store_true", help="이미 정규화된 파일도 다시 처리")
    args = ap.parse_args()

    if not NOTES_DIR.exists():
        print(f"[ERR] {NOTES_DIR} 없음", file=sys.stderr)
        return 2

    files = sorted(NOTES_DIR.glob("*.md"))
    skipped, changed, unchanged = 0, 0, 0
    for f in files:
        if args.only and args.only not in f.name:
            continue
        # 이미 수동 처리된 파일은 스킵 (검수 TODO 없음 + 원본 컨텐츠 후보 없음 + 위치 TODO 없음)
        text = f.read_text(encoding="utf-8")
        already_done = (
            "검수 TODO" not in text
            and "원본 컨텐츠 후보" not in text
            and "<!-- TODO: 정확한 주소" not in text
            and "<!-- 원본 메모:" not in text
        )
        if already_done and not args.force:
            skipped += 1
            continue
        ok, msg = normalize_file(f, dry_run=args.dry_run)
        if ok:
            changed += 1
            print(f"  [{'WOULD' if args.dry_run else 'NORM'}] {f.name}")
        else:
            unchanged += 1
            print(f"  [SKIP] {f.name} ({msg})")

    print()
    print(f"총 {len(files)} | 수동완료 스킵 {skipped} | 정규화 {changed} | 변동없음 {unchanged}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
