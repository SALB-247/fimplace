# frozen_string_literal: true
#
# 투어 노트의 '일정' 표를 파싱해서 site.data['tour_shows'] 생성 → tour_schedule.json 발행.
#
# - 표는 노트 안의 마크다운이 계속 단일 소스 (사용자가 평소처럼 노트만 고치면 됨)
# - 이 데이터를 쓰는 곳:
#     1) _includes/tour_calendar.html  — 투어 페이지 달력 (지난/오늘/예정 을 브라우저 시각으로 판정)
#     2) _pages/map.html               — '현재 핌둥이들 위치' 마커
#   둘 다 클라이언트에서 new Date() 로 판정하므로 빌드 후 날짜가 지나도 자동 갱신됨.
#
# 표 형식:  | 날짜 | 도시 | 공연장 | (비고) |
# 날짜 형식: 2026.07.11–12 / 2026.07.30, 08.01–02 / 2023.09.30–10.01 / 2023.10.03 / 2025.06.12, 14–15
#           (– 는 en-dash. hyphen/em-dash 도 허용)

require 'date'

module TourScheduleGenerator
  DASH        = '[–—-]'
  MAX_SPAN    = 21          # 날짜 범위 확장 상한 (파싱 오류로 폭주 방지)
  FLAG_REGEX  = /[\u{1F1E6}-\u{1F1FF}]{2}/

  module_function

  def date_str(y, m, d)
    Date.new(y, m, d).strftime('%Y-%m-%d')
  rescue ArgumentError
    nil
  end

  # 월을 넘는 범위: 2023.09.30–10.01 / 2026.01.31–02.01
  def expand_cross(year, m1, d1, m2, d2)
    y2 = m2 < m1 ? year + 1 : year
    a = Date.new(year, m1, d1)
    b = Date.new(y2, m2, d2)
    return [] if b < a || (b - a).to_i > MAX_SPAN
    (a..b).map { |x| x.strftime('%Y-%m-%d') }
  rescue ArgumentError
    []
  end

  def parse_dates(raw)
    s = raw.to_s.strip
    m = s.match(/\A(\d{4})\.\s*(.+)\z/)
    return [] unless m

    year = m[1].to_i
    out  = []
    cur_month = nil

    m[2].split(',').each do |seg|
      seg = seg.strip
      next if seg.empty?

      if (x = seg.match(/\A(\d{1,2})\.(\d{1,2})#{DASH}(\d{1,2})\.(\d{1,2})\z/))
        cur_month = x[3].to_i
        out.concat(expand_cross(year, x[1].to_i, x[2].to_i, x[3].to_i, x[4].to_i))

      elsif (x = seg.match(/\A(\d{1,2})\.(\d{1,2})#{DASH}(\d{1,2})\z/))
        mo, d1, d2 = x[1].to_i, x[2].to_i, x[3].to_i
        cur_month = mo
        next if d2 < d1 || (d2 - d1) > MAX_SPAN
        (d1..d2).each { |d| out << date_str(year, mo, d) }

      elsif (x = seg.match(/\A(\d{1,2})\.(\d{1,2})\z/))
        cur_month = x[1].to_i
        out << date_str(year, x[1].to_i, x[2].to_i)

      elsif (x = seg.match(/\A(\d{1,2})#{DASH}(\d{1,2})\z/)) && cur_month
        d1, d2 = x[1].to_i, x[2].to_i
        next if d2 < d1 || (d2 - d1) > MAX_SPAN
        (d1..d2).each { |d| out << date_str(year, cur_month, d) }

      elsif (x = seg.match(/\A(\d{1,2})\z/)) && cur_month
        out << date_str(year, cur_month, x[1].to_i)
      end
    end

    out.compact.uniq.sort
  end

  def split_city(cell)
    s = cell.to_s.strip
    flag = s[FLAG_REGEX]
    name = s.sub(FLAG_REGEX, '').strip
    [flag, name]
  end

  # 공연장 셀 → [이름, url]
  # ⚠️ 이 generator 는 :lowest 라 bidirectional_links_generator 가 이미 [[링크]] 를
  #    <a class='internal-link' href='...'>이름</a> 로 바꾼 뒤다. 두 형태 모두 처리.
  def venue_ref(cell)
    s = cell.to_s.strip
    return [nil, nil] if s.empty? || s =~ /미정|TBA/i

    if (x = s.match(/<a[^>]*href=['"]([^'"]+)['"][^>]*>(.*?)<\/a>/m))
      [x[2].gsub(/<[^>]+>/, '').strip, x[1]]
    elsif (x = s.match(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/))
      [x[1].strip, nil]
    else
      plain = s.gsub(/<[^>]+>/, '').gsub(/[*_`]/, '').strip
      plain.empty? ? [nil, nil] : [plain, nil]
    end
  end

  def cancelled?(note_cell)
    s = note_cell.to_s
    s.include?('취소') || s.include?('❌')
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest # places_generator(:low) 가 site.data['places'] 채운 뒤 실행

    def generate(site)
      by_title = {}
      by_url   = {}
      Array(site.data['places']).each do |p|
        by_title[p['title'].to_s] = p
        by_url[p['url'].to_s]     = p
      end

      shows = []
      site.collections['notes'].docs.each do |note|
        content = note.content.to_s
        next unless content =~ /\|\s*날짜\s*\|/ && content =~ /\|\s*공연장\s*\|/

        tour_title = note.data['title'].to_s
        rows = content.lines.map(&:strip).select { |l| l.start_with?('|') }

        rows.each do |line|
          cells = line.split('|').map(&:strip)
          cells.shift if cells.first.to_s.empty?
          cells.pop   if cells.last.to_s.empty?
          next if cells.size < 3
          next if cells[0] =~ /\A날짜\z/ || cells[0] =~ /\A-+\z/

          dates = TourScheduleGenerator.parse_dates(cells[0])
          next if dates.empty?

          flag, city       = TourScheduleGenerator.split_city(cells[1])
          venue, venue_url = TourScheduleGenerator.venue_ref(cells[2])
          remark           = cells[3].to_s

          place = (venue_url && by_url[venue_url]) || (venue && by_title[venue])
          shows << {
            'tour'       => tour_title,
            'tour_url'   => note.url,
            'date_raw'   => cells[0],
            'dates'      => dates,
            'start'      => dates.first,
            'end'        => dates.last,
            'flag'       => flag,
            'city'       => city,
            'venue'      => venue,
            'venue_url'  => (place && place['url']) || venue_url,
            'lat'        => place && place['lat'],
            'lng'        => place && place['lng'],
            'cancelled'  => TourScheduleGenerator.cancelled?(remark),
            'remark'     => remark.gsub(/\*\*/, '').strip
          }
        end
      end

      shows.sort_by! { |s| [s['start'], s['tour']] }
      site.data['tour_shows'] = shows

      if defined?(Jekyll)
        no_coord = shows.count { |s| s['venue'] && s['lat'].nil? }
        Jekyll.logger.info('TourSchedule', "공연 #{shows.size}건 파싱 (좌표없음 #{no_coord}, TBA #{shows.count { |s| s['venue'].nil? }})")
      end
    end
  end
end
