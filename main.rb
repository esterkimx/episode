require 'fileutils'
require 'time'
require 'io/console'
require_relative 'config'

class NoCommandError < StandardError; end
class CommandError < StandardError; end

class Main
  def initialize(opts) 
    @is_name = opts[:name] || false
    @is_update = opts[:update] != false
  end

  def last
    play 
  end

  alias l last

  def next
    if config.last
      config.last = episode_by_id(last_id + 1)
    else
      config.last = episodes.first
    end

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
        Integer(n_str.gsub /^0+/, '') 
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
    config.to_h.each do |k, v|
      puts "#{k}: #{v}"
    end
  end

  alias c cfg

  def reset(param = nil)
    if param.nil?
      puts 'Reset all config parameters (remove ./.episode)? (y|N)'
      if 'y' == $stdin.getch
        FileUtils.rm_f(CFG_FILENAME)
      end
      return
    end

    unless config.respond_to? param
      raise CommandError, <<~EOS
        Unknown config parameter '#{param}'".
        Run `#{PROGRAM_NAME} cfg` to see list of available parameters.
      EOS
    end

    config.send("#{param}=", nil)
    save_config
  end

  alias r reset

  def set(param, value)
    unless config.respond_to? param
      raise CommandError, <<~EOS
        Unknown config parameter '#{param}'".
        Run `#{PROGRAM_NAME} cfg` to see list of available parameters.
      EOS
    end

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
          raise CommandError, <<~EOS
            Can't parse time
          EOS
        end
    else
      config.send("#{param}=", value)
    end

    save_config
  end

  alias s set

  def ls
    total = episodes.size

    return if total == 0

    padding = 
      if config.index_from_zero 
        Math.log10(total - 1).floor + 1
      else
        Math.log10(total).floor + 1
      end

    episodes.each_with_index do |filename, id|
      id = config.index_from_zero ? id : id + 1
      id_formatted = id.to_s.rjust(padding, '0')
      puts "#{id_formatted} | #{filename}"
    end
  end

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

  def config
    @config ||= 
      if File.exists? CFG_FILENAME
        File.open(CFG_FILENAME, 'r') { |io| Config.load io }
      else
        Config.new
      end
  end

  def save_config
    File.open(CFG_FILENAME, 'w') { |io| config.save(io) }
  end

  def episodes
    @episodes ||= Dir['./*{mkv,mp4,avi}'].map { |path| File.basename(path) }.sort
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

        Please run 
        `#{PROGRAM_NAME} #{config.index_from_zero ? 0 : 1}` or `ep next` -- to watch first episode
        `#{PROGRAM_NAME} set last <file-name>` or `#{PROGRAM_NAME} set last <episode-number>` -- to define where to start from
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
      return
    end
  
    $stderr.puts "Playing #{last_safe}"
    `#{config.viewer} '#{File.join(config.dir, last_safe)}'`

    if update?
      config.last_played_at = Time.now
      save_config 
    end
  end
end