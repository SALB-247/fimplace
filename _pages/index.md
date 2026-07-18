---
layout: page
title: Home
id: home
permalink: /
---

# FimPlace 

🐯🌸🐍🦢🐥

핌플레이스는 르세라핌 관련 장소를 기록하는 보관소입니다.

문의는 fim.hlight@gmail.com으로 부탁드립니다.

<!-- font-size:0 = 링크 장식(↗)·공백 텍스트 노드가 이미지 아래 빈 줄을 만드는 것 방지 -->
<a href="{{ site.baseurl }}/2026-le-sserafim-tour-pureflow" style="display:block; position:relative; border-radius:12px; overflow:hidden; margin:1em 0 1.2em; width:100%; font-size:0; line-height:0;">
  <img src="assets/pureflow_banner.jpg" alt="2026 LE SSERAFIM TOUR 'PUREFLOW'" style="width:100%; display:block;">
  <span class="banner-cta" style="position:absolute; right:3%; bottom:8%; background:rgba(0,0,0,0.45); color:#fff; padding:0.35em 0.9em; border-radius:999px; font-size:13px; line-height:1.2; font-weight:700;">투어 일정 보기 →</span>
</a>
<style>
  /* 좁은 화면: CTA pill 이 PUREFLOW 타이틀을 가리므로 숨김 (배너 전체가 링크) */
  @media (max-width: 520px) { .banner-cta { display: none; } }
</style>

{% include home_map.html %}

<strong>High-lighted list</strong>

## [[2026 LE SSERAFIM TOUR 'PUREFLOW']]

## 🐯[[2026_채원_생일_이벤트]]


<strong>둘러보기</strong>

🗺️ [전체 지도 보기](/map/) — 모든 장소를 한눈에

🔍 [장소 검색](/search/) — 이름·태그·멤버로 검색

🏷️ [모든 태그](/tags/) — 카테고리 / 멤버별 인덱스

<strong>Fimplace list</strong>

[[-자체 컨텐츠 촬영지]]

[[-외부 컨텐츠 촬영지]]

[[-SNS 장소]]



<strong>최근 업데이트된 장소</strong>

<ul>
  {% assign recent_notes = site.notes | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 20 %}
    <li>
      {{ note.last_modified_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

