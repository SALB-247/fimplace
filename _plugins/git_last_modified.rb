# frozen_string_literal: true
#
# 노트·페이지의 "최초 작성일(published)" 과 "마지막 수정일(modified)" 을 git 이력에서 한 번에 뽑아 주입한다.
#
# 배경: 예전엔 jekyll-last-modified-at 젬이 문서마다 `git log` 서브프로세스를 띄웠고
#       (Recents 생성기 + 레이아웃 + 사이트맵 = 노트당 최대 3회) 빌드 240초 중 ~130초가 여기서 나갔다.
#       이 플러그인은 `git log --name-status` 단 1회로 경로→(최초 커밋일, 최종 커밋일) 맵을 만든다 (약 0.2초).
#
# 주입 키:
#   data['last_modified_at']           Time   — note.html / term_index.html / feed.xml / jekyll-sitemap
#   data['last_modified_at_timestamp'] String — tag_pages_generator 정렬용 (ISO8601)
#   data['created_at']                 Time   — 최초 커밋일 (head.html 의 article:published_time.
#                                                예전엔 page.date = 빌드 시각이라 published_time 이 빌드마다 바뀌었음)
#
# 리네임(-M) 을 따라가므로 파일명을 바꿔도 최초 작성일이 유지된다. 삭제 후 재생성된 파일은 재생성 시점부터 센다.
# git 에 없는 파일(미커밋 신규 노트) 은 파일 mtime 으로 대체.
# ※ Netlify 등 shallow clone 환경에선 이력이 잘려 mtime(=체크아웃 시각) 으로 떨어질 수 있다.
require 'open3'

module GitLastModified
  class Generator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      toplevel, last, first = git_dates(site.source)
      docs = site.collections.values.flat_map(&:docs) + site.pages
      hit = miss = 0
      docs.each do |d|
        abs = d.respond_to?(:path) ? d.path.to_s : ''
        next if abs.empty?
        abs = File.expand_path(abs, site.source) unless Pathname.new(abs).absolute?
        rel = relative_to(abs, toplevel)
        modified = rel && last[rel]
        created  = rel && first[rel]
        if modified then hit += 1
        else
          miss += 1
          modified = File.exist?(abs) ? File.mtime(abs) : Time.now
        end
        created ||= modified
        d.data['last_modified_at'] = modified
        d.data['last_modified_at_timestamp'] = modified.strftime('%FT%T%:z')
        d.data['created_at'] = created
        # ⚠️ data['date'] 는 건드리지 않는다. places_generator.extract_date 가 frontmatter date 를 최우선으로 쓰기 때문에
        #    여기서 채우면 장소의 대표 날짜(메모줄·방문일)가 git 최초 커밋일로 덮여 버린다 (2026-09 회귀 사례).
        #    published_time 은 head.html 이 created_at 을 직접 읽는다.
      end
      Jekyll.logger.info 'git_last_modified:', "git #{hit}건 / mtime 대체 #{miss}건"
    end

    private

    # git log 1회 → [toplevel, { 경로(NFC) => 최종 커밋 Time }, { 경로(NFC) => 최초 커밋 Time }]
    # 출력은 최신순. --name-status 로 A/M/D/R 을 받아 리네임은 새 이름으로 이력을 잇고, 삭제(D) 이전 이력은 끊는다.
    def git_dates(source)
      top, st = Open3.capture2('git', '-C', source, 'rev-parse', '--show-toplevel')
      return [nil, {}, {}] unless st.success?
      top = top.strip.force_encoding('UTF-8')
      out, st = Open3.capture2('git', '-C', source, '-c', 'core.quotepath=false',
                               'log', '-M', '--format=%x00%cI', '--name-status')
      return [top, {}, {}] unless st.success?
      out.force_encoding('UTF-8')

      last, first, aliases, sealed = {}, {}, {}, {}
      canon = lambda do |p|
        p = p.unicode_normalize(:nfc)
        hops = 0
        while aliases[p] && hops < 64
          p = aliases[p]; hops += 1
        end
        p
      end

      out.split("\0").each do |chunk|
        lines = chunk.split("\n").map(&:strip).reject(&:empty?)
        next if lines.empty?
        time = (Time.iso8601(lines.shift) rescue nil)
        next unless time
        lines.each do |line|
          parts = line.split("\t")
          status = parts[0].to_s
          if status.start_with?('R', 'C')
            old_p, new_p = parts[1], parts[2]
            next unless old_p && new_p
            c = canon.call(new_p)
            next if sealed[c]
            last[c] ||= time
            first[c] = time
            aliases[old_p.unicode_normalize(:nfc)] = c if status.start_with?('R')   # 복사(C)는 원본 이력을 잇지 않음
          else
            path = parts[1]
            next unless path
            c = canon.call(path)
            if status == 'D'
              sealed[c] = true      # 이보다 오래된 이력은 '이전 파일' 의 것
              next
            end
            next if sealed[c]
            last[c] ||= time        # 최신순이므로 첫 등장 = 최종 수정
            first[c] = time         # 계속 덮어써서 마지막 등장 = 최초 작성
          end
        end
      end
      [top, last, first]
    rescue StandardError => e
      Jekyll.logger.warn 'git_last_modified:', "git 조회 실패 (#{e.message}) — mtime 사용"
      [nil, {}, {}]
    end

    def relative_to(abs, top)
      return nil unless top
      a = abs.tr('\\', '/').unicode_normalize(:nfc)
      t = top.tr('\\', '/').unicode_normalize(:nfc).chomp('/') + '/'
      return nil unless a.downcase.start_with?(t.downcase)
      a[t.length..]
    end
  end
end
