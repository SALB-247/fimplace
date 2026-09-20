# frozen_string_literal: true
#
# 큰 이미지의 웹용 변형 치환 (2026-09-20 확장 — 예전엔 가로 2000px+ 의 모바일 변형만).
# _data/web_images.yml (scripts/make_web_images.py 생성) 에 등재된 원본에 한해,
# 렌더된 HTML 의 <img src="assets/원본"> 을 변형으로 바꾼다.
#
# - src      → d 변형 (긴 변 1600 webp)
# - srcset   → m 변형 (1200) + d 변형. 모바일은 m, 데스크톱은 d 를 고른다
# - 움직이는 gif → <video autoplay muted loop playsinline poster> (mp4)
# - 노트 원문·원본 파일은 수정하지 않음 (빌드 시 출력만 변환). 원본은 그대로 assets/ 에 남는다
# - width/height 속성은 일부러 안 넣는다: 사이트 CSS 가 max-height:75vh 로 세로 사진을 줄이는데,
#   속성이 있으면 폭이 고정돼 비율이 깨진다

require 'cgi'

module ResponsiveImages
  SIZES = '(max-width: 800px) 100vw, 800px'
  IMG_RE = /<img\b([^>]*?)\ssrc=(["'])\/?assets\/([^"']+)\2([^>]*?)>/i

  def self.rewrite(html, manifest, baseurl)
    html.gsub(IMG_RE) do
      pre, quote, name, post = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4)
      info = manifest[name] || manifest[CGI.unescape(name)]
      rest = pre + post
      if info.nil? || info['skip'] || rest.include?('srcset')
        Regexp.last_match(0)
      elsif info['v']
        # 움직이는 gif → mp4. <img> 의 나머지 속성(alt 등)은 버린다
        "<video autoplay muted loop playsinline preload=#{quote}metadata#{quote}" \
        " poster=#{quote}#{baseurl}/assets/#{info['poster']}#{quote}" \
        " src=#{quote}#{baseurl}/assets/#{info['v']}#{quote}></video>"
      else
        attrs = +" src=#{quote}#{baseurl}/assets/#{info['d']}#{quote}"
        if info['m']
          set = "#{baseurl}/assets/#{info['m']} #{info['mw']}w, #{baseurl}/assets/#{info['d']} #{info['dw']}w"
          attrs << " srcset=#{quote}#{set}#{quote} sizes=#{quote}#{SIZES}#{quote}"
        end
        attrs << " loading=#{quote}lazy#{quote}" unless rest =~ /\bloading=/
        attrs << " decoding=#{quote}async#{quote}" unless rest =~ /\bdecoding=/
        "<img#{pre}#{attrs}#{post}>"
      end
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output_ext == '.html'
  manifest = doc.site.data['web_images']
  next if manifest.nil? || manifest.empty?
  next if doc.output.nil? || !doc.output.include?('assets/')
  doc.output = ResponsiveImages.rewrite(doc.output, manifest, doc.site.baseurl.to_s)
end
