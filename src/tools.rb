# frozen_string_literal: true

require './src/os'

def copy_dist(from, to)
  unless File.directory?(to)
    Rake.mkdir_p(to, verbose: true)
    puts "Creating destination folder: #{to}"
  end
  src = "#{from}/src"
  if File.directory?(src)
    puts 'Remove sources'
    Rake.rm_r(src, force: true)
  end
  puts "Copy dist from #{from} to #{to}"
  Rake.cp_r("#{from}/.", to, verbose: false)
end

def compress(output_file, pwd, dest)
  if OS.windows?
    Rake.sh "tar -czf #{output_file} -C #{pwd} #{dest} --force-local"
  else
    Rake.sh "tar -czf #{output_file} -C #{pwd} #{dest} "
  end
end

def cleanup(all)
  Rake.rm_r(TMP_FOLDER, force: true) if File.directory?(TMP_FOLDER)
  Rake.rm_r(PLUGINS_DEST_FOLDER, force: true) if File.directory?(PLUGINS_DEST_FOLDER)
  if all
    Rake.rm_r(PLUGIN_RELEASE_FOLDER, force: true) if File.directory?(PLUGIN_RELEASE_FOLDER)
  end
end
