# frozen_string_literal: true
#
# YouTube/지도 iframe -> facade(썸네일/플레이스홀더) 변환
# 페이지 로딩 속도 개선용. 사용자가 클릭하기 전까지 무거운 iframe을 로드하지 않음.
#
# - YouTube 임베드 -> .yt-facade (썸네일 + 재생 아이콘, 클릭 시 iframe 삽입)
# - Google Maps 임베드 -> .map-facade (placeholder, 클릭 시 iframe 삽입)
# - Naver/Kakao 등 기타 iframe -> loading="lazy" 만 보강

module IframeFacade
  YT_REGEX = /<iframe[^>]*src="https?:\/\/(?:www\.)?youtube(?:-nocookie)?\.com\/embed\/([A-Za-z0-9_\-]{6,})([^"]*)"[^>]*>\s*<\/iframe>/i
  MAP_REGEX = /<iframe([^>]*?)src="(https?:\/\/www\.google\.com\/maps\/embed[^"]+)"([^>]*)>\s*<\/iframe>/i
  GENERIC_IFRAME_REGEX = /<iframe(?![^>]*\bloading=)([^>]*)>/i

  def self.transform(html)
    return html if html.nil? || html.empty?

    # 1) YouTube
    html = html.gsub(YT_REGEX) do
      video_id = Regexp.last_match(1)
      query    = Regexp.last_match(2).to_s
      src = "https://www.youtube.com/embed/#{video_id}#{query.empty? ? '?' : query + '&'}autoplay=1"
      thumb = "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg"
      %(<div class="yt-facade" role="button" tabindex="0" aria-label="YouTube 영상 재생" data-yt-src="#{src}"><img loading="lazy" src="#{thumb}" alt="YouTube thumbnail"></div>)
    end

    # 2) Google Maps
    html = html.gsub(MAP_REGEX) do
      src = Regexp.last_match(2)
      %(<div class="map-facade" role="button" tabindex="0" aria-label="지도 보기" data-map-src="#{src}"><span>지도를 보려면 클릭하세요</span></div>)
    end

    # 3) 기타 iframe(이미 변환된 것 제외) - loading=lazy 보강
    html = html.gsub(GENERIC_IFRAME_REGEX) do
      attrs = Regexp.last_match(1)
      %(<iframe loading="lazy"#{attrs}>)
    end

    html
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output
  next unless doc.output.include?('<iframe')
  doc.output = IframeFacade.transform(doc.output)
end
