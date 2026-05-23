#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
import_gmaps_list.py
====================

구글 맵 리스트(저장한 장소 목록) DOM을 받아서
fimplace의 `_notes/*.md` 스켈레톤을 생성한다.

사용법
------
  python import_gmaps_list.py input.html --dry-run            # 미리보기
  python import_gmaps_list.py input.html --out _notes_import_output  # 실제 생성

설계 원칙
- 확신 없는 항목은 자동 태그를 붙이지 않고 TODO 코멘트로 남긴다.
- 장소명을 이용해 구글맵 search iframe과 주소 필드를 자동 채운다.
  (정확한 좌표가 필요한 경우 사용자가 '지도 퍼가기' iframe으로 교체)
"""

import argparse
import re
import sys
import unicodedata
import urllib.parse
from pathlib import Path

try:
    from bs4 import BeautifulSoup
except ImportError:
    print("[ERR] beautifulsoup4가 필요합니다: pip install beautifulsoup4", file=sys.stderr)
    sys.exit(1)


# -----------------------------------------------------------------------------
# 매핑 테이블
# -----------------------------------------------------------------------------

# Google 카테고리 → fimplace 태그
GMAPS_CATEGORY_TO_TAG = {
    "카페": "카페", "커피숍": "카페", "커피 전문점": "카페",
    "디저트 카페": "카페", "베이커리 카페": "카페",
    "제과점": "카페", "베이커리": "카페",
    "초밥": "음식점", "초밥집": "음식점", "스시": "음식점", "초밥 전문점": "음식점",
    "라멘 전문점": "음식점", "라멘": "음식점",
    "우동 전문점": "음식점", "라이브하우스": "음식점",
    "음식점": "음식점", "식당": "음식점", "레스토랑": "음식점",
    "양식당": "음식점", "이탈리아 음식점": "음식점",
    "일식당": "음식점", "일본 음식점": "음식점",
    "한식당": "음식점", "한식 음식점": "음식점",
    "중식당": "음식점", "중국 음식점": "음식점",
    "고깃집": "음식점", "삼겹살집": "음식점",
    "분식점": "음식점", "포장마차": "음식점",
    "이자카야": "음식점", "주점": "음식점",
    "바": "음식점", "와인 바": "음식점", "칵테일 바": "음식점",
    "패스트푸드점": "음식점", "햄버거 음식점": "음식점",
    "호텔": "숙박시설", "리조트": "숙박시설", "료칸": "숙박시설",
    "여관": "숙박시설", "게스트하우스": "숙박시설", "에어비앤비": "숙박시설",
    "관광 명소": "관광지", "명소": "관광지", "관광지": "관광지",
    "사찰": "관광지", "신사": "관광지",
    "박물관": "관광지", "미술관": "관광지", "공원": "관광지", "전망대": "관광지",
    "쇼핑몰": "쇼핑", "백화점": "쇼핑",
    "편의점": "쇼핑", "마트": "쇼핑",
    "상점": "쇼핑", "기념품점": "쇼핑",
    "잡화점": "쇼핑", "서점": "쇼핑",
}

# 멤버 풀네임 / 영문 이름 / 일본어 / 한자 — 높은 신뢰도
# 풀네임은 곧장 멤버로 확정.
FULL_MEMBER_PATTERNS = [
    (re.compile(r"사쿠라|宮脇咲良|미야와키\s*사쿠라|サクラ|\bSakura\b|\bSAKURA\b"), "사쿠라"),
    (re.compile(r"김채원|\bChaewon\b|\bCHAEWON\b|Kim\s*Chaewon", re.I), "김채원"),
    (re.compile(r"허윤진|\bYunjin\b|\bYUNJIN\b|Huh\s*Yunjin", re.I), "허윤진"),
    (re.compile(r"카즈하|カズハ|\bKazuha\b|\bKAZUHA\b|中村\s*一葉"), "카즈하"),
    (re.compile(r"홍은채|\bEunchae\b|\bEUNCHAE\b|Hong\s*Eunchae", re.I), "홍은채"),
]

# 짧은 별칭 — 한글/영문 단어 경계로 보호.
# 즉, 앞뒤에 한글/영문이 붙어 있으면(다른 단어의 일부) 매칭 안 함.
# 예) "채원이" ← OK 매칭, "지원에는 채원하는 게 좋다" 처럼 다른 단어 안에 든 경우 미매칭.
def _bound(alias):
    # 앞뒤로 한글/영문이 없을 때만 매칭
    return re.compile(rf"(?<![가-힣A-Za-z]){re.escape(alias)}(?![가-힣A-Za-z])")

SHORT_ALIAS_PATTERNS = [
    (_bound("꾸라"), "사쿠라"),
    (_bound("사꾸라"), "사쿠라"),
    (_bound("채원"), "김채원"),
    (_bound("채원이"), "김채원"),
    (_bound("윤진"), "허윤진"),
    (_bound("윤진이"), "허윤진"),
    (_bound("즈하"), "카즈하"),
    (_bound("쟈"), "카즈하"),    # 즈하 → 쟈로 종종 쓰임
    (_bound("은채"), "홍은채"),
    (_bound("은채니"), "홍은채"),
]

# 약어 / 그룹 표현 (멤버 전원 또는 일부)
# 주의: "LE SSERAFIM"은 공백/구분자 필수 — URL의 "lesserafim" 오탐 방지
GROUP_PATTERNS = [
    (re.compile(r"(?<![가-힣A-Za-z])전원(?![가-힣A-Za-z])|르세라핌|\bLE[\s_-]+SSERAFIM\b", re.I), ["사쿠라", "김채원", "허윤진", "카즈하", "홍은채"]),
    (re.compile(r"(?<![가-힣A-Za-z])진즈하(?![가-힣A-Za-z])"), ["허윤진", "카즈하"]),
    (re.compile(r"(?<![가-힣A-Za-z])채하(?![가-힣A-Za-z])"), ["김채원", "카즈하"]),
    (re.compile(r"(?<![가-힣A-Za-z])즈해이(?![가-힣A-Za-z])"), ["카즈하", "홍은채"]),
]

# 메모 → 컨텐츠 유형 태그
CONTENT_TYPE_PATTERNS = [
    (re.compile(r"(인스타|instagram|insta)", re.I), "인스타그램"),
    (re.compile(r"위버스라이브|위버스\s*라이브"), "위버스라이브"),
    (re.compile(r"위버스\s*DM|weverse\s*DM", re.I), "위버스DM"),
    (re.compile(r"위버스(?!라이브|\s*DM)"), "위버스"),
    (re.compile(r"FIM[-\s]?LOG", re.I), "FIM-LOG"),
    (re.compile(r"LE\s*PLAY", re.I), "LE_PLAY"),
    (re.compile(r"LENIVERSE", re.I), "LE_NIVERSE"),
    (re.compile(r"DAY[-\s]?OFF", re.I), "DAYOFF"),
    (re.compile(r"카와이|Kawaii", re.I), "Kawaii_MV_촬영지"),
    (re.compile(r"화보|magazine|매거진", re.I), "화보"),
    (re.compile(r"광고|CF\b", re.I), "광고"),
    (re.compile(r"M/?V|뮤직비디오", re.I), "뮤직비디오"),
]

# 자체 컨텐츠 식별 키워드
INNER_CONTENT_KEYWORDS = [
    "FIM-LOG", "FIM LOG", "위버스", "인스타", "instagram",
    "LE PLAY", "LE_PLAY", "LENIVERSE", "DAYOFF", "DAY OFF", "DAY-OFF",
]

# 일본 지역 키워드
JAPAN_REGION_KEYWORDS = {
    "도쿄": "도쿄", "Tokyo": "도쿄", "東京": "도쿄", "신주쿠": "도쿄", "시부야": "도쿄",
    "하라주쿠": "도쿄", "긴자": "도쿄", "롯폰기": "도쿄", "아오야마": "도쿄", "오모테산도": "도쿄",
    "오사카": "오사카", "Osaka": "오사카", "大阪": "오사카", "난바": "오사카", "신사이바시": "오사카",
    "교토": "교토", "Kyoto": "교토", "京都": "교토",
    "나고야": "나고야", "Nagoya": "나고야", "名古屋": "나고야",
    "삿포로": "삿포로", "Sapporo": "삿포로",
    "후쿠오카": "후쿠오카", "Fukuoka": "후쿠오카",
    "요코하마": "요코하마", "Yokohama": "요코하마",
    "고베": "고베", "Kobe": "고베",
    "닛코": "닛코", "Nikko": "닛코",
    "가마쿠라": "가마쿠라", "Kamakura": "가마쿠라",
    "나라": "나라", "Nara": "나라",
}

# 한국 지역 키워드
KOREA_REGION_KEYWORDS = {
    "서울": "서울", "Seoul": "서울",
    "부산": "부산", "Busan": "부산",
    "제주": "제주",
    "경기": "경기",
    "강원": "강원",
    "인천": "인천",
    "대구": "대구",
    "광주": "광주",
    "대전": "대전",
}

# 멤버 개인 인스타그램 핸들 (후보 — 변경될 수 있음)
MEMBER_INSTAGRAM = {
    "사쿠라": "39saku_lalala",
    "김채원": "_chaechae_1",
    "허윤진": "jenaissante",
    "카즈하": "_kazuha_official",
    "홍은채": "hong_eunchae",
}

# LE SSERAFIM 공식 채널
LE_SSERAFIM_OFFICIAL = {
    "instagram": "https://www.instagram.com/le_sserafim/",
    "youtube":   "https://www.youtube.com/@LE_SSERAFIM",
    "weverse":   "https://weverse.io/lesserafim",
    "tiktok":    "https://www.tiktok.com/@le_sserafim",
}

# 메모 내 URL / 날짜 추출 패턴
URL_PATTERN  = re.compile(r"https?://[^\s)\]\>]+")
DATE_PATTERN = re.compile(r"(?<!\d)(\d{2})(\d{2})(\d{2})(?!\d)")  # YYMMDD


# -----------------------------------------------------------------------------
# 파싱
# -----------------------------------------------------------------------------

def parse_dom(html_text: str):
    """
    Google Maps 리스트의 outerHTML을 받아서 장소 dict 리스트를 반환.
    """
    soup = BeautifulSoup(html_text, "html.parser")

    blocks = soup.select('div[role="article"]')
    if not blocks:
        blocks = soup.select("div.m6QErb.XiKgde")
    if not blocks:
        blocks = soup.select(".bfdHYd")

    places = []
    for block in blocks:
        title_el = block.select_one(".fontHeadlineSmall") or block.select_one("[role='heading']")
        if not title_el:
            continue
        title = title_el.get_text(strip=True)
        if not title:
            continue

        # 카테고리
        category = ""
        cat_box = block.select_one(".IIrLbb")
        if cat_box:
            cat_divs = cat_box.find_all("div")
            if len(cat_divs) >= 2:
                category = cat_divs[1].get_text(strip=True)
        if not category:
            w4 = block.select_one(".W4Efsd")
            if w4:
                category = w4.get_text(" ", strip=True).split("·")[0].strip()

        # 메모
        memo = ""
        memo_el = (
            block.select_one(".u5DVOd .SwaGS span")
            or block.select_one(".u5DVOd")
            or block.select_one("[aria-label*='메모']")
        )
        if memo_el:
            memo = memo_el.get_text(" ", strip=True)

        # 주소
        address = ""
        addr_el = block.select_one("[data-tooltip='주소 복사']")
        if not addr_el:
            addr_candidates = block.select(".W4Efsd")
            for c in addr_candidates:
                txt = c.get_text(" · ", strip=True)
                if any(k in txt for k in ["市", "区", "구 ", "동 ", "로 ", "길 ", "Ave", "St ", "도 ", "Tokyo", "Osaka", "Kyoto"]):
                    address = txt
                    break

        places.append({
            "title": title,
            "category": category,
            "memo": memo,
            "address": address,
        })

    return places


# -----------------------------------------------------------------------------
# 분류 (강화된 멤버 추출)
# -----------------------------------------------------------------------------

MEMBER_ORDER = ["사쿠라", "김채원", "허윤진", "카즈하", "홍은채"]


def detect_members(memo: str):
    """
    확신 있는 멤버만 추출.
    반환: (확정 멤버 리스트, 신뢰도 코멘트 or None)

    신뢰도 정책
    - FULL 매칭(풀네임/영문)만 있으면 'high'
    - SHORT 별칭만 있으면 'medium' (단어 경계 통과)
    - GROUP 패턴 (르세라핌/진즈하 등)도 포함
    - 아무것도 못 잡으면 None 반환 → 노트에 TODO 코멘트 삽입
    """
    if not memo or not memo.strip():
        return [], "memo_empty"

    # URL은 멤버 식별 노이즈 — 메모에서 제거한 뒤 매칭
    memo = URL_PATTERN.sub(" ", memo)

    found = set()
    sources = []  # ["full", "short", "group"]

    for pattern, name in FULL_MEMBER_PATTERNS:
        if pattern.search(memo):
            found.add(name)
            sources.append("full")

    for pattern, name in SHORT_ALIAS_PATTERNS:
        if pattern.search(memo):
            found.add(name)
            sources.append("short")

    for pattern, names in GROUP_PATTERNS:
        if pattern.search(memo):
            for n in names:
                found.add(n)
            sources.append("group")

    if not found:
        return [], "no_member_detected"

    ordered = [m for m in MEMBER_ORDER if m in found]

    # 신뢰도 평가: short alias만으로 잡힌 경우 medium
    if "full" not in sources and "group" not in sources and "short" in sources:
        return ordered, "medium_confidence"

    return ordered, None


def detect_content_types(memo: str):
    if not memo:
        return []
    found = []
    for pattern, tag in CONTENT_TYPE_PATTERNS:
        if pattern.search(memo) and tag not in found:
            found.append(tag)
    return found


def detect_region(title: str, address: str, memo: str):
    blob = f"{title} {address} {memo}"
    for keyword, region in JAPAN_REGION_KEYWORDS.items():
        if keyword in blob:
            return region
    for keyword, region in KOREA_REGION_KEYWORDS.items():
        if keyword in blob:
            return region
    return ""


def map_category(google_category: str):
    if not google_category:
        return ""
    if google_category in GMAPS_CATEGORY_TO_TAG:
        return GMAPS_CATEGORY_TO_TAG[google_category]
    for key, tag in GMAPS_CATEGORY_TO_TAG.items():
        if key in google_category:
            return tag
    return ""


def is_korea_region(region_tag: str) -> bool:
    return bool(region_tag) and region_tag in set(KOREA_REGION_KEYWORDS.values())


def is_japan_region(region_tag: str) -> bool:
    return bool(region_tag) and region_tag in set(JAPAN_REGION_KEYWORDS.values())


def extract_urls(memo: str):
    if not memo:
        return []
    return [u.rstrip(".,;'\"") for u in URL_PATTERN.findall(memo)]


def extract_dates(memo: str):
    """YYMMDD → YYYY-MM-DD 리스트. 부적절한 날짜는 건너뜀."""
    out = []
    if not memo:
        return out
    for m in DATE_PATTERN.finditer(memo):
        y, mm, dd = m.group(1), m.group(2), m.group(3)
        try:
            year = 2000 + int(y)
            month = int(mm); day = int(dd)
            if 1 <= month <= 12 and 1 <= day <= 31:
                out.append(f"{year}-{month:02d}-{day:02d}")
        except ValueError:
            pass
    return out


def build_content_candidates(memo: str, members: list, content_types: list) -> str:
    """
    원본 컨텐츠 후보 섹션 생성.
    - 메모 내 URL은 그대로 노출
    - 인스타/위버스/영상 컨텐츠 키워드가 있으면 후보 링크 첨부
    - 멤버가 추출돼 있으면 멤버별 개인 인스타 핸들도 함께
    """
    blocks = []
    urls = extract_urls(memo)
    dates = extract_dates(memo)
    date_str = f" ({', '.join(dates)})" if dates else ""

    if urls:
        section = ["**메모에서 추출된 URL**"]
        for u in urls:
            section.append(f"- <{u}>")
        blocks.append("\n".join(section))

    # 인스타그램
    if "인스타그램" in content_types:
        section = [f"**📷 인스타그램 후보{date_str}**"]
        for m in members:
            h = MEMBER_INSTAGRAM.get(m)
            if h:
                section.append(f"- [{m} 인스타](https://www.instagram.com/{h}/)")
        section.append(f"- [LE SSERAFIM 공식 인스타]({LE_SSERAFIM_OFFICIAL['instagram']})")
        blocks.append("\n".join(section))

    # 위버스
    if any(t in content_types for t in ("위버스", "위버스라이브", "위버스DM")):
        section = [f"**🟣 위버스 후보{date_str}**"]
        section.append(f"- [LE SSERAFIM 위버스]({LE_SSERAFIM_OFFICIAL['weverse']})")
        blocks.append("\n".join(section))

    # 영상 (FIM-LOG / LE PLAY / LENIVERSE / DAYOFF / MV / Kawaii)
    video_keys = ("FIM-LOG", "LE_PLAY", "LE_NIVERSE", "DAYOFF", "뮤직비디오", "Kawaii_MV_촬영지")
    if any(t in content_types for t in video_keys):
        section = [f"**🎬 영상 후보{date_str}**"]
        section.append(f"- [LE SSERAFIM 공식 YouTube]({LE_SSERAFIM_OFFICIAL['youtube']})")
        # 컨텐츠 종류별 YouTube 검색 링크
        for t in content_types:
            if t in video_keys:
                # YYMMDD 들도 검색어에 추가
                terms = [t.replace("_", " ")]
                if dates:
                    terms += [d.replace("-", "") for d in dates]
                q = urllib.parse.quote(" ".join(terms))
                section.append(f"- YouTube 검색: [{t}](https://www.youtube.com/results?search_query={q})")
        blocks.append("\n".join(section))

    if not blocks:
        return ""
    return "## 원본 컨텐츠 후보\n\n" + "\n\n".join(blocks) + "\n"


def detect_inner_outer(memo: str):
    """
    자체/외부 컨텐츠 구분.
    반환: ('자체컨텐츠'|'외부컨텐츠', confident bool)
    """
    if not memo or not memo.strip():
        return "외부컨텐츠", False  # 정보 없음 → 외부 가정 + 불확실
    for k in INNER_CONTENT_KEYWORDS:
        if re.search(re.escape(k), memo, re.I):
            return "자체컨텐츠", True
    return "외부컨텐츠", True


# -----------------------------------------------------------------------------
# 노트 생성
# -----------------------------------------------------------------------------

def slugify_for_filename(title: str):
    s = unicodedata.normalize("NFC", title)
    s = re.sub(r'[<>:"/\\|?*]', "", s)
    s = s.strip().strip(".")
    return s or "untitled"


def build_gmaps_search_iframe(title: str):
    """
    장소명을 이용한 임시 구글맵 search iframe.
    실제 좌표가 필요한 경우 사용자가 '지도 퍼가기' iframe으로 교체해야 한다.
    """
    q = urllib.parse.quote(title)
    return (
        f'<iframe src="https://maps.google.com/maps?q={q}&output=embed" '
        f'width="600" height="450" frameborder="0" style="border:0;" '
        f'allowfullscreen loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>'
    )


SHORT_MEMBER_TAG = {
    "사쿠라": "사쿠라",
    "김채원": "채원",
    "허윤진": "윤진",
    "카즈하": "즈하",
    "홍은채": "은채",
}


def build_note_md(place: dict) -> str:
    title = place["title"]
    category = place.get("category", "")
    memo = place.get("memo", "")
    address = place.get("address", "")

    members, member_note = detect_members(memo)
    content_tags = detect_content_types(memo)
    region = detect_region(title, address, memo)
    type_tag = map_category(category)
    inner_outer, inner_outer_confident = detect_inner_outer(memo)

    # 태그
    tags = []
    if inner_outer == "자체컨텐츠":
        tags.append("자체컨텐츠_촬영지")
    else:
        tags.append("외부컨텐츠")
    for t in content_tags:
        if t not in tags:
            tags.append(t)
    if type_tag and type_tag not in tags:
        tags.append(type_tag)
    if region and region not in tags:
        tags.append(region)
    for m in members:
        short = SHORT_MEMBER_TAG[m]
        if short not in tags:
            tags.append(short)

    # frontmatter
    fm_lines = ["---", f"title: {title}", "tags:"]
    for t in tags:
        fm_lines.append(f"  - {t}")
    fm_lines.append("---")
    fm = "\n".join(fm_lines)

    # 본문
    body_lines = []
    body_lines.append("")

    # 검수 TODO 헤더 (불확실 항목 통합)
    todos = []
    if member_note == "memo_empty":
        todos.append("멤버 정보가 메모에 없음 — 수동 입력 필요")
    elif member_note == "no_member_detected":
        todos.append("메모에서 멤버를 인식하지 못함 — 수동 입력 필요")
    elif member_note == "medium_confidence":
        todos.append(f"멤버 자동 추출(짧은 별칭 기반, 검토 필요): {', '.join(members)}")
    if not inner_outer_confident:
        todos.append("자체/외부 컨텐츠 구분 불확실 — 기본값 '외부컨텐츠'로 설정")
    if not type_tag:
        todos.append(f"장소 유형 태그 자동 추출 실패 (Google 카테고리: '{category}')")
    if not region:
        todos.append("광역 지역 태그 자동 추출 실패 — 수동 입력 필요")

    if todos:
        body_lines.append("<!--")
        body_lines.append("  검수 TODO:")
        for t in todos:
            body_lines.append(f"  - {t}")
        body_lines.append("-->")
        body_lines.append("")

    # 구글맵 iframe (장소명 기반 임시)
    body_lines.append("<!-- 아래 iframe은 장소명으로 자동 생성된 임시 검색 임베드.")
    body_lines.append("     정확한 좌표가 필요하면 구글맵 → 공유 → '지도 퍼가기' 의 HTML로 교체하세요. -->")
    body_lines.append(build_gmaps_search_iframe(title))
    body_lines.append("")

    body_lines.append("## 상호명")
    body_lines.append(title)
    body_lines.append("")

    body_lines.append("## 위치")
    if address:
        body_lines.append(address)
    else:
        body_lines.append(f"<!-- TODO: 정확한 주소 입력 (자동 추출 실패) -->")
        body_lines.append(f"검색: {title}")
    body_lines.append("")

    q = urllib.parse.quote(title)
    # 지도 링크: 한국 vs 비-한국 분기
    if is_japan_region(region) or (region and not is_korea_region(region)):
        body_lines.append(f"## [🗺️ 구글맵](https://www.google.com/maps/search/?api=1&query={q})")
        body_lines.append("")
    else:
        # 한국 또는 미상 → 네이버 + 카카오 (미상이면 구글맵도 후보로 첨부)
        body_lines.append(f"## [🅽네이버지도](https://map.naver.com/p/search/{q})")
        body_lines.append("")
        body_lines.append(f"## [🅚카카오 지도](https://map.kakao.com/?q={q})")
        body_lines.append("")
        if not region:
            body_lines.append(f"<!-- 지역 미상: 비-한국일 경우 위 두 줄을 지우고 아래 사용 -->")
            body_lines.append(f"<!-- ## [🗺️ 구글맵](https://www.google.com/maps/search/?api=1&query={q}) -->")
            body_lines.append("")

    # 원본 컨텐츠 후보 (인스타/위버스/영상 링크)
    candidates_md = build_content_candidates(memo, members, content_tags)
    if candidates_md:
        body_lines.append(candidates_md)

    if memo:
        body_lines.append(f"<!-- 원본 메모: {memo} -->")
        body_lines.append("")

    return fm + "\n" + "\n".join(body_lines)


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Google Maps 리스트 DOM → fimplace 노트 스켈레톤")
    ap.add_argument("input", help="Google Maps 리스트 outerHTML 파일 경로")
    ap.add_argument("--out", default="_notes_import_output",
                    help="출력 디렉토리 (기본: _notes_import_output)")
    ap.add_argument("--dry-run", action="store_true", help="파일 생성 없이 결과만 출력")
    ap.add_argument("--existing-notes", default="_notes",
                    help="중복 체크용 기존 _notes 디렉토리 (기본: _notes)")
    ap.add_argument("--overwrite", action="store_true", help="이미 존재하는 파일도 덮어쓰기")
    args = ap.parse_args()

    html_text = Path(args.input).read_text(encoding="utf-8")
    places = parse_dom(html_text)

    if not places:
        print("[WARN] 파싱된 장소가 없습니다. DOM 구조가 바뀌었거나 셀렉터를 조정해야 합니다.", file=sys.stderr)
        return 2

    existing_dir = Path(args.existing_notes)
    existing_titles = set()
    if existing_dir.exists():
        for f in existing_dir.glob("*.md"):
            existing_titles.add(f.stem)

    out_dir = Path(args.out)
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    stats = {
        "total": len(places), "created": 0,
        "skipped_existing": 0, "skipped_duplicate": 0,
        "member_unknown": 0, "member_short_only": 0,
    }
    seen = set()

    for p in places:
        fname = slugify_for_filename(p["title"])
        if fname in seen:
            stats["skipped_duplicate"] += 1
            print(f"  [DUP]   {p['title']} (리스트 내 중복)")
            continue
        seen.add(fname)

        if fname in existing_titles and not args.overwrite:
            stats["skipped_existing"] += 1
            print(f"  [SKIP]  {p['title']} (이미 _notes/에 존재)")
            continue

        _, mnote = detect_members(p.get("memo", ""))
        if mnote in ("memo_empty", "no_member_detected"):
            stats["member_unknown"] += 1
        elif mnote == "medium_confidence":
            stats["member_short_only"] += 1

        md = build_note_md(p)
        target = out_dir / f"{fname}.md"

        if args.dry_run:
            print(f"  [WOULD] {target}")
            print("  ---")
            for line in md.splitlines()[:24]:
                print(f"    {line}")
            print("  ---")
        else:
            target.write_text(md, encoding="utf-8")
            print(f"  [WRITE] {target}")
        stats["created"] += 1

    print()
    print(f"총 {stats['total']}개 | 생성 {stats['created']} | "
          f"기존 스킵 {stats['skipped_existing']} | 리스트 중복 {stats['skipped_duplicate']}")
    print(f"  └ 멤버 추출 실패(수동 필요): {stats['member_unknown']}")
    print(f"  └ 멤버 짧은별칭만(검토 권장): {stats['member_short_only']}")
    if args.dry_run:
        print("dry-run 모드 — 실제 파일은 생성되지 않았습니다.")
    else:
        print(f"파일이 {out_dir}/ 에 생성되었습니다. 검수 후 _notes/ 로 옮기세요.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
