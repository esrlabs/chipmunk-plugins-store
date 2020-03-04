# frozen_string_literal: true

require 'json'

VERSIONS_FILE = './versions.json'

class Versions
  def initialize
    unless File.file?(VERSIONS_FILE)
      raise "Fail to find versions file: #{VERSIONS_FILE}"
    end

    @versions_str = File.read(VERSIONS_FILE.to_s)
    @versions = JSON.parse(@versions_str)
    puts "Next versions of frameworks/modules will be used:\n"
    puts "\telectron: #{@versions['electron']}\n"
    puts "\telectron-rebuild: #{@versions['electron-rebuild']}\n"
    puts "\tchipmunk.client.toolkit: #{@versions['chipmunk.client.toolkit']}\n"
    puts "\tchipmunk.plugin.ipc: #{@versions['chipmunk.plugin.ipc']}\n"
    puts "\tchipmunk-client-material: #{@versions['chipmunk-client-material']}\n"
    puts "\tangular-core: #{@versions['angular-core']}\n"
    puts "\tangular-material: #{@versions['angular-material']}\n"
    puts "\tforce: #{@versions['force']}\n"
  end

  def get
    @versions
  end

  def get_hash
    p = [
      @versions['electron'].split('.'),
      @versions['electron-rebuild'].split('.'),
      @versions['chipmunk.client.toolkit'].split('.'),
      @versions['chipmunk.plugin.ipc'].split('.'),
      @versions['chipmunk-client-material'].split('.'),
      @versions['angular-core'].split('.'),
      @versions['angular-material'].split('.'),
      @versions['force'].split('.')
    ]
    self.class.hash(p)
  end

  def get_dep_hash(dependencies)
    skip = ['', '', '']
    p = [
      dependencies['electron'] ? @versions['electron'].split('.') : skip,
      dependencies['electron-rebuild'] ? @versions['electron-rebuild'].split('.') : skip,
      dependencies['chipmunk.client.toolkit'] ? @versions['chipmunk.client.toolkit'].split('.') : skip,
      dependencies['chipmunk.plugin.ipc'] ? @versions['chipmunk.plugin.ipc'].split('.') : skip,
      dependencies['chipmunk-client-material'] ? @versions['chipmunk-client-material'].split('.') : skip,
      dependencies['angular-core'] ? @versions['angular-core'].split('.') : skip,
      dependencies['angular-material'] ? @versions['angular-material'].split('.') : skip,
      dependencies['force'] ? @versions['force'].split('.') : skip
    ]
    self.class.hash(p)
  end

  def self.hash(p)
    hash = ''
    (0..2).each do |i|
      hash = "#{hash}." if hash != ''
      p.each do |x|
        hash = "#{hash}#{x[i]}"
      end
    end
    hash
  end
end
