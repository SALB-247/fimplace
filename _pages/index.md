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


<strong>Hilighted list</strong>

<img src="assets/1741273417.jpg">

🔥

[[LE SSERAFIM 2025 POP UP - THE HOT HOUSE]]

[[사운드웨이브 럭키드로우  & 현장 이벤트_250314-250320]]


🌸

[[2025년 사쿠라 생일 이벤트]]

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

