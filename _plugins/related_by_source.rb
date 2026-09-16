# frozen_string_literal: true
#
# "함께 나온 장소" — 같은 인스타 게시물 / YouTube 영상 / 위버스 포스트 / X 게시물을 임베드(또는 링크)했거나
#                    같은 메모 줄(방송·DM·인스스처럼 링크가 없는 출처)을 쓴 노트끼리 묶는다.
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
    'x'  => [%r{(?:twitter|x)\.com/\w+/status/(\d+)}, '같은 X 게시물'],
  }.freeze
  LIMIT = 12

  # 링크로 묶을 수 없는 출처(방송·DM·인스스)는 **메모 줄**로 묶는다.
  #   예) 우선·포토오브제 성수점·오우칸 = "260916 후지TV '마음가는 대로 떠나는 둘만의 여행'"
  # 메모 줄 = 본문에서 처음 나오는 `YYMMDD ` / `YYMMDD_` 로 시작하는 줄. 글자가 완전히 같아야 한 묶음.
  # 인스타 피드 메모(`260109 사쿠라 인스타`)는 제외 — 같은 날 다른 게시물이 섞인다. 피드는 게시물 URL 로 묶을 것.
  # 링크가 든 메모(`260821_[위버스 포스트](…)`)도 제외 — 위 PATTERNS 가 이미 처리한다.
  MEMO_RE = /^\d{6}[ _]\S.*$/
  MEMO_VIA = [
    [/DM/, '같은 날 DM'],
    [/인스스|스토리/, '같은 날 스토리'],
    [/TV|テレビ|방송/, '같은 방송'],
  ].freeze
  MEMO_VIA_DEFAULT = '같은 출처'

  def self.memo_key(content)
    body = content.to_s.gsub(/<!--.*?-->/m, '')   # TODO 주석 속 날짜 줄은 메모가 아니다
    line = body.each_line.map(&:strip).find { |l| l.match?(MEMO_RE) }
    return nil unless line
    return nil if line.include?('](')
    return nil if line.include?('인스타') && !line.match?(/인스스|DM/)
    line.gsub(/\s+/, ' ')
  end

  def self.memo_via(line)
    MEMO_VIA.each { |re, via| return via if line.match?(re) }
    MEMO_VIA_DEFAULT
  end

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
        memo = RelatedBySource.memo_key(n.content)
        ks << "memo:#{memo}" if memo
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
            (rel[o] ||= []) << k
          end
        end
        next if rel.empty?
        list = rel.map do |o, keys|
          emoji = Array(o.data['members']).map { |m| EMOJI[m] || '' }.join
          # 링크로도 묶였으면 메모 라벨은 뺀다 ("같은 인스타 게시물 · 같은 날 스토리" 같은 중복 방지)
          link_keys = keys.reject { |k| k.start_with?('memo:') }
          keys = link_keys unless link_keys.empty?
          vias = keys.map do |k|
            type, id = k.split(':', 2)
            type == 'memo' ? RelatedBySource.memo_via(id) : PATTERNS[type][1]
          end
          {
            'title' => o.data['title'].to_s,
            'url'   => o.url,
            'via'   => vias.uniq.join(' · '),
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
