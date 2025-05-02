---
layout: page
title: Home
id: home
permalink: /
---

# FimPlace 

🐆🌸🐍🦢🐥

핌플레이스는 르세라핌 관련 장소를 기록하는 보관소입니다.

문의는 fim.hlight@gmail.com으로 부탁드립니다.


<strong>High-lighted list</strong>

<img src="assets/E18485E185A1E1848BE185AEE18490E185B5E186BC20E18491E185A9E18489E185B3E18490E1.jpg">

🐆🌸🐍🦢🐥

[[2025 데뷔 3주년 이벤트]]


🌸🐍
[[핫쿨즈 스페셜 카페 250524-250525]]


🐍🦢

[[진즈하여행 총집편]]

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

