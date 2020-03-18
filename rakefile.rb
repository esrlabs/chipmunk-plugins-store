# frozen_string_literal: true

require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/releases'

PLUGINS_DEST_FOLDER = './plugins'
PLUGIN_RELEASE_FOLDER = './releases'

def build(target, rebuild, clean)
  register = Register.new
  versions = Versions.new
  releases = Releases.new(register, versions)
  summary = ''

  puts "Current versions hash:\n\t#{versions.get_hash}\n"

  loop do
    plugin_info = register.next
    break if plugin_info.nil?

    next unless target.nil? || (!target.nil? && plugin_info['name'] == target)

    plugin = Plugin.new(plugin_info, PLUGINS_DEST_FOLDER, versions, releases, rebuild)
    if plugin.build
      plugin.cleanup if clean
      puts "Plugin #{plugin_info['name']} is built SUCCESSFULLY"
    else
      puts "Fail to build plugin #{plugin_info['name']}"
    end
    summary += plugin.get_summary
  end
  releases.normalize(register)
  releases.write
  cleanup(false) if clean
  puts summary
end

task :build, [:target] do |_t, args|
  build(args.target, false, true)
end

task :rebuild, [:target] do |_t, args|
  build(args.target, true, false)
end

task :clean do
  cleanup(true)
end
