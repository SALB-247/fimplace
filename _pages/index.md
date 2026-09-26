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

<!-- 두 줄 행 (2026-09-26 사용자 선택 'A안'): 1줄 = 진행 중 · 제목 · 날짜 / 2줄 = 분류 칩 · 멤버 칩 · 콘텐츠 제목(또는 지역)
     멤버 칩은 노트 페이지와 같은 .member-chip 색. 같은 이벤트를 매장 3곳 이상이 함께 하면 한 줄로 묶는다.
     서비스 칩의 로고(.ki)는 사이트 공통 img 규칙(display:block · margin auto · max-height)을 덮어써야 글자와 한 줄에 선다. -->
<style>
  #upcoming-events { list-style:none; padding-left:0; margin:0.4em 0 1.4em; }
  #upcoming-events > li { padding:0.55em 0; border-bottom:1px solid var(--border); }
  #upcoming-events > li:last-child { border-bottom:none; }
  #upcoming-events .l1 { display:flex; flex-wrap:wrap; align-items:baseline; gap:0.15em 0.6em; }
  #upcoming-events .ttl { min-width:0; overflow-wrap:anywhere; }
  #upcoming-events .when { margin-left:auto; font-size:0.78em; color:var(--subtext); white-space:nowrap; }
  #upcoming-events .live { display:inline-block; background:#c9184a; color:#fff; padding:0.05em 0.5em; border-radius:999px;
                           font-size:0.72em; font-weight:700; margin-right:0.4em; vertical-align:0.1em; }
  #upcoming-events .l2 { display:flex; flex-wrap:wrap; align-items:center; gap:0.3em 0.35em; margin-top:0.3em; }
  #upcoming-events .kc { display:inline-block; padding:0.1em 0.6em; border:1px solid var(--border); border-radius:999px;
                         background:var(--box-bg); color:var(--subtext); font-size:0.74em; line-height:1.5; white-space:nowrap; }
  #upcoming-events .kc .ki { display:inline-block; width:1.1em; height:1.1em; vertical-align:-0.2em; margin:0 0.3em 0 0; }
  #upcoming-events .kc img.ki { max-height:none; border-radius:0.25em; }
  #upcoming-events .member-chip { font-size:0.74em; padding:0.1em 0.6em; line-height:1.5; }
  #upcoming-events .sub { flex:1 1 12em; min-width:0; font-size:0.8em; color:var(--subtext);
                          overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  #upcoming-events .sub.wrap { white-space:normal; }
