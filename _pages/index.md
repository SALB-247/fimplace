---
layout: page
title: Home
id: home
permalink: /
---

# FimPlace 

🐯🌸🐍🦢🐥

<span data-i18n="home_intro">핌플레이스는 르세라핌 관련 장소를 기록하는 보관소입니다.</span>

<span data-i18n="home_contact">문의는 fim.hlight@gmail.com으로 부탁드립니다.</span>

<!-- font-size:0 = 링크 장식(↗)·공백 텍스트 노드가 이미지 아래 빈 줄을 만드는 것 방지 -->
<a href="{{ site.baseurl }}/2026-le-sserafim-tour-pureflow" style="display:block; position:relative; border-radius:12px; overflow:hidden; margin:1em 0 1.2em; width:100%; font-size:0; line-height:0;">
  <img src="assets/pureflow_banner.jpg" alt="2026 LE SSERAFIM TOUR 'PUREFLOW'" style="width:100%; display:block;">
  <span class="banner-cta" style="position:absolute; right:3%; bottom:8%; background:rgba(0,0,0,0.45); color:#fff; padding:0.35em 0.9em; border-radius:999px; font-size:13px; line-height:1.2; font-weight:700;" data-i18n="home_banner_cta">투어 일정 보기 →</span>
</a>
<style>
  /* 좁은 화면: CTA pill 이 PUREFLOW 타이틀을 가리므로 숨김 (배너 전체가 링크) */
  @media (max-width: 520px) { .banner-cta { display: none; } }
</style>

{% include home_map.html %}

<!-- 장소 찾기: 홈에서 제일 먼저 눌리길 바라는 세 갈래. 지도 바로 아래에 카드로 둔다. -->
<style>
  .fim-find { display:grid; grid-template-columns:repeat(auto-fit, minmax(190px, 1fr));
              gap:0.6em; margin:1.1em 0 1.6em; }
  .fim-find a { display:flex; align-items:flex-start; gap:0.6em; padding:0.85em 1em;
                border:1px solid var(--border); border-radius:10px; background:var(--box-bg);
                color:var(--text); text-decoration:none; line-height:1.35; transition:border-color .12s, background .12s; }
  .fim-find a:hover { background:var(--link-hover); border-color:var(--primary); }
  .fim-find a::after { content:none !important; }   /* 사이트 공통 링크 ↗ 끄기 */
  .fim-find .ico { font-size:1.45em; line-height:1; flex:0 0 auto; }
  .fim-find .ttl { font-weight:700; display:block; }
  .fim-find .sub { font-size:0.82em; color:var(--subtext); display:block; margin-top:0.15em; }
  .fim-find a.primary { border-color:var(--primary); background:var(--input-bg); }
</style>
<div class="fim-find">
  <a class="internal-link primary" href="{{ site.baseurl }}/map/">
    <span class="ico">🗺️</span><span>
      <span class="ttl" data-i18n="home_link_map">전체 지도 보기</span>
      <span class="sub" data-i18n="home_link_map_sub">모든 장소를 한눈에</span></span>
  </a>
  <a class="internal-link" href="{{ site.baseurl }}/search/">
    <span class="ico">🔍</span><span>
      <span class="ttl" data-i18n="home_link_search">장소 검색</span>
      <span class="sub" data-i18n="home_link_search_sub">이름·태그·멤버로 검색</span></span>
  </a>
  <a class="internal-link" href="{{ site.baseurl }}/tags/">
    <span class="ico">🏷️</span><span>
      <span class="ttl" data-i18n="home_link_tags">모든 태그</span>
      <span class="sub" data-i18n="home_link_tags_sub">카테고리 / 멤버별 인덱스</span></span>
  </a>
</div>

<strong data-i18n="home_highlighted">High-lighted list</strong>

## [[2026 LE SSERAFIM TOUR 'PUREFLOW']]

## [[Made My Night_오프라인 이벤트 모음]]


<strong data-i18n="home_list">Fimplace list</strong>

[[-자체 컨텐츠 촬영지]]

[[-외부 컨텐츠 촬영지]]

[[-SNS 장소]]


<strong data-i18n="home_recent">최근 일정 노트</strong>

