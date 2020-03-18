# frozen_string_literal: true

require 'octokit'
require 'open-uri'

REPO = 'esrlabs/chipmunk-plugins-store'

class Github
  def initialize
    if !ENV['GITHUB_LOGIN'].nil? && !ENV['GITHUB_PASW'].nil? &&
       ENV['GITHUB_LOGIN'] != '' && ENV['GITHUB_PASW'] != ''
      puts 'Login to Github using login/password'
      @client = Octokit::Client.new(login: ENV['GITHUB_LOGIN'], password: ENV['GITHUB_PASW'])
    else
      puts 'Login to Github using token'
      @client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    end
    @tag = self.class.detect_last_tag(@client)
    puts "Detected tag: #{@tag}"
  end

  def get_releases_list(target)
    puts 'Getting latest release'
    release = @client.latest_release(REPO, {})
    puts 'Getting assets latest release'
    assets = @client.release_assets(release.url, {})
    release_file_asset = nil
    assets.each do |a|
      release_file_asset = a if a.name == target
    end
    raise "Fail to find latest release file on repo #{REPO}" if release_file_asset.nil?

    puts "Reading releases file from \"#{release_file_asset.browser_download_url}\""
    release_file_asset_contents = URI.open(release_file_asset.browser_download_url, &:read)
    releases = JSON.parse(release_file_asset_contents)
    releases
  end

  def get_last_tag
    @tag
  end

  def self.detect_last_tag(client)
    if ENV.key?('GITHUB_REF')
      tag = ENV['GITHUB_REF'].dup.sub!('refs/tags/', '')
      if !tag.nil? && !tag.empty? && Gem::Version.correct?(tag)
        puts 'Tag was exctracted from REF'
        return tag
      end
    end
    tags = client.tags(REPO, {})
    raise "At least one tag should be defined on #{REPO}" if tags.empty?

    tags = tags.sort { |a, b| Gem::Version.new(b.name) <=> Gem::Version.new(a.name) }
    puts "Tag was gotten from list of repo's tags"
    tags[0].name
  end
end
