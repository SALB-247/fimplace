---
layout: null
permalink: /i18n-dict.js
sitemap: false
---
{%- comment -%}
  번역 사전(영어·일본어) — 2026-09-29 전에는 페이지마다 약 80KB 가 인라인으로 들어 있었다.
  이제 _includes/i18n.html 이 이 파일을 먼저 부르고, 브라우저는 빌드마다 한 번만 받는다 (?v=빌드 시각 + netlify.toml 의 immutable 캐시).
{%- endcomment -%}
window.FIM_I18N = { en: {{ site.data.i18n | jsonify }}, ja: {% if site.data.i18n_ja %}{{ site.data.i18n_ja | jsonify }}{% else %}{}{% endif %} };