</style>
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
  var today = now.getTime();
  var LANG = window.FimLang || 'ko';
  function T(key, ko) { return LANG !== 'ko' ? window.FimT(key, ko) : ko; }
  function tagLabel(t) { return LANG !== 'ko' && window.FimTag ? window.FimTag(t) : String(t).replace(/_/g, ' '); }
  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }
  // 공연·이벤트는 그 장소의 현지 오늘로 판정한다 (서울에서 볼 때 미국 공연이 하루 먼저 끝나 보이던 문제, 2026-09-22)
  function todayFor(tz) {
    if (window.FimTime && window.FimTime.isValidTz(tz)) return ms(window.FimTime.todayIn(tz, now)) || today;
    return today;
  }

  // 멤버: full = .member-chip 색 클래스, tag = 번역 사전 키. 칩은 항상 노트의 멤버 태그 전부 (2026-09-26 사용자 지시)
  var MEMBERS = [
    { full: '사쿠라', tag: '꾸라', ko: '사쿠라' },
    { full: '김채원', tag: '채원', ko: '채원' },
    { full: '허윤진', tag: '윤진', ko: '윤진' },
    { full: '카즈하', tag: '즈하', ko: '즈하' },
    { full: '홍은채', tag: '은채', ko: '은채' }
  ];
  // 메모 줄의 플랫폼 — 앞에서부터 먼저 맞는 것 ('허윤진 위버스 DM' 은 DM)
  var PLATFORMS = [
    { re: /인스스|스토리/, key: 'home_chip_story', ko: '인스타 스토리', logo: 'ig' },
    { re: /DM/, tag: 'DM', logo: 'wv' },
    { re: /인스타|공스타/, tag: '인스타', logo: 'ig' },
    { re: /위버스\s*라이브/, tag: '위버스라이브', logo: 'wv' },
    { re: /위버스/, tag: '위버스', logo: 'wv' },
    { re: /틱톡/, tag: '틱톡', logo: 'tt' },
    { re: /공트|공식\s*(?:트위터|X)/, tag: '공트', logo: 'x' },
    { re: /멤트|트위터/, tag: '멤트', logo: 'x' }
  ];
  var PF_IG = PLATFORMS.filter(function (x) { return x.tag === '인스타'; })[0];
  // 이벤트 유형 — _plugins/event_period_generator.rb 의 infer_type 과 같은 규칙
  var TYPES = {
    '생일카페': { key: 'home_chip_bdcafe', ico: '🎂' },
    '광고': { key: 'home_chip_ad', ico: '📢' },
    '팝업': { key: 'home_chip_popup', ico: '🏪' },
    '투어이벤트': { key: 'home_chip_tourevent', ico: '🎫' },
    '이벤트': { key: 'home_chip_event', ico: '🎁' }
  };
  function eventType(tags) {
    var t = (tags || []).join(' ');
    if (t.indexOf('생일카페') >= 0) return '생일카페';
    if (t.indexOf('광고') >= 0) return '광고';
    if (t.indexOf('팝업스토어') >= 0) return '팝업';
    if (/TOUR|PUREFLOW|FEARNADA/.test(t)) return '투어이벤트';
    return '이벤트';
  }
  // 앨범 이벤트 태그 → 칩 이름: Made_My_Night_이벤트 → "Made My Night" (앨범명은 번역하지 않는다)
  function albumName(tags) {
    for (var i = 0; i < (tags || []).length; i++) {
      var m = /^(.+)_이벤트$/.exec(tags[i]);
      if (m && m[1].indexOf('생일') < 0) return m[1].replace(/_/g, ' ').replace(/\bpt(\d)/i, 'pt.$1');   // PUREFLOW_pt1 → PUREFLOW pt.1
    }
    return '';
  }
  // 비교용: 공백·밑줄·점 무시 ('PUREFLOW pt.1' = 'PUREFLOW_pt1')
  function norm(s) { return String(s || '').toLowerCase().replace(/[\s_.]/g, ''); }
  // 제목 정리: 파일명식 날짜 접미(_250317-250319)는 오른쪽 날짜와 겹치고, "(Made My Night)" 는 칩으로 옮긴다
  function cleanTitle(t, album) {
    t = String(t || '').replace(/_\d{6}(?:-\d{4,6})?$/, '');
    // 앨범명 괄호: 짝이 안 맞거나('애플뮤직 (PUREFLOW_pt1') 오타('PURELFOW')여도 앨범명 끝말(pt1·night)이 들어 있으면 뺀다
    var m = /\s*\(([^()]*)\)?\s*$/.exec(t);
    var tail = album ? norm(album.split(/\s+/).pop()) : '';
    if (album && m && m.index > 0 && (norm(m[1]).indexOf(norm(album)) === 0 || (tail.length >= 3 && norm(m[1]).indexOf(tail) >= 0))) t = t.slice(0, m.index);
    return t.trim();
  }
  function nameOf(p) {
    if (LANG === 'ja' && p.name_ja) return p.name_ja;
    if (LANG !== 'ko' && p.name_en) return p.name_en;
    return p.title;
  }
  // 이벤트 모음의 소제목(공식 이벤트 이름) — 제목과 겹치면 겹치지 않는 부분만
  //   "Weverse Lucky Store (LUCKY DRAW 1차)" → "LUCKY DRAW 1차" / '팝업 스토어' 같은 분류 소제목은 쓰지 않는다
  var GENERIC_EVENT = { '팝업스토어': 1, 'popupstore': 1 };
  function eventName(src) { return src && src.event ? ((LANG !== 'ko' && src.event_en) || src.event) : ''; }
  function eventNote(ev, titles) {
    if (!ev || GENERIC_EVENT[norm(ev)]) return '';
    for (var i = 0; i < titles.length; i++) {
      var t = titles[i] || '';
      if (!t) continue;
      if (norm(t).indexOf(norm(ev)) >= 0) return '';
      if (ev.toLowerCase().indexOf(t.toLowerCase()) === 0) return ev.slice(t.length).replace(/^[\s(]+|[\s)]+$/g, '');
    }
    return ev;
  }

  // 서비스 로고 (2026-09-26 사용자 제안 — 이모지 대신 실제 로고). 경로는 Simple Icons(CC0), 위버스는 공식 앱 아이콘(48px).
  //   X·틱톡은 검은 로고라 글자색을 따른다 (다크 모드에서 밝게). 칩 글자가 서비스 이름이라 로고는 장식(aria-hidden)
  var LOGO = {
    ig: { fill: '#E4405F', d: 'M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077' },
    x: { d: 'M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z' },
    tt: { d: 'M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z' },
    yt: { fill: '#FF0000', d: 'M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z' },
    wv: { img: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAJCElEQVR42tWaa3CcVRnHf+fybjYJCU2aNr2lTbYNkXIrU6uAl2lFqeAwCMh0sA6XysDAh46IRUW5WETFUT+IfFEUK1ZQwOqM41AKLSMoA1gujWPLNCkmaZNQSNuUJtnsvuc8fnjf3e5mN01bBtqcmTPZ7D777v95zv+5nXMUxcMALno571yFWQmyDGQ+qFP5UIcMguoENgt+PXS9XooRVCn4+U0Kfy+oFaCSIETzRAwVTxkB+aOg7oZd3YVKqELwhublHr0OdGP8uSt4ivqQ0UvBNDHEvRp/raPrqRxmVQD+Io/+GxCAD0FZTqohIWgLZDXyBcdbmwCjAA1zZiqCbaDqQVys1Mk4HCgDsk8Iz4Kefg14RfAD0PWR5U9a8DHVfQi6XmF/FGEndZZCtsbANZNjeMAJfFQr/HWggxMYao7TwXWgkOs08JkYu5pECqgIs1qmgVSsgJ5ECug4wqY0qFom7VC1RxXrlVIFE0TAe4/IiXebIyqgtUYpRehCkDQQxr6ugSqMtnjvyypsTCkjvZcSea01Whe7n4jgnH+/CiicHwZGCYKpLFx4Oi3NTVRXV7J37wDPv/AK6fRBtKpCxBd9z0uIDw+VeWYFisqCgKdwfgjnsyWwFNVHFRjteJTxkuX00z/CqlUruPTSz9HWliqSaW/fwZVX3MjOjk6MrsR7n/9e4/RG1tx+J9YYBMF7wRjNX/+yiS3PbcHo6iit+iEuu+xSLrl4KaGLCkxrDP/811Ye+d2jaF2J9zJRPGqRwmnNfIFG+dQnvySZTFYKRxg6CcMw//7LL78hgZ0rWue+u0CgQT6//FopN25f80OBKRLYVgnsAoF6WbfuyRK5l156TaBRjJ4vY/GNnbocTyFBR0cXg4Pvkc2GZLMhIpEVjTEEgcU5x5IlZ7N48RK8H0Zrg1JRkpw7dxZhGJJOjxKGjtHRDGEYsn17B2ALnF9x6NAQYehIpzNkMlnC0DF1ah3Jiik471BKTRRPKXGgwCbp69/Jww8/ThBYgsCWfZCIkErNBkK0zuVCoSXVhLUWaw3WGhKJAGst/f3vxBWLIHHurKqqLJIzRtPS0kRbWwql0iUOPqEC0Sp4lKriV798jNHRDIODh8qSTykVf6YRIbasoaWlKS8jIiilGBlJs3fvwJgV0NTXT4n9Li43nUdrzeVXLEdkFKX08SmAJNnZsYuPf+yLtLYu4b77Hox/IHI2YzTee7q79+RBRSGygnnzZueDQW7s2zfIu+/uB0yUR8QDAdOm1Rc1hzmL33DDCmpOmYH3GbTWx6ZArl7SyvDGtnbeeWcPHR3/i2lDPjIMDBygu6cv6oEAL47KZC2zZjUejmax7Ntvv8vwyCGUMnkjBUEVDQ31RSugtcY5x+zZM7j/x9/B+QOIeNQ4pdoR10dEqEhUoVSCRecsHNPpQVfXHg4OHkDnmzdHQ8OUvFUjUJFsb28/ImmMNnnZurpaGhsbSlbLGINzjptvXsldd96NDRzjMWnCAs45j4hhQWtziVU7O7sQhuOMDZChuXkOlZXJPPdzfO/p7gMcSoHSCsgyt2kWNTXVedmizsUYnPN8b+2tLFu6FOffwxhzbAooFXHemhpSqbkFlopA7djRGYNSsbNlueATi4t8JTd6evriPkShlUKpDGee2YZSqqRscM7hvccYzf79g7S3vwlUjMn4R6WAQsgyfXoDc+fOLCrsAHZs74wfkXPgJJdcvKyIErm/PT29edkoYimWLjuvfN9oTFSDhY7nnnuJ3r5OrEmWzcoTKBBZtbl5DtXVVXk65KJCd3dvVLcohTBC22kLOe/8c+OkZ8Yo0J9vt71kqTllBsuXfzof0XLP7uvby53f/QlDQ8NYa9iwYSMoYbx8NiGFICSVajocXmNQYRiyf/8BtA4wxuD9EGtuv5FEIiiiRE7ZgwffQ2tDECTw/gDXXHMlM2ZMwzmXp5GI8OKLr/L9++7ggvOv5IEH1vH0xn+AVI5bndqJd8Y806dPzYfQws+Gh9N4n2YkPcgVl69k1aqr8N5jrSmKZJHje7wfZXikl9bWRay991a8l3yiylHz1w89jjH1tP/nv6xefRtwCopg3N7jqNrIimQiH0JzYKw1XH/9VaRSs1m9+us8+tjPy+xWHs4ZX71hBfPmNbFixZfZtOkP+QysdWR9YzTbtu1g0zPPIlKF0QkCW4dWZoJmi5Zx61VrDdlwH7fcfAu/eHAtzhVbFyCTyZJIBHlrj43phSOdHiWZrChaGRFwLsRay2cv/ArPbn4aa04tiWLHkYlzgCzbt+9CKVW2c8px3nspoIuULLmIkExWxFQ6nCPCMIu1lp/+5CGe3fzUMYGfUIHohyp5+ZWt7N7dD0ShrajxyYMVtNbc+rW1PPHE31FKkclkikNyQcIKw8h5gyDg4d88zjfW3IU1tWVb1GNqaEobnKhJufaa2/INh3NOwtCJc66oEbnn7p8J1MgZCy+UgYEDJY3QWPnh4RG549v3C8wUrZtFq9SEDczYaRR190xEI6Mree31rfT3D3DOOWcwZUotWkdR49DQMM9sep4bb/omv133CIlgGv1v97Bx4wu0trYwZ85MgsDmNwi883R2dvH79Ru46aZv8ecNT6J1DYg6rl2OIzpx8e6BwvmD1NTM4NxFC2loqOPQ0Ahv7uikq7sDEKypxTkXVZR+GFCcdlobC+Y3U1mZZGhomJ6eXjo6uhjNDAAJrKk+Js4ftwK5FB+6DJDO1zWQwOhkXDcVJzARwUsayBSEWAtUEFhbdpvlA1Ug54xRNFIxxfwRdw5y1CmkZG5+4Btb4/mEc0f/4+/XwkezSXpw8u6NykENaldMBz+JkPsY8y4NsiX+Z5IdcCiAzQpazlbw78l5xKQWa3hrG/AYaB0dZZ70I4yw8ijsao+PWZtmKGz75DpmzZ4Nu/t0FNB7egW5GsjGAifhSkgYYSMbYd29h/iN+Cj/QAfUvqJQF4GtiX3ajWnPTsRVAx+xxGrwewW/Aro2Hr5hcFjYwOBOqP+TwteBagOdOEH3JGKDKRXzPQ1+vTB6Nex+tdxlj3LXbRYp9EqiY9gTeN1GbRHceuh6rdx1m/8DJdjF/9wmo6AAAAAASUVORK5CYII=' }
  };
  function logo(k) {
    var o = LOGO[k];
    if (!o) return '';
    if (o.img) return '<img class="ki" src="' + o.img + '" alt="">';
    return '<svg class="ki" viewBox="0 0 24 24" aria-hidden="true"><path fill="' + (o.fill || 'currentColor') + '" d="' + o.d + '"/></svg>';
  }
  function chip(text, ico) { return '<span class="kc">' + (ico ? ico + ' ' : '') + esc(text) + '</span>'; }
  function logoChip(text, k) { return '<span class="kc">' + logo(k) + esc(text) + '</span>'; }
  function typeChip(type) { var d = TYPES[type] || TYPES['이벤트']; return chip(T(d.key, type), d.ico); }
  function membersFromNames(names) {
    return MEMBERS.filter(function (m) { return (names || []).indexOf(m.full) >= 0; });
  }
  // 멤버 태그가 없거나 다섯 명이면 칩을 쓰지 않는다 (노트 규칙: 태그 없음 = 전원)
  function memberChips(list) {
    if (!list.length || list.length >= MEMBERS.length) return '';
    return list.map(function (m) {
      return '<span class="member-chip member-' + m.full + '">' + esc(LANG !== 'ko' ? tagLabel(m.tag) : m.ko) + '</span>';
    }).join('');
  }
  function platformOf(label) {
    for (var i = 0; i < PLATFORMS.length; i++) if (PLATFORMS[i].re.test(label || '')) return PLATFORMS[i];
    return null;
  }
  // 메모 줄로 플랫폼을 못 정하면 노트의 SNS 태그(인스타·DM·위버스·틱톡·공트·멤트)에서
  function platformTag(tags) {
    for (var i = 0; i < PLATFORMS.length; i++) if (PLATFORMS[i].tag && (tags || []).indexOf(PLATFORMS[i].tag) >= 0) return PLATFORMS[i];
    return null;
  }
  function platformChip(pf) { return logoChip(pf.key ? T(pf.key, pf.ko) : tagLabel(pf.tag), pf.logo); }
  // 유튜브 임베드가 있는 노트 = 방문 기록에 '영상 업로드'(임베드 영상의 업로드일)가 있다
  function hasYT(p) { return (p.visits || []).some(function (v) { return v.label === '영상 업로드'; }); }
  function sub(text, wrap) { return text ? '<span class="sub' + (wrap ? ' wrap' : '') + '">' + text + '</span>' : ''; }

  Promise.all([FimJson('places.json'), FimJson('tour_schedule.json'), FimJson('events.json')])
    .then(function (raw) {
    var P = raw[0] || { places: [] }, S = raw[1] || { shows: [] }, E = raw[2] || { events: [] };
    var cat = P.category_tags || {};
    function tagSet(names) {
      var o = {};
      names.forEach(function (c) { (cat[c] || []).forEach(function (t) { o[t] = 1; }); });
      return o;
    }
    var AREA = tagSet(['서울 (구별)', '경기', '광역 지역', '일본 (지역)', '해외 (지역)']);
    var SERIES = tagSet(['컨텐츠 (자체)', '컨텐츠 (외부)']);
    var EVENT_TAGS = tagSet(['이벤트/광고', '활동별']);
    function areaOf(tags) {
      for (var i = 0; i < (tags || []).length; i++) if (AREA[tags[i]]) return tagLabel(tags[i]);
      return '';
    }
    // 시리즈 칩: 가장 구체적인 시리즈 태그 (자체컨텐츠_촬영지·유튜브 같은 큰 분류는 다른 게 없을 때만)
    function seriesTag(tags) {
      var list = (tags || []).filter(function (t) { return SERIES[t]; });
      return list.filter(function (t) { return t !== '자체컨텐츠_촬영지' && t !== '유튜브'; })[0] || list[0] || '';
    }
    // 시리즈 칩 로고: 위버스 라이브 → 위버스, 유튜브 임베드가 있는 노트 → 유튜브, 그 밖(TV 방송 등) → 🎬
    function seriesChip(tag, p) {
      if (tag === '위버스라이브') return logoChip(tagLabel(tag), 'wv');
      return hasYT(p) ? logoChip(tagLabel(tag), 'yt') : chip(tagLabel(tag), '🎬');
    }

    var items = [];
    var seen = {};   // url 기준 dedupe (places 와 events 에 같은 노트가 둘 다 있음)

    (P.places || []).forEach(function (p) {
      seen[p.url] = 1;
      var s = ms(p.start), e = ms(p.end);
      if (s !== null || e !== null) {
        // 이벤트(기간): 현지 오늘이 기간 안이면 diff 0, 밖이면 가까운 끝점까지 거리
        var a = (s !== null ? s : e), b = (e !== null ? e : s);
        var tp = todayFor(p.time_zone);
        var diff = tp < a ? a - tp : (tp > b ? tp - b : 0);
        // 메모 줄 라벨 = 같은 이벤트인지 가르는 열쇠 (매장마다 같은 메모 줄을 쓴다)
        var lab = (p.visits || []).map(function (v) { return v.label; })
          .filter(function (l) { return l && l !== 'IG 게시' && l !== '영상 업로드'; })[0] || '';
        items.push({ kind: 'period', p: p, url: p.url, date: a, endDate: b, diff: diff, evt: true, today: tp, label: lab });
        return;
      }
      // 방문 기록: 오늘과 가장 가까운 방문일 1개 (그 날짜의 라벨로 칩을 만든다)
      var best = null;
      (p.visits || []).forEach(function (v) {
        var d = ms(v.date);
        if (d !== null && (!best || Math.abs(d - today) < Math.abs(best.d - today))) best = { d: d, label: v.label };
      });
      if (best) {
        items.push({ kind: 'visit', p: p, url: p.url, date: best.d, endDate: best.d, diff: Math.abs(best.d - today), evt: false, label: best.label });
        return;
      }
      // 컨텐츠 게시일 (영상 업로드 / IG 게시)
      var d0 = ms(p.date);
      if (d0 !== null) {
        items.push({ kind: 'visit', p: p, url: p.url, date: d0, endDate: d0, diff: Math.abs(d0 - today), evt: false, label: '' });
      }
    });

    (S.shows || []).forEach(function (sh) {
      if (sh.cancelled || !sh.venue) return;
      var s = ms(sh.start), e = ms(sh.end) || s;
      if (s === null) return;
      var ts = todayFor(sh.time_zone);
      var diff = ts < s ? s - ts : (ts > e ? ts - e : 0);
      items.push({ kind: 'show', sh: sh, url: sh.venue_url || sh.tour_url, date: s, endDate: e, diff: diff, evt: true, today: ts });
    });

    // 지도에서 스킵된 노트(노선 광고 등)는 places 에 없음 → events 에서 보충 (url dedupe)
    (E.events || []).forEach(function (ev) {
      if (seen[ev.url]) return;
      var a = ms(ev.start), b = ms(ev.end) || a;
      if (a === null) return;
      var te = todayFor(ev.time_zone);
      var diff = te < a ? a - te : (te > b ? te - b : 0);
      items.push({ kind: 'period', ev: ev, url: ev.url, date: a, endDate: b, diff: diff, evt: true, today: te, label: '' });
    });

    // 같은 이벤트를 매장 여러 곳이 함께 하면 한 줄로 (2026-09-26 사용자 지시 — 카시나 3곳·세븐일레븐 4곳).
    //   열쇠 = 이벤트 모음의 '# 소제목'(event, _plugins/hub_events.rb) → 모음에 없으면 이벤트 태그 + 메모 줄 라벨.
    //   3곳 이상일 때만 묶고, 기간은 가장 이른 시작 ~ 가장 늦은 끝. 제목은 그 이벤트 이름 ("카시나 3곳" 이 아니라).
    var byKey = {};
    items.forEach(function (it) {
      if (it.kind !== 'period') return;
      var s0 = it.p || it.ev;
      // 다른 앨범 모음에 같은 소제목('팝업 스토어')이 있어도 섞이지 않게 앨범 이벤트 이름도 열쇠에 넣는다
      var key = s0.event ? 'E|' + albumName(s0.tags) + '|' + s0.event
        : (it.p && it.label ? 'L|' + it.p.tags.filter(function (t) { return EVENT_TAGS[t]; }).sort().join(',') + '|' + it.label : '');
      if (key) (byKey[key] = byKey[key] || []).push(it);
    });
    Object.keys(byKey).forEach(function (k) {
      var g = byKey[k];
      if (g.length < 3) return;
      g.sort(function (x, y) { return (x.p || x.ev).title.localeCompare((y.p || y.ev).title); });
      var a = Math.min.apply(null, g.map(function (x) { return x.date; }));
      var b = Math.max.apply(null, g.map(function (x) { return x.endDate; }));
      var tp = g[0].today || today;
      var diff = tp < a ? a - tp : (tp > b ? tp - b : 0);
      g.forEach(function (x) { x.merged = true; });
      items.push({ kind: 'group', list: g, p: g[0].p || g[0].ev, url: g[0].url, date: a, endDate: b, diff: diff, evt: true, today: tp, label: g[0].label });
    });
    items = items.filter(function (it) { return !it.merged; });

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
    function sortTitle(it) { return it.p ? it.p.title : (it.ev ? it.ev.title : (it.sh ? it.sh.venue : '')); }
    picked.sort(function (a, b) { return a.date - b.date || sortTitle(a).localeCompare(sortTitle(b)); });

    // 날짜: 올해면 월-일만
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    function md(msv) {
      var x = new Date(msv);
      var s = pad(x.getMonth() + 1) + '-' + pad(x.getDate());
      return x.getFullYear() === now.getFullYear() ? s : x.getFullYear() + '-' + s;
    }
    function link(url, text) { return '<a class="internal-link" href="' + esc(url) + '">' + esc(text) + '</a>'; }
    // 묶음 제목 링크: 그 이벤트의 모음 페이지(홈 '주요 모음' 카드) → 없으면 첫 매장
    function hubHref(tags) {
      var cards = document.querySelectorAll('#home-highlight a[data-kind="event"]');
      for (var i = 0; i < cards.length; i++) {
        if ((tags || []).indexOf(cards[i].getAttribute('data-tag')) >= 0) {
          return (LANG !== 'ko' && cards[i].getAttribute('data-en-href')) || cards[i].getAttribute('href');
        }
      }
      return null;
    }
    function commonPrefix(names) {
      var words = names.map(function (n) { return n.split(/\s+/); });
      var out = [];
      for (var i = 0; i < words[0].length; i++) {
        var w = words[0][i];
        if (words.some(function (ws) { return ws[i] !== w; })) break;
        out.push(w);
      }
      return out.length < words[0].length ? out.join(' ') : '';
    }

    function render(it) {
      var head = '', chips = '', rest = '';
      if (it.kind === 'show') {
        var sh = it.sh;
        var tour = (/'([^']+)'/.exec(sh.tour || '') || [])[1] || sh.tour || '';
        head = link(it.url, tagLabel(sh.city) + ' — ' + sh.venue);   // 국기 이모지는 윈도우에서 'US' 글자로 보여 뺐다
        chips = chip(T('home_chip_show', '공연'), '🎤') + (tour ? chip(tour) : '');
        if (sh.start_time) rest = sub(esc(LANG !== 'ko' ? window.FimFmt(window.FimT('home_local_time', ''), [sh.start_time]) : '현지 ' + sh.start_time));
      } else if (it.kind === 'group') {
        var album = albumName(it.p.tags);
        // 제목 = 이벤트 모음의 소제목(공식 이벤트 이름) → 모음에 없는 이벤트는 메모 줄 라벨
        head = link(hubHref(it.p.tags) || it.url, eventName(it.p) || it.label);
        chips = typeChip(eventType(it.p.tags)) + (album ? chip(album) : '');
        // 매장 이름: 공통 앞말(카시나·세븐일레븐)은 빼고 지점만. 영어·일본어는 매장마다 있는 현지 이름(영어판 모음 라벨 → 영어 이름 → 원제)
        var names = it.list.map(function (x) {
          var o = x.p || x.ev;
          if (LANG === 'ja' && o.name_ja) return o.name_ja;   // 같음·다름 비교를 한 줄에 같이 두면 markdown-highlighter 가 mark 태그로 깬다 (2026-09-26)
          return (LANG !== 'ko' && (o.label_en || o.name_en)) || o.title;
        });
        names = names.map(function (nm) { return cleanTitle(nm, album); });
        var brand = commonPrefix(names);
        var n = it.list.length;
        var shown = it.list.slice(0, n > 5 ? 4 : 5).map(function (x, i) {
          var nm = brand ? names[i].slice(brand.length).trim() : names[i];
          return link(x.url, nm || names[i]);
        });
        if (n > 5) shown.push(esc(LANG !== 'ko' ? window.FimFmt(window.FimT('home_more', ''), [n - 4]) : '외 ' + (n - 4) + '곳'));
        rest = sub(shown.join(' · '), true);
      } else if (it.kind === 'period') {
        var src = it.p || it.ev;
        var tags = src.tags || [];
        var alb = albumName(tags);
        var t0 = cleanTitle(it.p ? it.p.title : src.title, alb);
        head = link(it.url, it.p ? cleanTitle(nameOf(it.p), alb) : t0);
        chips = typeChip(it.ev ? (TYPES[it.ev.type] ? it.ev.type : eventType(tags)) : eventType(tags)) +
                (alb ? chip(alb) : '') + memberChips(membersFromNames(src.members));
        // 둘째 줄 설명: ① 이벤트 모음의 소제목이 제목과 다른 정보를 주면 그것 (WITHMUU SPECIAL STORE · LUCKY DRAW 2차)
        //              ② 메모 줄 라벨이 제목과 다르면 그것  ③ 지역
        var evn = eventNote(eventName(src), [t0, it.p ? cleanTitle(nameOf(it.p), alb) : t0]);
        var lab = it.label;
        if (alb && lab && norm(lab).indexOf(norm(alb)) === 0) lab = lab.slice(alb.length).trim();
        var dup = !lab || norm(t0).indexOf(norm(lab)) >= 0 || norm(lab).indexOf(norm(t0)) >= 0;
        rest = sub(esc(evn || (dup ? areaOf(tags) : lab)));
      } else {
        var p = it.p;
        head = link(it.url, nameOf(p));
        var lb = it.label || '';
        if (lb === '영상 업로드' || lb === '') {
          var se = seriesTag(p.tags);
          var vt = se ? tagLabel(se) : T('home_chip_video', '영상');
          chips = (lb ? logoChip(vt, 'yt') : chip(vt, '🎬')) + memberChips(membersFromNames(p.members));
          // 메모 줄이 없어 제목이 그대로 뽑힌 노트는 지역으로
          var ct = p.src && norm(p.src).indexOf(norm(p.title)) < 0 && norm(p.title).indexOf(norm(p.src)) < 0 ? p.src : '';
          rest = sub(esc(ct || areaOf(p.tags)));
        } else if (lb === 'IG 게시') {
          chips = platformChip(PF_IG) + memberChips(membersFromNames(p.members));
          rest = sub(esc(areaOf(p.tags)));
        } else {
          var pf = platformOf(lb);
          var mem = membersFromNames(p.members);   // 그 날짜 게시자만이 아니라 노트 멤버 태그 전부
          if (pf) {
            chips = platformChip(pf) + memberChips(mem);
            rest = sub(esc(areaOf(p.tags)));
          } else {
            // 방송·역조공·방문 메모: 분류 칩은 노트 태그에서 (시리즈 → 역조공 → SNS 플랫폼), 메모 줄은 그대로 보여 준다
            var se2 = seriesTag(p.tags);
            var pf2 = platformTag(p.tags);
            var gift = (p.tags || []).indexOf('역조공') >= 0;
            chips = (se2 ? seriesChip(se2, p) : gift ? chip(tagLabel('역조공'), '🎁') : pf2 ? platformChip(pf2) : '') + memberChips(mem);
            rest = sub(esc(lb));
          }
        }
      }
      var tt = it.today || today;
      var live = it.evt && it.date <= tt && tt <= it.endDate + DAY - 1;
      var badge = live ? '<span class="live">' + (LANG !== 'ko' ? window.FimT('home_live', 'LIVE NOW') : '진행 중') + '</span>' : '';
      var when = md(it.date) + (it.endDate !== it.date ? ' ~ ' + md(it.endDate) : '');
      return '<li><div class="l1"><span class="ttl">' + badge + head + '</span><span class="when">' + when + '</span></div>' +
        ((chips || rest) ? '<div class="l2">' + chips + rest + '</div>' : '') + '</li>';
    }

    var html = picked.map(render).join('');
    document.getElementById('upcoming-events').innerHTML = html || ('<li>' +
      (LANG !== 'ko' ? window.FimT('home_no_events', '') : '표시할 일정이 없습니다.') + '</li>');
  });
})();
</script>
