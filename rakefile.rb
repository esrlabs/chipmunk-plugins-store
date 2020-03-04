# frozen_string_literal: true

require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/releases'

PLUGINS_DEST_FOLDER = './plugins'
PLUGIN_RELEASE_FOLDER = './releases'

task :build, [:target] do |_t, args|
  register = Register.new
  versions = Versions.new
  releases = Releases.new(register, versions)
  summary = ''

  puts "Current versions hash:\n\t#{versions.get_hash}\n"

  loop do
    plugin_info = register.next
    break if plugin_info.nil?

    next unless args.target.nil? || (!args.target.nil? && plugin_info['name'] == args.target)

    plugin = Plugin.new(plugin_info, PLUGINS_DEST_FOLDER, versions, releases)
    if plugin.build
      plugin.cleanup
      puts "Plugin #{plugin_info['name']} is built SUCCESSFULLY"
    else
      puts "Fail to build plugin #{plugin_info['name']}"
    end
    summary += plugin.get_summary
  end
  releases.normalize(register)
  releases.write
  cleanup
  puts summary
end
