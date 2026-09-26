# frozen_string_literal: true
#
# 이벤트 모음 노트의 '# 소제목' = 그 아래 매장들의 공식 이벤트 이름 (2026-09-26)
#
# 홈 '최근 일정 노트' 가 같은 이벤트 매장 3곳 이상을 한 줄로 묶을 때 제목으로 쓴다
# ("카시나 3곳" 이 아니라 "KASINA ALBUM & BRAND MERCH." — 사용자 지적). 한 매장짜리 이벤트는 둘째 줄 설명이 된다.
# 대상 = _data/hub_menu.yml 의 group: 이벤트 아래 모음. 영어 이름·영어 매장 라벨은 _hubs_en/<같은 파일명>.md 의 같은 구조에서.
#
#   # KASINA ALBUM & BRAND MERCH.          ← 이벤트 이름
#   * [[카시나 성수 (Made My Night)]] — …   ← 이 노트의 이벤트 = 위 이름
#   # [[LE SSERAFIM 2026 SS POP UP]]        ← 소제목 자체가 링크면 매장 (직전 이벤트 이름 아래)
#
# 결과: note.data['hub_event'] = { 'ko' => 이름, 'en' => 영어 이름, 'label_en' => 영어판 링크 라벨 }
#       → places.json·events.json 의 event / event_en / label_en (places_generator · event_period_generator)

module HubEvents
  WIKILINK = /\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/

  module_function

  # 본문 → { 링크 대상 => { 'event' => 소제목, 'label' => 링크 라벨 } }
  def parse(text)
    out = {}
    event = nil
    text.to_s.gsub(/<!--.*?-->/m, '').each_line do |line|
      s = line.strip
      if (m = s.match(/\A#\s+(.+)\z/))   # '# ' 하나짜리 소제목만 (## 매장 소제목은 아래 링크로 잡힌다)
        h = m[1].strip
        if h =~ WIKILINK && h.gsub(WIKILINK, '').strip.empty?
          h.scan(WIKILINK) { |t, lab| add(out, t, lab, event) }
        else
          event = h.gsub(/\*\*|__/, '').strip
        end
        next
      end
      s.scan(WIKILINK) { |t, lab| add(out, t, lab, event) } if event
    end
    out
  end

  def add(out, target, label, event)
    return if event.nil? || event.empty?
    key = target.to_s.strip.unicode_normalize(:nfc)
    out[key] ||= { 'event' => event, 'label' => label && label.strip }
  end

  def strip_frontmatter(s)
    s.to_s.sub(/\A---\s*\n.*?\n---\s*\n/m, '')
  end

  class Generator < Jekyll::Generator
    safe true
    # bidirectional_links_generator(:normal) 가 본문의 [[링크]] 를 <a> 로 바꾸기 전에 — 그래도 본문은 디스크 원본에서 읽는다
    priority :high

    def generate(site)
      hubs = []
      group = nil
      Array(site.data['hub_menu']).each do |it|
        if it['group']
          group = it['group']
          next
        end
        hubs << it['title'].to_s if group == '이벤트'
      end
      return if hubs.empty?

      notes = site.collections['notes'].docs
      by_key = {}
      notes.each do |n|
        [n.data['title'].to_s, File.basename(n.path, '.*')].each do |k|
          by_key[k.strip.unicode_normalize(:nfc)] ||= n
        end
      end

      set = 0
      notes.each do |hub|
        next unless hubs.include?(hub.data['title'].to_s)
        ko = HubEvents.parse(HubEvents.strip_frontmatter(File.read(hub.path, encoding: 'utf-8')))
        en_path = File.join(site.source, '_hubs_en', File.basename(hub.path))
        en = File.exist?(en_path) ? HubEvents.parse(HubEvents.strip_frontmatter(File.read(en_path, encoding: 'utf-8'))) : {}
        ko.each do |target, v|
          note = by_key[target]
          next if note.nil? || note.data['hide_backlinks'] || note.data['hub_event']
          e = en[target] || {}
          note.data['hub_event'] = { 'ko' => v['event'], 'en' => e['event'], 'label_en' => e['label'] }.compact
          set += 1
        end
      end
      Jekyll.logger.info('HubEvents', "이벤트 모음 #{hubs.size}곳 → 매장 노트 #{set}개에 이벤트 이름")
    end
  end
end
