# If the configuration sets `open_external_links_in_new_tab` to a truthy value,
# add 'target=_blank' to anchor tags that don't have `internal-link` class

# frozen_string_literal: true
require 'nokogiri'

Jekyll::Hooks.register [:notes], :post_convert do |doc|
  convert_links(doc)
end

Jekyll::Hooks.register [:pages], :post_convert do |doc|
  # jekyll considers anything at the root as a page,
  # we only want to consider actual pages
  next unless doc.path.start_with?('_pages/')
  convert_links(doc)
end

def convert_links(doc)
  return unless !!doc.site.config["open_external_links_in_new_tab"]

  # 사이트 자기 호스트 (자기 사이트 절대 URL 은 외부로 보지 않음)
  site_url = doc.site.config["url"].to_s.sub(%r{/\z}, '')

  parsed_doc = Nokogiri::HTML::DocumentFragment.parse(doc.content)
  parsed_doc.css("a:not(.internal-link):not(.footnote):not(.reversefootnote)").each do |link|
    href = link.get_attribute('href').to_s.strip
    next if href.empty?
    # 외부 링크(다른 호스트의 http/https)에만 새 창. 상대/내부 링크(/tag/, /map/, #anchor, mailto 등)는 같은 탭.
    next unless href =~ %r{\Ahttps?://}i
    next if site_url != '' && href.start_with?(site_url)
    link.set_attribute('target', '_blank')
    link.set_attribute('rel', 'noopener')   # tabnabbing 방지
  end
  doc.content = parsed_doc.inner_html
end
