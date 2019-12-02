require 'fileutils'
require 'time'
require 'io/console'
require_relative 'config'

FORMATS = %w[mkv mp4 avi]

class NoCommandError < StandardError; end
class CommandError < StandardError; end

class Main
  def initialize(opts) 
    @is_name = opts[:name] || false
    @is_update = opts[:update] != false
    @is_global = opts[:global] || false
  end

  def ls
    if episodes.empty?
      raise CommandError, 'No episodes found in the directory'
    end

    total = episodes.size
    padding = Math.log10(config.index_from_zero ? total - 1 : total).floor + 1

    episodes.each_with_index do |filename, id|
      id_fixed = config.index_from_zero ? id : id + 1
      id_formatted = id_fixed.to_s.rjust(padding, '0')
      separator = (config.last && id == last_id) ? config.pointer : '|'
      puts "#{id_formatted} #{separator} #{filename}"
    end
  end

  def status
    puts "#{config.index_from_zero ? last_id : last_id + 1} | #{config.last}"

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
        "#{seconds_ago} second#{seconds_ago == 1 ? '' : 's'}" 
      else
        [
          days_ago > 0 ? "#{days_ago} day#{days_ago == 1 ? '' : 's'}" : nil,
          hours_ago > 0 ? "#{hours_ago} hour#{hours_ago == 1 ? '' : 's'}" : nil,
          minutes_ago > 0 ? "#{minutes_ago} minute#{minutes_ago == 1 ? '' : 's'}" : nil
        ].compact.join(" ")
      end
      
    puts "#{config.last_played_at} (#{time_passed} ago)" 
  end

  alias s status

  def last
    play 
  end

  alias l last

  def next
    config.last = config.last ? episode_by_id(last_id + 1) : episodes.first
    play 
  end

  alias n next

  def prev
    config.last = episode_by_id(last_id - 1)
    play 
  end

  alias p prev

  def no(n_str)
    n =
      begin
        Integer(n_str.gsub /^0*(\d)/, '\\1') 
      rescue ArgumentError
        raise CommandError, <<~EOS
          Invalid value '#{n_str}'.
          `no` command expects natural number.
        EOS
      end
    config.last = episode_by_id(n - 1)
    play
  end

  def cfg
    config.to_h.each { |param, val| puts "#{param}: #{val}" }
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
        [config.default, GLOBAL_CFG_PATH]
      else
        [config, CFG_FILENAME]
      end

    cfg.send "#{param}=", parse_config_value(param, value)
    config_save_safe(cfg_path, cfg)
  end

  def reset(param = nil)
    cfg_path = global? ? GLOBAL_CFG_PATH : CFG_FILENAME  

    if param.nil?
      puts "Reset all config parameters (delete #{cfg_path})? (y|N)"
      FileUtils.rm_f(cfg_path) if 'y' == $stdin.getch
    else
      set(param, nil)
    end
  end

  alias r reset

  private

  def method_missing(*args)
    raise NoCommandError, args.first
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

  def config
    return @config if @config

    default_cfg =
      if File.exists? GLOBAL_CFG_PATH
        File.open(GLOBAL_CFG_PATH, 'r') { |io| Config.load io }
      end

    @config = 
      if File.exists? CFG_FILENAME
        File.open(CFG_FILENAME, 'r') { |io| Config.load io, default: default_cfg }
      else
        Config.new(default: default_cfg)
      end
  end

  def episodes
    @episodes ||= 
      Dir["./*{#{FORMATS.join(',')}}"]
        .map { |path| File.basename(path) }.sort
  end

  def episode_by_id(id)
    ep = episodes[id] if id >= 0
    ep || raise(CommandError, 'Episode not found') 
  end

  def parse_episode_ref(ref)
    case
    when File.file?(ref)
      ref
    when ref =~ /^\d+$/
      ref_i = ref.to_i
      id = config.index_from_zero ? ref_i : ref_i - 1
      episode_by_id(id)
    else
      raise CommandError, "Can't parse episode reference '#{ref}'"
    end
  end

  def last_safe
    unless config.last
      raise CommandError, <<~EOS
        Last episode is undefined.
        Please run:
        `#{PROGRAM_NAME} #{config.index_from_zero ? 0 : 1}` or `ep next` -- to watch first episode
        `#{PROGRAM_NAME} set last <file-name>` or `#{PROGRAM_NAME} set last <episode-number>` -- to define where to start from
      EOS
    end

    unless File.file? config.last
      raise CommandError, <<~EOS
        '#{config.last}' doesn't exist.
        To fix it run:
        `#{PROGRAM_NAME} set last <file-name>` or `#{PROGRAM_NAME} set last <episode-number>` -- to define last file
        `#{PROGRAM_NAME} reset last` -- to erase erroneous value 
      EOS
    end

    config.last
  end

  def last_id
    @last_id ||= episodes.find_index(last_safe)
  end

  def play
    if name?
      puts last_safe
    else
      $stderr.puts "Playing #{last_safe}"
      system config.viewer, File.join(config.dir, last_safe)
    end

    if update?
      config.last_played_at = Time.now
      config_save_safe(CFG_FILENAME, config)
    end
  end

  def parse_config_value(param, value)
    return if value.nil?

    case param
    when "last"
      config.last = parse_episode_ref(value)
    when "index_from_zero"
      unless %w[true false].include? value
        raise CommandError, <<~EOS
          Invalid value '#{value}' for 'index_from_zero'.
          Should be true or false.
        EOS
      end
      config.index_from_zero = (value == "true")
    when "last_played_at"
      config.last_played_at = 
        begin
          Time.parse value 
        rescue ArgumentError
          raise CommandError, "Can't parse time"
        end
    else
      value
    end
  end

  def config_save_safe(path, cfg)
    File.open(path, 'w') { |io| cfg.save(io) }
  rescue Errno::EACCES
    raise CommandError, <<~EOS
      Failed to save the episode data: can't write to this directory.
    EOS
  end
end