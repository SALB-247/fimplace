# frozen_string_literal: true
#
# 검색 인덱스 생성 (Ruby 플러그인)
# Liquid 템플릿보다 안정적, 본문에서 iframe/이미지/마크다운 노이즈 제거

module SearchIndexer
  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      items = site.collections['notes'].docs.filter_map do |note|
        title = note.data['title'].to_s.strip
        next nil if title.empty?
        {
          'title'   => title,
          'url'     => "#{site.baseurl}#{note.url}",
          'tags'    => Array(note.data['tags']).map(&:to_s),
          'members' => Array(note.data['members']).map(&:to_s),
          'address' => extract_address_line(note.content.to_s),
          'excerpt' => clean_excerpt(note.content.to_s, 300)
        }
      end
      site.data['search_index'] = items
    end

    private

    def clean_excerpt(content, limit)
      t = content.dup
      t.gsub!(/<iframe[\s\S]*?<\/iframe>/i, '')
      t.gsub!(/<blockquote[\s\S]*?<\/blockquote>/i, '')
      t.gsub!(/<script[\s\S]*?<\/script>/i, '')
      t.gsub!(/<[^>]+>/, ' ')
      t.gsub!(/!\[[^\]]*\]\([^)]+\)/, ' ')
      t.gsub!(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/, '\1 ')
      t.gsub!(/\[([^\]]+)\]\([^)]+\)/, '\1 ')
      t.gsub!(/[#*_`>~-]/, ' ')
      t.gsub!(/\s+/, ' ')
      t.strip!
      t.length > limit ? t[0...limit] : t
    end

    KR_REGION = %w[서울 부산 대구 인천 광주 대전 울산 세종 경기 강원 충북 충남 전북 전남 경북 경남 제주]
    ADDR_REGEX = /(?:#{KR_REGION.join('|')})(?:특별시|광역시|특별자치도|도)?\s+\S.+/

    def extract_address_line(content)
      # 1) ## 위치 / ## 주소 헤딩 다음 줄
      m = content.match(/##\s*(?:위치|주소|주\s*소|위\s*치|location|address)\s*\n+([^\n#]+)/i)
      return m[1].to_s.strip.gsub(/<[^>]+>/, '').strip if m

      # 2) 본문에서 한국 도/시 prefix 패턴 첫 라인
      m = content.match(ADDR_REGEX)
      return m[0].to_s.strip if m

      ''
    end
  end
end
