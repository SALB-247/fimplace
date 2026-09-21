# frozen_string_literal: true
#
# 장소·공연의 IANA 시간대 결정 (2026-09-22, 현지 시간 모듈)
#
# 원본은 _data/timezones.yml (venues / cities / countries). 우선순위:
#   노트 frontmatter timezone → venues[제목] → cities[도시 셀·도시 태그] → countries[국가 코드, 단일 시간대 국가만] → nil
# 결과는 tour_schedule.json(time_zone) · places.json(time_zone) · events.json(time_zone) 에 실리고,
# 브라우저의 _includes/fim_time.html (window.FimTime) 이 '공연장 현지 오늘' 로 지난/오늘/예정을 판정한다.
# 국가 코드만으로 다중 시간대 국가(us·mx·id…)를 추정하지 않는다 — 도시로 못 찾으면 nil 로 두고 화면에 '시간대 확인 필요'.

module FimTz
  module_function

  def table(site)
    site.data['timezones'] || {}
  end

  def clean_city(s)
    s.to_s.gsub(/[\u{1F1E6}-\u{1F1FF}]{2}/, '').sub(/\s*\(.*\)\s*\z/, '').strip
  end

  # note: 공연장 노트(있으면), venue: 제목 문자열, cities: 도시 후보(도시 셀·태그 배열), country: 국가 코드
  def resolve(site, note: nil, venue: nil, cities: [], country: nil)
    t = table(site)
    tz = note && note.data['timezone'].to_s
    return tz if tz && !tz.empty?
    v = (t['venues'] || {})[venue.to_s]
    return v if v
    Array(cities).each do |c|
      cc = clean_city(c)
      next if cc.empty?
      x = (t['cities'] || {})[cc]
      return x if x
    end
    (t['countries'] || {})[country.to_s.downcase]
  end
end
