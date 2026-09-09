# frozen_string_literal: true
#
# 변경되지 않은 정적 파일(assets/ 등)은 _site 로 다시 복사하지 않는다.
#
# Jekyll 은 한 프로세스 안에서만 mtime 캐시를 유지해서, 매번 새로 도는 `jekyll build` 는
# 573MB 짜리 assets/ 를 통째로 다시 복사한다 (로컬 빌드의 write 단계 ~24초).
# 목적지 파일이 이미 있고 크기가 같고 mtime 이 원본 이상이면 복사를 건너뛴다.
# (copy_file 이 목적지 mtime 을 원본과 같게 맞추므로 정상 복사본은 항상 이 조건을 만족.)
# 원본이 수정되면 mtime 이 앞서므로 그대로 복사된다. Netlify 처럼 매번 새 환경이면 전부 복사 (기존과 동일).

module StaticFileSkipUnchanged
  def write(dest)
    dest_path = destination(dest)
    # StaticFile#mtime 은 Integer(epoch) 를 돌려주므로 같은 단위로 비교
    if File.file?(dest_path) &&
       File.size(dest_path) == File.size(path) &&
       File.mtime(dest_path).to_i >= mtime
      self.class.mtimes[path] = mtime
      return false
    end
    super
  end
end

Jekyll::StaticFile.prepend(StaticFileSkipUnchanged)
