# frozen_string_literal: true
#
# "함께 나온 장소" — 같은 인스타 게시물 / YouTube 영상 / 위버스 포스트를 임베드(또는 링크)한 노트끼리 묶는다.
#   예) 국제갤러리·평양면옥·삼청동호떡 = 같은 IG 게시물 DcsW6XPFN8A → 서로의 노트에 나머지 둘이 표시
#
# 빌드 때 본문에서 소스 ID 를 뽑아 그룹을 만들고, 각 노트에 아래를 주입한다 (_includes/related_places.html 이 렌더):
#   data['related_by_source']       [{ title, url, via, emoji }, …]  (제목순, 최대 12)
#   data['related_by_source_total'] 전체 개수
# 허브 노트(hide_backlinks)는 그룹에서 제외. 임베드가 아닌 단순 링크(예: 삭제된 게시물의 원본 링크)도 같은 소스로 본다.

module RelatedBySource
  EMOJI = { '사쿠라' => '🌸', '김채원' => '🐯', '허윤진' => '🐍', '카즈하' => '🦢', '홍은채' => '🐥' }.freeze
  PATTERNS = {
    'ig' => [%r{instagram\.com/(?:p|reel)/([A-Za-z0-9_-]{8,})}, '같은 인스타 게시물'],
    'yt' => [%r{youtube(?:-nocookie)?\.com/embed/([A-Za-z0-9_-]{11})}, '같은 영상'],
    'wv' => [%r{weverse\.io/lesserafim/(?:artist|live)/([A-Za-z0-9-]+)}, '같은 위버스 포스트'],
  }.freeze
  LIMIT = 12

  class Generator < Jekyll::Generator
    safe true
    priority :low   # member_extractor(:high) · event_period(:normal) 뒤

    def generate(site)
      notes = site.collections['notes'].docs.reject { |n| n.data['hide_backlinks'] }
      by_key = Hash.new { |h, k| h[k] = [] }
      keys_of = {}
      notes.each do |n|
        ks = []
        PATTERNS.each do |type, (re, _)|
          n.content.to_s.scan(re) { |(id)| ks << "#{type}:#{id}" }
        end
        ks.uniq!
        keys_of[n] = ks
        ks.each { |k| by_key[k] << n }
      end

      grouped = 0
      notes.each do |n|
        rel = {}
        keys_of[n].each do |k|
          by_key[k].each do |o|
            next if o.equal?(n)
            (rel[o] ||= []) << k.split(':', 2).first
          end
        end
        next if rel.empty?
        list = rel.map do |o, types|
          emoji = Array(o.data['members']).map { |m| EMOJI[m] || '' }.join
          {
            'title' => o.data['title'].to_s,
            'url'   => o.url,
            'via'   => types.uniq.map { |t| PATTERNS[t][1] }.join(' · '),
            'emoji' => (emoji.empty? ? '📍' : emoji),
          }
        end
        list.sort_by! { |r| r['title'] }
        n.data['related_by_source'] = list.first(LIMIT)
        n.data['related_by_source_total'] = list.size
        grouped += 1
      end
      Jekyll.logger.info 'RelatedBySource:', "소스 공유 그룹 #{by_key.count { |_, v| v.size > 1 }}개 / 노트 #{grouped}개에 '함께 나온 장소' 주입"
    end
  end
end
