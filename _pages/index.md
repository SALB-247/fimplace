---
layout: page
title: Home
og_title: Fimplace | 르세라핌 장소 아카이브
description: 르세라핌 멤버들이 다녀간 카페·음식점·촬영지·팝업을 지도와 노트로 기록하는 팬 아카이브. 국가·지역·멤버별로 장소를 찾고 관련 게시물을 확인하세요.
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

<script>
// 홈에서 쓰는 JSON 은 한 번만 받아 공유한다 (모음 카드 + 최근 일정)
window.FimJson = function (name) {
  window.__fimJson = window.__fimJson || {};
  if (!window.__fimJson[name]) {
    window.__fimJson[name] = fetch('{{ site.baseurl }}/' + name)
      .then(function (r) { return r.json(); }).catch(function () { return null; });
  }
  return window.__fimJson[name];
};
</script>
<!-- 주요 모음 / 컬렉션 — 목록은 _data/hub_menu.yml 한 곳에서 온다 (2026-09-22).
     · 라벨: 한국어는 템플릿 원문, 영어는 노트의 title_en(+en_url), 일본어는 _data/i18n_ja.yml 의 hubs:
     · '주요 모음'(투어·이벤트)은 마지막 공연·이벤트가 끝나면 스크립트가 감춘다. 다 끝나면 섹션째 사라진다. -->
<style>
  .fim-hubs { display:grid; grid-template-columns:repeat(auto-fit, minmax(230px, 1fr));
              gap:0.5em; margin:0.5em 0 1.4em; }
  .fim-hubs a { display:flex; align-items:center; gap:0.6em; padding:0.7em 0.9em;
                border:1px solid var(--border); border-radius:10px; background:var(--box-bg);
                color:var(--text); text-decoration:none; line-height:1.3; font-weight:600;
                transition:border-color .12s, background .12s; }
  .fim-hubs a:hover { background:var(--link-hover); border-color:var(--primary); }
  .fim-hubs a::after { content:none !important; }   /* 사이트 공통 링크 ↗ 끄기 */
  .fim-hubs .ico { font-size:1.3em; line-height:1; flex:0 0 auto; }
  .fim-hubs .ttl { min-width:0; word-break:keep-all; overflow-wrap:anywhere; }
  .fim-hubs a.primary { border-color:var(--primary); background:var(--input-bg); }
  /* display:flex 가 UA 의 [hidden]{display:none} 보다 우선순위가 높아 끝난 카드가 계속 보였다 (2026-09-22) */
  .fim-hubs a[hidden] { display:none !important; }
</style>

<section id="home-highlight" hidden>
<strong data-i18n="home_highlighted">주요 모음</strong>
<div class="fim-hubs">
{%- assign cur_group = '' -%}
{%- for item in site.data.hub_menu -%}
  {%- if item.group -%}
    {%- assign cur_group = item.group -%}
  {%- elsif cur_group != '' and item.home != 'skip' -%}
    {%- assign hub = site.notes | where: "title", item.title | first -%}
    {%- if hub -%}
      {%- assign ja = site.data.i18n_ja.hubs[item.title] -%}
      {%- if cur_group == '투어' -%}{%- assign kind = 'tour' -%}{%- else -%}{%- assign kind = 'event' -%}{%- endif -%}
<a class="internal-link primary" href="{{ site.baseurl }}{{ hub.url }}" data-kind="{{ kind }}"
   {%- if kind == 'tour' %} data-tour-url="{{ hub.url }}"{% else %} data-tag="{{ hub.tags | first }}"{% endif -%}
   {%- if hub.en_url %} data-en-href="{{ site.baseurl }}{{ hub.en_url }}"{% endif -%}
   {%- if hub.title_en %} data-en="{{ hub.title_en | escape }}"{% endif -%}
   {%- if ja %} data-ja="{{ ja | escape }}"{% endif %}>
  <span class="ico">{{ item.icon | default: '🎫' }}</span><span class="ttl">{{ item.title }}</span></a>
    {%- endif -%}
  {%- endif -%}
{%- endfor -%}
</div>
</section>

