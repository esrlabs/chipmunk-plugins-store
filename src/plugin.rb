# frozen_string_literal: true

require 'json'
require 'fileutils'
require './src/plugin.backend'
require './src/plugin.frontend'
require './src/tools'

class Plugin
  def initialize(info, path, versions, releases, rebuild)
    @info = info
    @path = path
    @versions = versions
    @root = "#{@path}/#{@info['name']}"
    @releases = releases
    @rebuild = rebuild
    @summary = "Plugin \"#{@info['name']}\" summary:\n"
  end

  def build
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    target_file_name = self.class.get_name(@info['name'], @versions.get_hash, @info['version'])
    # Check version of plugin and make decision: update or not update (build or not build)
    if @releases.exist(target_file_name) && !@rebuild
      puts "No need to build plugin #{@info['name']} because it's already exist"
      @summary += "Building is skipped: release already exists\n"
      @releases.write
      return true
    end
    self.class.clone(@info['name'], @info['repo'], @path)
    backend = PluginBackend.new(@root, @versions.get, @info['has_to_be_signed'])
    frontend = PluginFrontend.new(@root, @versions.get)
    dependencies = self.class.get_dependencies(backend, frontend)
    if !@releases.has_to_be_update(@info['name'], dependencies) && !@rebuild
      puts 'Available version of plugin is actual. No need to rebuild.'
      @summary += "Building is skipped: release is still actual\n"
      @releases.write
      return true
    end
    if !backend.exist
      puts "Plugin \"#{@info['name']}\" doesn't have backend"
      @summary += "\t- backend: -\n"
    else
      unless backend.valid
        puts "Fail to build plugin \"#{@info['name']}\" because backend isn't valid"
        @summary += "Backend of plugin isn't valid: #{backend.get_error}\n"
        return false
      end
      if backend.install
        puts "Install backend of \"#{@info['name']}\": SUCCESS"
        @summary += "\t- backend: OK\n"
      else
        puts "Install backend of \"#{@info['name']}\": FAIL"
        @summary += "Fail to build backend: #{backend.get_error}\n"
        return false
      end
    end
    if !frontend.exist
      puts "Plugin \"#{@info['name']}\" doesn't have frontend"
      @summary += "\t- frontend: -\n"
    else
      unless frontend.valid
        puts "Fail to build plugin \"#{@info['name']}\" because frontend isn't valid"
        @summary += "Frontend of plugin isn't valid: #{frontend.get_error}\n"
        return false
      end
      if frontend.install
        puts "Install frontend of \"#{@info['name']}\": SUCCESS"
        @summary += "\t- frontend: OK\n"
      else
        puts "Install frontend of \"#{@info['name']}\": FAIL"
        @summary += "Fail to build frontend: #{frontend.get_error}\n"
        return false
      end
    end
    if backend.get_state.nil? || frontend.get_state.nil?
      puts "Fail to build plugin \"#{@info['name']}\" because backend or frontend weren't installed correctly"
      @summary += "Plugin doesn't have not frontend, not backend\n"
      return false
    end
    if backend.get_state && !frontend.get_state
      puts "Fail to build plugin \"#{@info['name']}\" because plugin has only backend"
      @summary += "Plugin cannot have only backend\n"
      return false
    end
    unless File.directory?(PLUGIN_RELEASE_FOLDER)
      Rake.mkdir_p(PLUGIN_RELEASE_FOLDER, verbose: true)
      puts "Creating release folder: #{TMP_FOLDER}"
    end
    dest = "#{PLUGIN_RELEASE_FOLDER}/#{@info['name']}"
    unless File.directory?(dest)
      Rake.mkdir_p(dest, verbose: true)
      puts "Creating plugin release folder: #{dest}"
    end
    copy_dist(backend.get_path, "#{dest}/process") if backend.get_state
    copy_dist(frontend.get_path, "#{dest}/render") if frontend.get_state
    file_name = self.class.get_name(@info['name'], @versions.get_hash, @info['version'])
    self.class.add_info(dest, {
                          'name' => @info['name'],
                          'file' => file_name,
                          'version' => @info['version'],
                          'hash' => @versions.get_hash,
                          'phash' => @versions.get_dep_hash(dependencies),
                          'url' => @releases.get_url(file_name),
                          'display_name' => @info['display_name'],
                          'description' => @info['description'],
                          'readme' => @info['readme'],
                          'icon' => @info['icon'],
                          'dependencies' => dependencies
                        })
    compress("#{PLUGIN_RELEASE_FOLDER}/#{file_name}", PLUGIN_RELEASE_FOLDER, @info['name'])
    @releases.add(@info['name'], file_name, @info['version'], dependencies)
    @releases.write
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @summary += "Dependencies:\n"
    @summary += "\t- electron: #{dependencies['electron'] ? 'TRUE' : '-'}\n"
    @summary += "\t- electron-rebuild: #{dependencies['electron-rebuild'] ? 'TRUE' : '-'}\n"
    @summary += "\t- chipmunk.client.toolkit: #{dependencies['chipmunk.client.toolkit'] ? 'TRUE' : '-'}\n"
    @summary += "\t- chipmunk.plugin.ipc: #{dependencies['chipmunk.plugin.ipc'] ? 'TRUE' : '-'}\n"
    @summary += "\t- chipmunk-client-material: #{dependencies['chipmunk-client-material'] ? 'TRUE' : '-'}\n"
    @summary += "\t- angular-core: #{dependencies['angular-core'] ? 'TRUE' : '-'}\n"
    @summary += "\t- angular-material: #{dependencies['angular-material'] ? 'TRUE' : '-'}\n"
    @summary += "\t- force: #{dependencies['force'] ? 'TRUE' : '-'}\n"
    @summary += "Other:\n"
    @summary += "\t- sign: #{!backend.exist ? 'no backend' : backend.get_sign_state}\n"
    @summary += "\t- hash: #{@versions.get_hash}\n"
    @summary += "\t- plugin hash: #{@versions.get_dep_hash(dependencies)}\n"
    @summary += "\t- built in: #{(ending - starting)}s\n"
    true
  end

  def get_summary
    "#{'=' * 50}\n#{@summary}#{'=' * 50}\n"
  end

  def cleanup
    puts "Cleanup #{@info['name']}"
    Rake.rm_r(@root, force: true)
    Rake.rm_r("#{PLUGIN_RELEASE_FOLDER}/#{@info['name']}", force: true)
  end

  def self.get_dependencies(backend, frontend)
    dependencies = {
      'electron' => false,
      'electron-rebuild' => false,
      'chipmunk.client.toolkit' => false,
      'chipmunk.plugin.ipc' => false,
      'chipmunk-client-material' => false,
      'angular-core' => false,
      'angular-material' => false,
      'force' => true
    }
    if backend.exist
      dependencies['electron'] = true
      dependencies['electron-rebuild'] = true
      dependencies['chipmunk.plugin.ipc'] = true
    end
    if frontend.exist
      if frontend.has_angular
        dependencies['chipmunk.client.toolkit'] = true
        dependencies['chipmunk-client-material'] = true
        dependencies['angular-core'] = true
        dependencies['angular-material'] = true
      else
        dependencies['chipmunk.client.toolkit'] = true
      end
    end
    dependencies
  end

  def self.clone(name, repo, path)
    unless File.directory?(path)
      Rake.mkdir_p(path, verbose: true)
      puts "Creating plugin's destination folder: #{path}"
    end
    unless File.directory?("#{path}/#{name}")
      Rake.cd path do
        puts "Cloning plugin #{name} into #{path}"
        Rake.sh "git clone #{repo}"
      end
    end
  end

  def self.get_name(name, hash, version)
    "#{name}@#{hash}-#{version}-#{get_nodejs_platform}.tgz"
  end

  def self.add_info(dest, entry)
    File.open("./#{dest}/info.json", 'w') do |f|
      f.write(entry.to_json)
    end
  end
end
