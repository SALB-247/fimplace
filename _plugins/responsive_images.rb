# frozen_string_literal: true
#
# 대형 이미지(가로 2000px+)의 모바일 대응.
# _data/mobile_images.yml (scripts/make_mobile_images.py 생성) 에 등재된 원본에 한해,
# 렌더된 HTML 의 <img src="assets/원본"> 을 srcset 으로 치환한다.
#
# - 모바일(좁은 뷰포트) → assets/m/<이름>.webp (1200px)
# - 데스크톱 → 원본 그대로
# - 노트 원문은 수정하지 않음 (빌드 시 출력만 변환)

module ResponsiveImages
  SIZES = '(max-width: 800px) 100vw, 800px'

  def self.rewrite(html, manifest, baseurl)
    manifest.each do |orig, info|
      m_path = info['m']
      w      = info['w']
      next unless m_path && w
      # src="assets/원본" / src="/assets/원본" (따옴표 안 전체 매칭 — 공백·괄호 파일명 대응)
      pattern = /<img([^>]*?)\ssrc=(["'])\/?assets\/#{Regexp.escape(orig)}\2([^>]*?)>/
      html = html.gsub(pattern) do
        pre, quote, post = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
        # 이미 srcset 이 있으면 건너뜀
        if pre.include?('srcset') || post.include?('srcset')
          Regexp.last_match(0)
        else
          "<img#{pre} src=#{quote}#{baseurl}/assets/#{orig}#{quote}" \
          " srcset=#{quote}#{baseurl}/assets/#{m_path} 1200w, #{baseurl}/assets/#{orig} #{w}w#{quote}" \
          " sizes=#{quote}#{SIZES}#{quote} loading=#{quote}lazy#{quote}#{post}>"
        end
      end
    end
    html
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output_ext == '.html'
  manifest = doc.site.data['mobile_images']
  next if manifest.nil? || manifest.empty?
  next if doc.output.nil? || !doc.output.include?('assets/')
  doc.output = ResponsiveImages.rewrite(doc.output, manifest, doc.site.baseurl.to_s)
end
