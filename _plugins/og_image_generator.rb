# frozen_string_literal: true
#
# 각 노트의 첫 이미지(또는 YouTube 썸네일)를 자동으로 og:image 로 설정
#
# 우선순위:
#   1) front matter 의 `image` 가 명시되어 있으면 그 값을 사용
#   2) 본문의 첫 ![](...) 또는 <img src="..."> 사용
#   3) 본문의 YouTube 임베드에서 썸네일 추출
#   4) 기본 OG 이미지로 fallback

module OgImage
  IMG_MD_REGEX  = /!\[[^\]]*\]\(([^)\s]+)/
  IMG_HTML_REGEX = /<img[^>]*src=["']([^"']+)/i
  YT_REGEX      = /youtube(?:-nocookie)?\.com\/embed\/([A-Za-z0-9_\-]{6,})/i
  WEVERSE_REGEX = /(weverse[^\s"'<>]+\.(?:jpg|jpeg|png|webp))/i

  def self.pick(content)
    return nil if content.nil? || content.empty?
    if m = content.match(IMG_MD_REGEX);   return m[1]; end
    if m = content.match(IMG_HTML_REGEX); return m[1]; end
    if m = content.match(YT_REGEX);       return "https://i.ytimg.com/vi/#{m[1]}/hqdefault.jpg"; end
    nil
  end
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  next if doc.data['image']
  found = OgImage.pick(doc.content)
  doc.data['image'] = found if found
end