<ul id="upcoming-events"><li style="color:var(--subtext);" data-i18n="home_loading">일정 불러오는 중...</li></ul>

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
  // 종류 라벨은 한국어 원문을 키로 쓰고 표시할 때만 갈아끼운다
  var KIND = { '기간': 'home_kind_period', '방문': 'home_kind_visit',
               '업로드': 'home_kind_upload', '공연': 'home_kind_show' };
  function kindLabel(k) {
    return (window.FimLang === 'en' && KIND[k]) ? window.FimT(KIND[k], k) : k;
  }
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
        items.push({ title: p.title, url: p.url, date: a, endDate: b, diff: diff, kind: '기간', evt: true });
        return;
      }
      // 방문 기록: 오늘과 가장 가까운 방문일 1개
      var vs = (p.visits || []).map(function (v) { return ms(v.date); }).filter(function (x) { return x !== null; });
      if (vs.length) {
        var best = vs.reduce(function (acc, x) { return Math.abs(x - today) < Math.abs(acc - today) ? x : acc; }, vs[0]);
        items.push({ title: p.title, url: p.url, date: best, endDate: best, diff: Math.abs(best - today), kind: '방문', evt: false });
        return;
      }
      // 컨텐츠 게시일 (영상 업로드 / IG 게시)
      var d0 = ms(p.date);
      if (d0 !== null) {
        items.push({ title: p.title, url: p.url, date: d0, endDate: d0, diff: Math.abs(d0 - today), kind: '업로드', evt: false });
      }
    });

    (res[1].shows || []).forEach(function (sh) {
      if (sh.cancelled || !sh.venue) return;
      var s = ms(sh.start), e = ms(sh.end) || s;
      if (s === null) return;
      var diff = today < s ? s - today : (today > e ? today - e : 0);
      items.push({ title: (sh.flag || '') + ' ' + (window.FimTag ? FimTag(sh.city) : sh.city) + ' — ' + sh.venue,
                   url: sh.venue_url || sh.tour_url, date: s, endDate: e, diff: diff, kind: '공연', evt: true });
    });

    // 지도에서 스킵된 노트(노선 광고 등)는 places 에 없음 → events 에서 보충 (url dedupe)
    (res[2].events || []).forEach(function (e) {
      if (seen[e.url]) return;
      var a = ms(e.start), b = ms(e.end) || a;
      if (a === null) return;
      var diff = today < a ? a - today : (today > b ? today - b : 0);
      items.push({ title: e.title, url: e.url, date: a, endDate: b, diff: diff, kind: '기간', evt: true });
    });

    // 1) 절대값 정렬 → 15개 선정   2) 선정분을 날짜순 나열
    //  가중치 (성격이 반대라 분리):
    //   · 이벤트(생카·팝업·광고·공연): 예정이 곧 정보 → 미래 페널티 없음(×1), 끝나면 ×2 로 빠르게 밀어냄
    //   · 기록(방문·업로드): 과거가 본질 → 미래 ×3 (과거 중심 유지)
    function selKey(it) {
      if (it.evt) return it.diff * (it.endDate < today ? 2 : 1);
      return it.diff * (it.date > today ? 3 : 1);
    }
    items.sort(function (a, b) { return selKey(a) - selKey(b) || a.date - b.date; });
    var picked = items.slice(0, 15);
    picked.sort(function (a, b) { return a.date - b.date || a.title.localeCompare(b.title); });

    function ymd(msv) {
      var x = new Date(msv);
      return x.getFullYear() + '-' + String(x.getMonth() + 1).padStart(2, '0') + '-' + String(x.getDate()).padStart(2, '0');
    }
    var html = picked.map(function (it) {
      var when = ymd(it.date) + (it.endDate !== it.date ? ' ~ ' + ymd(it.endDate) : '');
      var live = it.evt && it.date <= today && today <= it.endDate + DAY - 1;
      var badge = live ? '<span style="display:inline-block;background:#c9184a;color:#fff;padding:0.05em 0.5em;border-radius:999px;font-size:0.72em;font-weight:700;margin-right:0.4em;">' +
        (window.FimLang === 'en' ? window.FimT('home_live', 'LIVE NOW') : '진행 중') +
        '</span>' : '';
      return '<li style="margin-bottom:0.25em;">' + badge +
        '<a class="internal-link" href="' + it.url + '">' + it.title + '</a>' +
        ' <span style="font-size:0.78em;color:var(--subtext);">(' + when + ' ' + kindLabel(it.kind) + ')</span></li>';
    }).join('');
    document.getElementById('upcoming-events').innerHTML = html || ('<li>' +
      (window.FimLang === 'en' ? window.FimT('home_no_events', '') : '표시할 일정이 없습니다.') + '</li>');
  });
})();
</script>

