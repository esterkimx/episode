require 'fileutils'
require 'time'
require 'io/console'
require_relative 'episode/config'

class Episode
  VERSION = 2
  VERSION_PATCH = 0

  class NoCommandError < StandardError; end
  class CommandError < StandardError; end

  def initialize(opts = {}) 
    @is_name = opts[:name] || false
    @is_update = opts[:update] != false
    @is_global = opts[:global] || false
    @viewer = opts[:viewer]
  end

  def ls
    if episodes.empty?
      raise CommandError, <<~EOS 
        No episodes found in the directory.
        Currently #{PROGRAM_NAME} is looking for the following formats: #{config.formats.join ', '}.
        To change this run:
          `ep set formats fmt1,fmt2,fmt3` -- to set list of formats for the current directory
          `ep set formats fmt1,fmt2,fmt3 -g` -- to make it global
      EOS
    end

    largest_id = episodes.size - 1 + config.index_from
    id_length = Math.log10([largest_id, 1].max).floor + 1

    episodes.each_with_index do |filename, id|
      id_fixed = id + config.index_from
      id_formatted = id_fixed.to_s.rjust id_length, '0'
      separator = 
        if config.last && id_fixed == last_id
          config.pointer
        else
          '|'
        end
      puts "#{id_formatted} #{separator} #{filename}"
    end
  end

  def status
    puts "#{last_id} #{config.pointer} #{config.last}"

    unless config.last_played_at
      puts 'Time unknown'
      return
    end

    seconds_ago = (Time.now - config.last_played_at).floor
    days_ago = seconds_ago / (3600 * 24)
    hours_ago = (seconds_ago % (3600 * 24)) / 3600
    minutes_ago = (seconds_ago % 3600) / 60
    time_passed = 
      if seconds_ago < 60
        pluralize seconds_ago, 'second'
      else
        [
          days_ago > 0 ? pluralize(days_ago, 'day') : nil,
          hours_ago > 0 ? pluralize(hours_ago, 'hour') : nil,
          minutes_ago > 0 ? pluralize(minutes_ago, 'minute') : nil
        ].compact.join ' '
      end
      
    puts "#{config.last_played_at} (#{time_passed} ago)" 
  end

  alias s status

  def last
    play_last 
  end

  alias l last

  def next
    config.last = 
      if config.last 
        episode_by_id(last_id + 1) 
      else 
        episodes.first
      end
    play_last
  end

  alias n next

  def prev
    config.last = episode_by_id(last_id - 1)
    play_last
  end

  alias p prev

  def play(ref)
    config.last = parse_episode_ref ref
    play_last
  end

  def cfg
    cfg_h = 
      if global? 
        config.global.to_h
      else
        config.to_h
      end

    cfg_h.each { |param, val| puts "#{param}: #{val}" }
  end

  alias c cfg

  def set(param, value)
    unless config.respond_to? param
      raise CommandError, <<~EOS
        Unknown config parameter '#{param}'.
        Run `#{PROGRAM_NAME} cfg` to see the list of available parameters.
      EOS
    end

    cfg, cfg_path =
      if global? 
        [config.global, CFG_GLOBAL_PATH]
      else
        [config, CFG_FILENAME]
      end

    cfg.send "#{param}=", parse_config_value(param, value)

    if param == 'last'
      cfg.last_played_at = nil
    end

    config_save cfg_path, cfg
  rescue NotLocal
    raise CommandError, "Parameter '#{param}' is not global"
  end

  def reset(param = nil)
    cfg_path = global? ? CFG_GLOBAL_PATH : CFG_FILENAME  

    if param.nil?
      $stderr.puts "Reset all config parameters (delete #{cfg_path})? (y|N)"
      if 'y' == $stdin.getch
        safe_rm cfg_path 
      end
    else
      set param, nil
    end
  end
  
  alias r reset

  private

  def method_missing(*args)
    if args.size == 1
      play args.first.to_s
    else
      raise NoCommandError, args.first
    end
  end

  def name?
    @is_name
  end

  def update?
    @is_update
  end

  def global?
    @is_global
  end

  def viewer
    @viewer || config.viewer
  end

  def config
    @config ||= 
      if File.exists? CFG_FILENAME
        File.open(CFG_FILENAME, 'r') { |io| Config.load io, global: config_global }
      else
        Config.new(global: config_global)
      end
  end

  def config_global
    @config_global ||= 
      if File.exists? CFG_GLOBAL_PATH
        File.open(CFG_GLOBAL_PATH, 'r') { |io| Config.load io }
      else
        Config.new
      end
  end

  def episodes
    @episodes ||= 
      Dir.entries(config.dir)
        .select { |path| path =~ /(#{config.formats.join '|'})$/ } 
        .sort
  end

  def episode_by_id(id)
    id_fixed = id - config.index_from
    ep = episodes[id_fixed] if id_fixed >= 0
    ep || raise(CommandError, "Episode ##{id} not found")
  end

  def last_id
    config.index_from + episodes.find_index(last_name)
  end

  def last_name
    File.basename last_path 
  end

  def last_path
    unless config.last
      raise CommandError, <<~EOS
        Last episode is undefined.
        Please run:
          `#{PROGRAM_NAME} #{config.index_from}` or `ep next` -- to watch first episode
          `#{PROGRAM_NAME} set last <number-or-file>` -- to define where to start from
      EOS
    end

    path = File.join config.dir, config.last

    if File.file? path
      path
    else
      raise CommandError, <<~EOS
        '#{config.last}' doesn't exist.
        It looks like '.episode' file is damaged. To fix it run:
          `#{PROGRAM_NAME} set last <numer-or-file>` -- to define last file
          `#{PROGRAM_NAME} reset last` -- to reset erroneous value 
      EOS
    end
  end

  def play_last
    if name?
      puts last_name
    else
      $stderr.puts "Viewing ##{last_id} #{config.pointer} #{last_name}"
      viewer_with_options = viewer.split ' '
      system *viewer_with_options, last_path
    end

    if update?
      config.last_played_at = Time.now
      config_save CFG_FILENAME, config
    end
  end

  def parse_config_value(param, value)
    return if value.nil?

    case param
    when 'last'
      parse_episode_ref value
    when 'index_from'
      parse_natural_number value, 
        err_msg: <<~EOS
          Invalid value '#{value}' for 'index_from'.
          Should be a natural number.
        EOS
    when 'last_played_at'
      begin
        Time.parse value 
      rescue ArgumentError
        raise CommandError, "Failed to parse time."
      end
    when 'pointer'
      "\"#{value}\"".undump
    when 'formats'
      value.split ','
    else
      value
    end
  end

  def parse_episode_ref(ref)
    case
    when File.file?(ref)
      ref
    when ref =~ /^\d+$/
      id = parse_natural_number ref,
        err_msg: <<~EOS
          Can't parse #{ref}.
          Should be a file or a natural number.
        EOS
      episode_by_id id
    else
      raise CommandError, "File '#{ref}' not found"
    end
  end

  def parse_natural_number(str, err_msg: nil)
      Integer(str.gsub /^0*(\d)/, '\\1') 
  rescue ArgumentError 
    if err_msg
      raise CommandError, err_msg
    else
      raise CommandError, <<~EOS
        Invalid value '#{str}'.
        Should be a natural number.
      EOS
    end
  end

  def config_save(path, cfg)
    File.open(path, 'w') { |io| cfg.save io }
  rescue Errno::EACCES => e
    raise CommandError, <<~EOS
      Failed to save episode data.
      #{e.message}
    EOS
  end

  def safe_rm(path)
    $stderr.puts "rm #{path}"
    FileUtils.rm path
  rescue Errno::ENOENT => e
    raise CommandError, <<~EOS
      File #{path} doesn't exist.
    EOS
  rescue Errno::EACCES => e
    raise CommandError, <<~EOS
      Failed to remove file #{path}
      #{e.message}
    EOS
  end

  def pluralize(n, word)
    "#{n} #{word}#{n == 1 ? '' : 's'}" 
  end
end