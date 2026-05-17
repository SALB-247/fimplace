# frozen_string_literal: true
#
# 태그 / 멤버 별 인덱스 페이지 자동 생성
#
#   /tag/{tagname}/      - 해당 태그가 달린 노트 목록
#   /member/{member}/    - 해당 멤버가 등장하는 노트 목록
#
# 각 페이지는 _layouts/term_index.html 을 사용

module TermPages
  class TermPage < Jekyll::Page
    def initialize(site, base, kind, term, notes)
      @site = site
      @base = base
      @dir  = "#{kind}/#{term}"
      @name = 'index.html'

      self.process(@name)
      self.data = {
        'layout' => 'term_index',
        'title'  => kind == 'member' ? "#{term} 관련 장소" : "##{term}",
        'kind'   => kind,
        'term'   => term,
        'notes'  => notes.sort_by { |n| -(n.data['last_modified_at_timestamp'].to_s.tr('-:T', '').to_i) }
      }
    end
  end

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      notes = site.collections['notes'].docs

      # 태그 인덱스
      tags = Hash.new { |h, k| h[k] = [] }
      notes.each do |n|
        Array(n.data['tags']).each { |t| tags[t.to_s] << n }
      end
      tags.each do |term, ns|
        site.pages << TermPage.new(site, site.source, 'tag', term, ns)
      end

      # 멤버 인덱스
      members = Hash.new { |h, k| h[k] = [] }
      notes.each do |n|
        Array(n.data['members']).each { |m| members[m.to_s] << n }
      end
      members.each do |term, ns|
        site.pages << TermPage.new(site, site.source, 'member', term, ns)
      end

      # site 변수에 노출 (목록 페이지에서 사용)
      site.data['all_tags']    = tags.map    { |t, ns| { 'name' => t, 'count' => ns.size } }.sort_by { |x| -x['count'] }
      site.data['all_members'] = members.map { |m, ns| { 'name' => m, 'count' => ns.size } }.sort_by { |x| -x['count'] }
    end
  end
end
