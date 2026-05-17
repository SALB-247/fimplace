# frozen_string_literal: true
#
# 노트의 tags 에서 멤버 이름/별칭을 자동 검출해서 members 필드에 채워넣음
#
# 예) tags: ['2025년_사쿠라_생일카페'] -> members: ['사쿠라']
#     tags: ['은채', 'FIM-LOG']        -> members: ['홍은채']
#     tags: ['1979 LP LIVE PUB', '꾸라', '즈하', '은채'] -> members: ['사쿠라','카즈하','홍은채']
#
# - 별칭은 부분 문자열 매칭이므로 "은채" 가 다른 단어에 포함돼도 잡힘
# - 더 긴 별칭부터 매칭 (예: '사쿠라' 가 '사키' 보다 우선) → 중복 방지
# - 노트 frontmatter 에 members 가 이미 있으면 추가만 함 (덮어쓰지 않음)

module MemberExtractor
  # canonical name => 매칭할 별칭들 (긴 순서대로)
  MEMBERS = {
    '사쿠라' => %w[사쿠라 꾸라 사키 sakura],
    '김채원' => %w[김채원 채원 chaewon],
    '허윤진' => %w[허윤진 윤진 yunjin],
    '카즈하' => %w[카즈하 즈하 카즈 kazuha],
    '홍은채' => %w[홍은채 은채 eunchae]
  }

  def self.extract(tags)
    return [] if tags.nil? || tags.empty?
    found = []
    tags.each do |tag|
      tag_str = tag.to_s.downcase
      MEMBERS.each do |canonical, aliases|
        next if found.include?(canonical)
        aliases.each do |a|
          if tag_str.include?(a.downcase)
            found << canonical
            break
          end
        end
      end
    end
    found
  end

  class Generator < Jekyll::Generator
    safe true
    priority :high  # tag_pages_generator, places_generator 보다 먼저 실행

    def generate(site)
      site.collections['notes'].docs.each do |note|
        tags = Array(note.data['tags'])
        existing = Array(note.data['members'])
        auto = MemberExtractor.extract(tags)
        merged = (existing + auto).uniq
        note.data['members'] = merged unless merged.empty?
      end
    end
  end
end
