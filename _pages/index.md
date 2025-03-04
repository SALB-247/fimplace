---
layout: page
title: Home
id: home
permalink: /
---

# FimPlace 

핌플레이스는 르세라핌 관련 장소를 기록하는 보관소입니다.

문의는 fim.hlight@gmail.com으로 부탁드립니다.

<strong>Fimplace list</strong>

[[2025년 사쿠라 생일 이벤트]]

[[르니버스 촬영지]]


<strong>최근 업데이트된 장소</strong>

<ul>
  {% assign recent_notes = site.notes | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 5 %}
    <li>
      {{ note.last_modified_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

