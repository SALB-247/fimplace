# 노트별 shortid 를 받아 /s/<shortid>/index.html 리다이렉트 페이지 생성.
# - meta refresh + JS location.replace (즉시 이동)
# - canonical 태그 (한글 URL 이 정본)
# - OG 메타태그 복제 (SNS 미리보기 크롤러가 단축 URL 직접 가져갈 때 대비)
# - sitemap 제외 (정본 한 개만 인덱싱)
require 'json'

module Shortlinks
  IMG_MD_REGEX   = /!\[[^\]]*\]\(([^)\s]+)/
  IMG_HTML_REGEX = /<img[^>]*src=["']([^"']+)/i
  YT_REGEX       = /youtube(?:-nocookie)?\.com\/embed\/([A-Za-z0-9_\-]{6,})/i

  def self.pick_image(content)
    return nil if content.nil? || content.empty?
    if (m = content.match(IMG_MD_REGEX));   return m[1]; end
    if (m = content.match(IMG_HTML_REGEX)); return m[1]; end
    if (m = content.match(YT_REGEX));       return "https://i.ytimg.com/vi/#{m[1]}/hqdefault.jpg"; end
    nil
  end

  def self.absolutize(src, site)
    return src if src =~ /\Ahttps?:\/\//
    base = (site.config['url'] || '').sub(/\/\z/, '') + (site.config['baseurl'] || '')
    "#{base}#{src.start_with?('/') ? '' : '/'}#{src}"
  end

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      created = 0
      collisions = []
      seen = {}
      site_url = (site.config['url'] || '').sub(/\/\z/, '')
      baseurl  = site.config['baseurl'] || ''
      default_og = site.config['default_og_image'] || '/assets/image.jpg'

      site.collections['notes'].docs.each do |note|
        sid = note.data['shortid'].to_s.strip
        next if sid.empty?
        if seen[sid]
          collisions << "#{sid}: #{seen[sid]} / #{note.data['title']}"
          next
        end
        seen[sid] = note.data['title']

        target_path = "#{baseurl}#{note.url}"           # e.g. "/cafe-tapirosu"
        target_abs  = "#{site_url}#{target_path}"       # 절대 URL (canonical/og:url 용)
        title       = note.data['title'].to_s.gsub('"', '&quot;')
        img_src     = note.data['image'] || Shortlinks.pick_image(note.content) || default_og
        og_img_url  = Shortlinks.absolutize(img_src, site)

        # safe JS string-literal escape: 백슬래시 → 작은따옴표 순서로
        js_target = target_path.gsub('\\', '\\\\').gsub("'", "\\'")
        html = <<~HTML
          <!DOCTYPE html>
          <html lang="ko"><head>
          <meta charset="UTF-8">
          <title>#{title} — Fimplace</title>
          <link rel="canonical" href="#{target_abs}">
          <meta http-equiv="refresh" content="0; url=#{target_path}">
          <meta name="robots" content="noindex, follow">
          <meta property="og:title" content="#{title}">
          <meta property="og:type" content="article">
          <meta property="og:url" content="#{target_abs}">
          <meta property="og:image" content="#{og_img_url}">
          <meta property="og:image:width" content="1200">
          <meta property="og:image:height" content="630">
          <meta property="og:locale" content="ko_KR">
          <meta property="og:site_name" content="#{site.config['title']}">
          <meta name="twitter:card" content="summary_large_image">
          <meta name="twitter:title" content="#{title}">
          <meta name="twitter:image" content="#{og_img_url}">
          <script>location.replace('#{js_target}');</script>
          <style>body{font-family:sans-serif;padding:2em;color:#666}</style>
          </head><body>
          <p>Redirecting to <a href="#{target_path}">#{title}</a>...</p>
          </body></html>
        HTML

        page = Jekyll::PageWithoutAFile.new(site, site.source, "s/#{sid}", 'index.html')
        page.content = html
        page.data['layout']  = nil
        page.data['sitemap'] = false   # jekyll-sitemap 제외
        site.pages << page
        created += 1
      end

      if defined?(Jekyll)
        Jekyll.logger.info('Shortlinks', "created #{created} redirect pages")
        collisions.each { |c| Jekyll.logger.warn('Shortlinks', "collision: #{c}") } unless collisions.empty?
      end
    end
  end
end
