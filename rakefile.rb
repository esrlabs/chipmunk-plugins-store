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
  failed = ''
  count = 0
  done = 0

  puts "Current versions hash:\n\t#{versions.get_hash}\n"

  loop do
    plugin_info = register.next
    break if plugin_info.nil?

    next unless target.nil? || (!target.nil? && plugin_info['name'] == target)

    plugin = Plugin.new(plugin_info, PLUGINS_DEST_FOLDER, versions, releases, rebuild)
    if plugin.build
      plugin.cleanup if clean
      puts "Plugin #{plugin_info['name']} is built SUCCESSFULLY"
      done += 1
    else
      failed += "FAIL to build plugin #{plugin_info['name']}\n"
    end
    count += 1
    summary += plugin.get_summary
  end
  releases.normalize(register)
  releases.write
  cleanup(false) if clean
  puts "\n\n#{'=' * 50}\nSummary: built #{done} from #{count}\n#{'=' * 50}"
  puts summary
  if failed != ''
    puts "\n\n#{'=' * 50}\nBuild of #{count - done} is FAILED\n#{'=' * 50}"
    puts failed
    STDERR.puts("#{count - done} from #{count} are FAILED")
    exit(false)
  end
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
