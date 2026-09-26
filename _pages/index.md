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
     멤버 칩은 노트 페이지와 같은 .member-chip 색. 같은 이벤트를 매장 3곳 이상이 함께 하면 한 줄로 묶는다. -->
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

  // 멤버: full = .member-chip 색 클래스, tag = 번역 사전 키, re = 메모 줄에서 찾는 이름
  var MEMBERS = [
    { full: '사쿠라', tag: '꾸라', ko: '사쿠라', re: /사쿠라|꾸라/ },
    { full: '김채원', tag: '채원', ko: '채원', re: /채원/ },
    { full: '허윤진', tag: '윤진', ko: '윤진', re: /윤진/ },
    { full: '카즈하', tag: '즈하', ko: '즈하', re: /즈하/ },
    { full: '홍은채', tag: '은채', ko: '은채', re: /은채|만채/ }
  ];
  // 메모 줄의 플랫폼 — 앞에서부터 먼저 맞는 것 ('허윤진 위버스 DM' 은 DM)
  var PLATFORMS = [
    { re: /인스스|스토리/, key: 'home_chip_story', ko: '인스타 스토리', ico: '📷' },
    { re: /DM/, tag: 'DM', ico: '💬' },
    { re: /인스타/, tag: '인스타', ico: '📷' },
    { re: /위버스/, tag: '위버스', ico: '💬' },
    { re: /틱톡/, tag: '틱톡', ico: '🎵' },
    { re: /공트/, tag: '공트', ico: '📣' },
    { re: /멤트/, tag: '멤트', ico: '📣' }
  ];
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
  function norm(s) { return String(s || '').toLowerCase().replace(/[\s_]/g, ''); }
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

  function chip(text, ico) { return '<span class="kc">' + (ico ? ico + ' ' : '') + esc(text) + '</span>'; }
  function typeChip(type) { var d = TYPES[type] || TYPES['이벤트']; return chip(T(d.key, type), d.ico); }
  function membersFromNames(names) {
    return MEMBERS.filter(function (m) { return (names || []).indexOf(m.full) >= 0; });
  }
  function membersFromLabel(label) {
    return MEMBERS.filter(function (m) { return m.re.test(label || ''); });
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
  function platformChip(pf) { return chip(pf.key ? T(pf.key, pf.ko) : tagLabel(pf.tag), pf.ico); }
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
    function seriesOf(tags) {
      var list = (tags || []).filter(function (t) { return SERIES[t]; });
      var best = list.filter(function (t) { return t !== '자체컨텐츠_촬영지' && t !== '유튜브'; })[0] || list[0];
      return best ? tagLabel(best) : '';
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
      var key = s0.event ? 'E|' + s0.event
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
        // 매장 이름: 공통 앞말(카시나·세븐일레븐)은 빼고 지점만. 영어·일본어는 모든 매장에 현지 이름이 있을 때만 그 이름
        var srcs = it.list.map(function (x) { return x.p || x.ev; });
        var pick = function (f) { return srcs.every(function (x) { return f(x); }) ? srcs.map(f) : null; };
        var names = (LANG === 'ja' && pick(function (x) { return x.name_ja; })) ||
          (LANG !== 'ko' && (pick(function (x) { return x.label_en; }) || pick(function (x) { return x.name_en; }))) ||
          srcs.map(function (x) { return x.title; });
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
          var se = seriesOf(p.tags);
          chips = (se ? chip(se, '🎬') : chip(T('home_chip_video', '영상'), '🎬')) + memberChips(membersFromNames(p.members));
          // 메모 줄이 없어 제목이 그대로 뽑힌 노트는 지역으로
          var ct = p.src && norm(p.src).indexOf(norm(p.title)) < 0 && norm(p.title).indexOf(norm(p.src)) < 0 ? p.src : '';
          rest = sub(esc(ct || areaOf(p.tags)));
        } else if (lb === 'IG 게시') {
          chips = platformChip(PLATFORMS[2]) + memberChips(membersFromNames(p.members));
          rest = sub(esc(areaOf(p.tags)));
        } else {
          var pf = platformOf(lb);
          var mem = membersFromLabel(lb);
          if (!mem.length) mem = membersFromNames(p.members);
          if (pf) {
            chips = platformChip(pf) + memberChips(mem);
            rest = sub(esc(areaOf(p.tags)));
          } else {
            // 방송·역조공 같은 메모: 분류 칩은 노트 태그에서, 메모 줄은 그대로 보여 준다
            var se2 = seriesOf(p.tags);
            chips = (se2 ? chip(se2, '🎬') : '') + memberChips(mem);
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
