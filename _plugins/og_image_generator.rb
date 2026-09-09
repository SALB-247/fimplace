# frozen_string_literal: true
#
# 각 노트의 첫 이미지(또는 YouTube 썸네일)를 자동으로 og:image 로 설정
#
# 우선순위:
#   1) front matter 의 `image` 가 명시되어 있으면 그 값을 사용
#   2) 본문의 첫 ![](...) 또는 <img src="..."> 사용
#   3) 본문의 YouTube 임베드에서 썸네일 추출
#   4) 기본 OG 이미지로 fallback
#   + og:image:width/height 를 실제 픽셀값으로 (image_width / image_height 주입)

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

  # 이미지 실제 픽셀 크기 (PNG/JPEG/GIF/WebP 헤더만 읽음 — 외부 젬 불필요).
  # og:image:width/height 를 실제값으로 내보내 카카오톡·페이스북 카드 크롭을 정확히.
  SOF_MARKERS = [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF].freeze
  def self.dimensions(path)
    return nil unless path && File.file?(path)
    File.open(path, 'rb') do |f|
      head = f.read(32).to_s
      if head.getbyte(0) == 0x89 && head[1, 3] == 'PNG'
        f.seek(16); return f.read(8).unpack('N2')
      elsif head.start_with?('GIF8'.b)
        return head[6, 4].unpack('v2')
      elsif head.start_with?('RIFF'.b) && head[8, 4] == 'WEBP'
        case head[12, 4]
        when 'VP8X'
          f.seek(24); b = f.read(6).bytes
          return [1 + (b[0] | (b[1] << 8) | (b[2] << 16)), 1 + (b[3] | (b[4] << 8) | (b[5] << 16))]
        when 'VP8 '
          f.seek(26); w, h = f.read(4).unpack('v2'); return [w & 0x3fff, h & 0x3fff]
        when 'VP8L'
          f.seek(21); b = f.read(4).unpack('V')[0]; return [1 + (b & 0x3fff), 1 + ((b >> 14) & 0x3fff)]
        end
      elsif head.getbyte(0) == 0xFF && head.getbyte(1) == 0xD8
        f.seek(2)
        loop do
          mk = f.read(2)
          break unless mk && mk.bytesize == 2 && mk.getbyte(0) == 0xFF
          m = mk.getbyte(1)
          if m == 0xFF then f.seek(-1, IO::SEEK_CUR); next end     # fill byte
          next if (0xD0..0xD9).cover?(m) || m == 0x01                # 길이 없는 마커
          len = f.read(2).unpack1('n')
          if SOF_MARKERS.include?(m)
            f.read(1); h, w = f.read(4).unpack('n2'); return [w, h]
          end
          f.seek(len - 2, IO::SEEK_CUR)
        end
      end
    end
    nil
  rescue StandardError
    nil
  end

  def self.local_path(site, img)
    return nil if img.nil? || img.include?('://')
    File.join(site.source, img.sub(%r{^/}, ''))
  end
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  site = doc.site
  unless doc.data['image']
    found = OgImage.pick(doc.content)
    doc.data['image'] = found if found
  end
  img = doc.data['image']
  next unless img
  # 로컬 파일이면 실제 픽셀 크기, YouTube hqdefault 는 480x360 고정
  if img.include?('i.ytimg.com/vi/')
    doc.data['image_width'], doc.data['image_height'] = 480, 360
  elsif (dim = OgImage.dimensions(OgImage.local_path(site, img)))
    doc.data['image_width'], doc.data['image_height'] = dim
    # 공백 등이 든 파일명은 og:image URL 에서 깨지므로 인코딩 (head.html 은 값을 그대로 씀)
    doc.data['image'] = img.gsub(' ', '%20') if img.include?(' ')
  end
end

# 기본 OG 이미지(사이트 공통) 크기도 한 번 계산해 head.html 이 쓰게 함
Jekyll::Hooks.register :site, :post_read do |site|
  img = site.config['default_og_image'] || '/assets/image.jpg'
  dim = OgImage.dimensions(OgImage.local_path(site, img))
  site.data['og_default_size'] = { 'w' => dim[0], 'h' => dim[1] } if dim
end
