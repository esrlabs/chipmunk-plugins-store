# frozen_string_literal: true

require 'json'

PLUGINS_REGISTER_FILE = './plugins.json'

class Register
  def initialize
    unless File.file?(PLUGINS_REGISTER_FILE)
      raise "Fail to find register file: #{PLUGINS_REGISTER_FILE}"
    end

    @register_str = File.read(PLUGINS_REGISTER_FILE.to_s)
    @plugins = JSON.parse(@register_str)
    @cursor = 0
    puts "Register file #{PLUGINS_REGISTER_FILE} is read. Found #{@plugins.length} entries"
  end

  def self.validate(entry)
    unless entry.key?('name')
      puts 'Field "name" not found'
      return false
    end
    unless entry.key?('repo')
      puts 'Field "repo" not found'
      return false
    end
    unless entry.key?('version')
      puts 'Field "version" not found'
      return false
    end
    true
  end

  def self.normalize(entry)
    entry['default'] = false unless entry.key?('default')
    entry['has_to_be_signed'] = false unless entry.key?('has_to_be_signed')
    entry
  end

  def next
    return nil if @cursor >= @plugins.length

    loop do
      return nil if @cursor >= @plugins.length

      @cursor += 1
      if self.class.validate(@plugins[@cursor - 1])
        return self.class.normalize(@plugins[@cursor - 1])
      end
    end
  end

  def get_by_name(name)
    result = nil
    @plugins.each do |plugin|
      result = self.class.normalize(plugin) if plugin['name'] == name
    end
    result
  end
end
