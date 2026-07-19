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



<strong>최근 일정 노트</strong>

<ul id="upcoming-events"><li style="color:var(--subtext);">일정 불러오는 중...</li></ul>

<script>
(function () {
  // 전체 날짜 풀(방문·업로드·이벤트 기간·공연)에서 |날짜 − 오늘| 최소 15개 선정 → 날짜순 나열.
  // 보는 시점(new Date) 기준이라 빌드 후에도 자동 갱신.
  function ms(s) {
    var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s || '');
    return m ? new Date(+m[1], +m[2] - 1, +m[3]).getTime() : null;
  }
  var DAY = 86400000;
  var now = new Date(); now.setHours(0, 0, 0, 0);
  var today = now.getTime();

  Promise.all([
    fetch('{{ site.baseurl }}/places.json').then(function (r) { return r.json(); }).catch(function () { return { places: [] }; }),
    fetch('{{ site.baseurl }}/tour_schedule.json').then(function (r) { return r.json(); }).catch(function () { return { shows: [] }; }),
    fetch('{{ site.baseurl }}/events.json').then(function (r) { return r.json(); }).catch(function () { return { events: [] }; })
  ]).then(function (res) {
    var items = [];
    var seen = {};   // url 기준 dedupe (places 와 events 에 같은 노트가 둘 다 있음)

    (res[0].places || []).forEach(function (p) {
      seen[p.url] = 1;
      var s = ms(p.start), e = ms(p.end);
      if (s !== null || e !== null) {
        // 이벤트(기간): 오늘이 기간 안이면 diff 0, 밖이면 가까운 끝점까지 거리
        var a = (s !== null ? s : e), b = (e !== null ? e : s);
        var diff = today < a ? a - today : (today > b ? today - b : 0);
        items.push({ title: p.title, url: p.url, date: a, endDate: b, diff: diff, kind: '기간' });
        return;
      }
      // 방문 기록: 오늘과 가장 가까운 방문일 1개
      var vs = (p.visits || []).map(function (v) { return ms(v.date); }).filter(function (x) { return x !== null; });
      if (vs.length) {
        var best = vs.reduce(function (acc, x) { return Math.abs(x - today) < Math.abs(acc - today) ? x : acc; }, vs[0]);
        items.push({ title: p.title, url: p.url, date: best, endDate: best, diff: Math.abs(best - today), kind: '방문' });
        return;
      }
      // 컨텐츠 게시일 (영상 업로드 / IG 게시)
      var d0 = ms(p.date);
      if (d0 !== null) {
        items.push({ title: p.title, url: p.url, date: d0, endDate: d0, diff: Math.abs(d0 - today), kind: '업로드' });
      }
    });

    (res[1].shows || []).forEach(function (sh) {
      if (sh.cancelled || !sh.venue) return;
      var s = ms(sh.start), e = ms(sh.end) || s;
      if (s === null) return;
      var diff = today < s ? s - today : (today > e ? today - e : 0);
      items.push({ title: (sh.flag || '') + ' ' + sh.city + ' — ' + sh.venue,
                   url: sh.venue_url || sh.tour_url, date: s, endDate: e, diff: diff, kind: '공연' });
    });

    // 지도에서 스킵된 노트(노선 광고 등)는 places 에 없음 → events 에서 보충 (url dedupe)
    (res[2].events || []).forEach(function (e) {
      if (seen[e.url]) return;
      var a = ms(e.start), b = ms(e.end) || a;
      if (a === null) return;
      var diff = today < a ? a - today : (today > b ? today - b : 0);
      items.push({ title: e.title, url: e.url, date: a, endDate: b, diff: diff, kind: '기간' });
    });

    // 1) 절대값 정렬 → 15개 선정 (미래는 날짜 차이에 ×3 가중 → 과거 중심 밸런스)
    //    2) 선정분을 날짜순 나열
    function selKey(it) { return it.diff * (it.date > today ? 3 : 1); }
    items.sort(function (a, b) { return selKey(a) - selKey(b) || a.date - b.date; });
    var picked = items.slice(0, 15);
    picked.sort(function (a, b) { return a.date - b.date || a.title.localeCompare(b.title); });

    function ymd(msv) {
      var x = new Date(msv);
      return x.getFullYear() + '-' + String(x.getMonth() + 1).padStart(2, '0') + '-' + String(x.getDate()).padStart(2, '0');
    }
    var html = picked.map(function (it) {
      var when = ymd(it.date) + (it.endDate !== it.date ? ' ~ ' + ymd(it.endDate) : '');
      var live = it.date <= today && today <= it.endDate + DAY - 1 && (it.kind === '기간' || it.kind === '공연');
      var badge = live ? '<span style="display:inline-block;background:#c9184a;color:#fff;padding:0.05em 0.5em;border-radius:999px;font-size:0.72em;font-weight:700;margin-right:0.4em;">진행 중</span>' : '';
      return '<li style="margin-bottom:0.25em;">' + badge +
        '<a class="internal-link" href="' + it.url + '">' + it.title + '</a>' +
        ' <span style="font-size:0.78em;color:var(--subtext);">(' + when + ' ' + it.kind + ')</span></li>';
    }).join('');
    document.getElementById('upcoming-events').innerHTML = html || '<li>표시할 일정이 없습니다.</li>';
  });
})();
</script>