<section id="home-collections">
<strong data-i18n="home_list">FimPlace 컬렉션</strong>
<div class="fim-hubs">
{%- for item in site.data.hub_menu -%}
  {%- if item.home == 'collection' -%}
    {%- assign hub = site.notes | where: "title", item.title | first -%}
    {%- if hub -%}
      {%- assign ja = site.data.i18n_ja.hubs[item.title] -%}
<a class="internal-link" href="{{ site.baseurl }}{{ hub.url }}"
   {%- if hub.en_url %} data-en-href="{{ site.baseurl }}{{ hub.en_url }}"{% endif -%}
   {%- if hub.title_en %} data-en="{{ hub.title_en | escape }}"{% endif -%}
   {%- if ja %} data-ja="{{ ja | escape }}"{% endif %}>
  <span class="ico">{{ item.icon | default: '📁' }}</span><span class="ttl">{{ item.title }}</span></a>
    {%- endif -%}
  {%- endif -%}
{%- endfor -%}
</div>
</section>

<script>
// 홈 모음 카드: ① 언어별 라벨·주소 ② 끝난 투어·이벤트는 감춘다
(function () {
  var LANG = window.FimLang || 'ko';

  function label(a) {
    var v = (LANG === 'ko') ? null : (a.getAttribute('data-' + LANG) || a.getAttribute('data-en'));
    if (v) { var t = a.querySelector('.ttl'); if (t) t.textContent = v; }
    var href = (LANG === 'ko') ? null : a.getAttribute('data-en-href');   // 영어판 허브는 /en/…
    if (href && LANG === 'en') a.setAttribute('href', href);
  }
  document.querySelectorAll('.fim-hubs a').forEach(label);

  var sec = document.getElementById('home-highlight');
  if (!sec) return;
  var cards = [].slice.call(sec.querySelectorAll('a[data-kind]'));
  if (!cards.length) return;

  function localToday() {
    var d = new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }
  // 공연장·행사장 현지 날짜로 판정 (서울에서 볼 때 미국 공연이 하루 먼저 끝나 보이던 문제와 같은 이유)
  function todayIn(tz) {
    if (tz && window.FimTime && window.FimTime.isValidTz(tz)) return window.FimTime.todayIn(tz);
    return localToday();
  }
  function reveal() { sec.hidden = false; }
  var done = false;
  var safety = setTimeout(function () { if (!done) reveal(); }, 4000);   // 데이터가 안 와도 섹션이 영영 안 보이는 일은 없게

  Promise.all([FimJson('tour_schedule.json'), FimJson('events.json')]).then(function (res) {
    var shows = (res[0] && res[0].shows) || [];
    var events = (res[1] && res[1].events) || [];
    // 투어: tour_url 별 마지막 공연 / 이벤트 모음: 같은 태그를 단 이벤트의 마지막 종료일
    var byTour = {}, byTag = {};
    function bump(box, key, end, tz) {
      if (!key || !end) return;
      if (!box[key] || end > box[key].end) box[key] = { end: end, tz: tz };
    }
    shows.forEach(function (sh) {
      if (sh.cancelled) return;
      bump(byTour, sh.tour_url, sh.end || sh.start, sh.time_zone);
    });
    events.forEach(function (e) {
      (e.tags || []).forEach(function (tg) { bump(byTag, tg, e.end || e.start, e.time_zone); });
    });

    var shown = 0;
    cards.forEach(function (a) {
      var kind = a.getAttribute('data-kind');
      var info = (kind === 'tour') ? byTour[a.getAttribute('data-tour-url')] : byTag[a.getAttribute('data-tag')];
      // 일정을 못 찾으면 감추지 않는다 (아직 일정이 안 올라온 새 투어)
      if (info && info.end < todayIn(info.tz)) { a.hidden = true; return; }
      shown++;
    });
    done = true;
    clearTimeout(safety);
    if (shown) reveal();          // 하나도 안 남으면 제목째 그대로 숨김
  }).catch(function () { done = true; clearTimeout(safety); reveal(); });
})();
</script>


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
    return (window.FimLang !== 'ko' && KIND[k]) ? window.FimT(KIND[k], k) : k;
  }
  var today = now.getTime();
  // 공연·이벤트는 그 장소의 현지 오늘로 판정한다 (서울에서 볼 때 미국 공연이 하루 먼저 끝나 보이던 문제, 2026-09-22)
  function todayFor(tz) {
    if (window.FimTime && window.FimTime.isValidTz(tz)) return ms(window.FimTime.todayIn(tz, now)) || today;
    return today;
  }

  Promise.all([FimJson('places.json'), FimJson('tour_schedule.json'), FimJson('events.json')])
    .then(function (raw) {
    var res = [raw[0] || { places: [] }, raw[1] || { shows: [] }, raw[2] || { events: [] }];
    var items = [];
    var seen = {};   // url 기준 dedupe (places 와 events 에 같은 노트가 둘 다 있음)

    (res[0].places || []).forEach(function (p) {
      seen[p.url] = 1;
      var s = ms(p.start), e = ms(p.end);
      if (s !== null || e !== null) {
        // 이벤트(기간): 현지 오늘이 기간 안이면 diff 0, 밖이면 가까운 끝점까지 거리
        var a = (s !== null ? s : e), b = (e !== null ? e : s);
        var tp = todayFor(p.time_zone);
        var diff = tp < a ? a - tp : (tp > b ? tp - b : 0);
        items.push({ title: p.title, url: p.url, date: a, endDate: b, diff: diff, kind: '기간', evt: true, today: tp });
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
      var ts = todayFor(sh.time_zone);
      var diff = ts < s ? s - ts : (ts > e ? ts - e : 0);
      items.push({ title: (sh.flag || '') + ' ' + (window.FimTag ? FimTag(sh.city) : sh.city) + ' — ' + sh.venue,
                   url: sh.venue_url || sh.tour_url, date: s, endDate: e, diff: diff, kind: '공연', evt: true, today: ts });
    });

    // 지도에서 스킵된 노트(노선 광고 등)는 places 에 없음 → events 에서 보충 (url dedupe)
    (res[2].events || []).forEach(function (e) {
      if (seen[e.url]) return;
      var a = ms(e.start), b = ms(e.end) || a;
      if (a === null) return;
      var te = todayFor(e.time_zone);
      var diff = te < a ? a - te : (te > b ? te - b : 0);
      items.push({ title: e.title, url: e.url, date: a, endDate: b, diff: diff, kind: '기간', evt: true, today: te });
    });

    // 1) 절대값 정렬 → 15개 선정   2) 선정분을 날짜순 나열
    //  가중치 (성격이 반대라 분리):
    //   · 이벤트(생카·팝업·광고·공연): 예정이 곧 정보 → 미래 페널티 없음(×1), 끝나면 ×2 로 빠르게 밀어냄
    //   · 기록(방문·업로드): 과거가 본질 → 미래 ×3 (과거 중심 유지)
    function selKey(it) {
      var tt = it.today || today;
      if (it.evt) return it.diff * (it.endDate < tt ? 2 : 1);
      return it.diff * (it.date > tt ? 3 : 1);
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
      var tt = it.today || today;
      var live = it.evt && it.date <= tt && tt <= it.endDate + DAY - 1;
      var badge = live ? '<span style="display:inline-block;background:#c9184a;color:#fff;padding:0.05em 0.5em;border-radius:999px;font-size:0.72em;font-weight:700;margin-right:0.4em;">' +
        (window.FimLang !== 'ko' ? window.FimT('home_live', 'LIVE NOW') : '진행 중') +
        '</span>' : '';
      return '<li style="margin-bottom:0.25em;">' + badge +
        '<a class="internal-link" href="' + it.url + '">' + it.title + '</a>' +
        ' <span style="font-size:0.78em;color:var(--subtext);">(' + when + ' ' + kindLabel(it.kind) + ')</span></li>';
    }).join('');
    document.getElementById('upcoming-events').innerHTML = html || ('<li>' +
      (window.FimLang !== 'ko' ? window.FimT('home_no_events', '') : '표시할 일정이 없습니다.') + '</li>');
  });
})();
</script>

