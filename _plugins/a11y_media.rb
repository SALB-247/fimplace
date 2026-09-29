# frozen_string_literal: true
#
# 접근성·로딩 보강 (2026-09-29 사이트 전수 점검에서 나옴) — 빌드 출력만 바꾼다, 노트 원문은 그대로.
#
# - title 없는 iframe 에 서비스 이름 title — 화면 읽기 프로그램이 이름 없는 '프레임' 으로만 읽던 것 (1,895개)
#   (Google Maps · Instagram · TikTok · X · YouTube … — 상표 이름이라 한국어·영어·일본어 화면 모두 그대로 통한다)
# - 본문(<content>) 사진 중 alt 가 없는 것에 alt="<노트 제목>" (1,379장). 이미 alt 가 있으면(위키미디어 크레딧 등) 그대로
# - 본문 두 번째 사진부터 loading="lazy" decoding="async" — 첫 사진은 바로 보이게 둔다 (392쪽이 전부 즉시 받고 있었다)
# - <script> 안의 문자열('<img …' 을 만드는 코드)은 건드리지 않는다

require 'cgi'

module A11yMedia
  IFRAME_NAMES = [
    [%r{google\.[a-z.]+/maps}i, 'Google Maps'],
    [/instagram\.com/i, 'Instagram'],
    [/tiktok\.com/i, 'TikTok'],
    [%r{//(?:[a-z]+\.)?(?:twitter|x)\.com}i, 'X'],
    [/youtube(?:-nocookie)?\.com/i, 'YouTube'],
    [/weverse/i, 'Weverse'],
    [/naver\.com/i, 'Naver Map'],
    [/kakao\.com/i, 'Kakao Map'],
    [/giscus/i, 'Comments'],
  ].freeze
  IFRAME_RE = /<iframe\b([^>]*)>/i
  IMG_RE = /<img\b([^>]*)>/i
  CONTENT_RE = %r{(<content\b[^>]*>)(.*?)(</content>)}mi
  SCRIPT_SPLIT = %r{(<script\b.*?</script>)}mi

  module_function

  # 스크립트 블록은 그대로 두고 나머지 조각에만 블록을 적용
  def outside_scripts(html)
    html.split(SCRIPT_SPLIT).map { |part| part.start_with?('<script') ? part : yield(part) }.join
  end

  def iframe_titles(html)
    outside_scripts(html) do |part|
      part.gsub(IFRAME_RE) do
        m, attrs = Regexp.last_match(0), Regexp.last_match(1)
        next m if attrs =~ /\btitle\s*=/i
        src = attrs[/\bsrc\s*=\s*["']([^"']+)/i, 1].to_s
        name = IFRAME_NAMES.find { |re, _| src =~ re }&.last || src[%r{//([^/"']+)}, 1] || 'embed'
        %(<iframe title="#{CGI.escapeHTML(name)}"#{attrs}>)
      end
    end
  end

  def content_images(html, title)
    alt = CGI.escapeHTML(title.to_s.strip)
    html.sub(CONTENT_RE) do
      open_tag, body, close_tag = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
      n = 0
      body = outside_scripts(body) do |part|
        part.gsub(IMG_RE) do
          m, attrs = Regexp.last_match(0), Regexp.last_match(1)
          n += 1
          add = +''
          add << %( alt="#{alt}") unless attrs =~ /\balt\s*=/i || alt.empty?
          if n > 1
            add << ' loading="lazy"' unless attrs =~ /\bloading\s*=/i
            add << ' decoding="async"' unless attrs =~ /\bdecoding\s*=/i
          end
          add.empty? ? m : "<img#{add}#{attrs}>"
        end
      end
      open_tag + body + close_tag
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render, priority: :low do |doc|
  next unless doc.respond_to?(:output_ext) && doc.output_ext == '.html'
  out = doc.output
  next if out.nil? || out.empty?
  out = A11yMedia.iframe_titles(out) if out.include?('<iframe')
  out = A11yMedia.content_images(out, doc.data['title']) if out.include?('<content') && out.include?('<img')
  doc.output = out
end
