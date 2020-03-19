# frozen_string_literal: true

require 'json'
require './src/github'
require './src/tools'

RELEASES_FILE_NAME = 'releases'
RELEASE_URL_PATTERN = 'https://github.com/esrlabs/chipmunk-plugins-store/releases/download/${tag}/${file_name}'

class Releases
  def initialize(register, versions)
    @register = register
    @versions = versions
    @git = Github.new
    @releases = self.class.validate(@git.get_releases_list(self.class.get_name))
    @tag = @git.get_last_tag
  end

  def exist(file_name)
    result = false
    @releases.each do |release|
      result = true if release['file'] == file_name
    end
    result
  end

  def has_to_be_update(name, dependencies)
    last = nil
    @releases.each do |release|
      last = release if release['name'] == name
    end
    if last.nil?
      # No release found
      return true
    end

    basic = @register.get_by_name(name)
    if basic.nil?
      # Plugin is excluded from basic register (plugins.json)
      return false
    end

    if Gem::Version.new(last['version']) != Gem::Version.new(basic['version'])
      # Version of plugin is dismatch
      puts "Plugin\"#{name}\" has to be updated because last built version of plugin: #{last['version']}, but new: #{basic['version']} "
      return true
    end
    phash = @versions.get_dep_hash(dependencies)
    if Gem::Version.new(last['phash']) != Gem::Version.new(phash)
      # Plugin's hash is dismatch
      puts "Plugin\"#{name}\" has to be updated because last built phash of plugin: #{last['phash']}, but new: #{phash} "
      return true
    end
    # No need to update plugin
    false
  end

  def add(name, file_name, version, dependencies)
    @releases = @releases.reject do |release|
      release['name'] == name
    end
    @releases.push({
                     'name' => name,
                     'file' => file_name,
                     'version' => version,
                     'dependencies' => dependencies,
                     'phash' => @versions.get_dep_hash(dependencies),
                     'url' => RELEASE_URL_PATTERN.sub('${tag}', @tag).sub('${file_name}', file_name)
                   })
  end

  def write
    unless File.directory?(PLUGIN_RELEASE_FOLDER)
      Rake.mkdir_p(PLUGIN_RELEASE_FOLDER, verbose: true)
      puts "Creating release folder: #{PLUGIN_RELEASE_FOLDER}"
    end
    File.open("./#{PLUGIN_RELEASE_FOLDER}/#{self.class.get_name}", 'w') do |f|
      f.write(@releases.to_json)
    end
  end

  def normalize(register)
    result = []
    @releases.each do |release|
      plugin = register.get_by_name(release['name'])
      next if plugin.nil?
      result.push({
                    'name' => release['name'],
                    'file' => release['file'],
                    'version' => release['version'],
                    'url' => release['url'],
                    'dependencies' => release['dependencies'],
                    'phash' => release['phash'],
                    'hash' => @versions.get_hash,
                    'display_name' => plugin['display_name'],
                    'description' => plugin['description'],
                    'readme' => plugin['readme'],
                    'icon' => plugin['icon'],
                    'default' => plugin['default'],
                    'signed' => plugin['has_to_be_signed'],
                    'history' => self.class.get_history(release, @versions.get_hash)
                  })
    end
    @releases = result
  end

  def get_url(file_name)
    RELEASE_URL_PATTERN.sub('${tag}', @tag).sub('${file_name}', file_name)
  end

  def self.get_name
    "#{RELEASES_FILE_NAME}-#{get_nodejs_platform}.json"
  end

  def self.validate(releases)
    result = []
    releases.each do |release|
      release['phash'] = release['hash'] unless release.key?('phash')
      unless release.key?('dependencies')
        release['dependencies'] = {
          'electron' => true,
          'electron-rebuild' => true,
          'chipmunk.client.toolkit' => true,
          'chipmunk.plugin.ipc' => true,
          'chipmunk-client-material' => true,
          'angular-core' => true,
          'angular-material' => true,
          'force' => true
        }
      end
      result.push(release)
    end
    result
  end

  def self.get_history(release, hash)
    history = []
    history = release['history'] if release.key?('history')
    key = "#{release['phash']}#{hash}#{release['version']}"
    exists = history.detect { |r| key == "#{r['phash']}#{r['hash']}#{r['version']}" }
    return history unless exists.nil?
    history.unshift({
                   'phash' => release['phash'],
                   'hash' => hash,
                   'url' => release['url'],
                   'version' => release['version']
                 })
    history
  end
end
