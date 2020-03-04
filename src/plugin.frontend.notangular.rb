# frozen_string_literal: true

require 'json'

class PluginFrontendNotAngular
  def initialize(path, versions, package_json)
    @path = path
    @versions = versions
    @package_json = package_json
    @error = ""
  end

  def is
    return false if File.file?("#{@path}/#{PLUGIN_FRONTEND_ANGULAR_PACKAGE}")

    true
  end

  def valid
    unless @package_json.key?('name')
      @error = 'Field "name" not found in package.json'
      puts @error
      return false
    end
    true
  end

  def install
    Rake.cd @path do
      puts 'Install'
      Rake.sh 'npm install --prefere-offline'
      puts 'Build'
      Rake.sh 'npm run build'
      puts 'Remove node_modules'
      Rake.rm_r('./node_modules', force: true)
      puts 'Install in production'
      Rake.sh 'npm install --production --prefere-offline'
    end
    true
  rescue StandardError => e
    @error = e.message
    puts @error
    return false
  end

  def get_dist_path
    @path
  end

  def get_error
    @error
  end
end
