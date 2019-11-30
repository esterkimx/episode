require 'fileutils'
require 'time'
require_relative 'config'

class NoCommandError < StandardError; end
class CommandError < StandardError; end

class Main
  def initialize(opts) 
    @name = opts[:name] || false
    @update = opts[:update] != false
  end

  def last
    play 
  end

  def next
    if config.last
      config.last = episode_by_id(last_id + 1)
    else
      config.last = episodes.first
    end

    play 
  end

  def prev
    config.last = episode_by_id(last_id - 1)
    play 
  end

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

  def reset(param)
    unless config.respond_to? param
      raise CommandError, <<~EOS
        Unknown config parameter '#{param}'".
        Run `#{PROGRAM_NAME} cfg` to see list of available parameters.
      EOS
    end

    config.send("#{param}=", nil)
    save_config
  end

  def cfg
    config.to_h.each do |k, v|
      puts "#{k}: #{v}"
    end
  end

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
    when "index_zero"
      unless %w[true false].include? value
        raise CommandError, <<~EOS
          Invalid value '#{value}' for 'index_zero'.
          Should be true or false.
        EOS
      end
      config.index_zero = (value == "true")
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

  def ls
    episodes.each_with_index do |filename, id|
      puts "#{config.index_zero ? id : id + 1} | #{filename}"
    end
  end

  private

  def method_missing(*args)
    raise NoCommandError, args.first
  end

  def name?
    @name
  end

  def update?
    @update
  end

  def config
    @config ||= 
      if File.exists? DATA_FILENAME
        File.open(DATA_FILENAME, 'r') { |io| Config.load io }
      else
        Config.new
      end
  end

  def save_config
    File.open(DATA_FILENAME, 'w') { |io| config.save(io) }
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
    when ref =~ /\d+/
      ref_i = ref.to_i
      id = config.index_zero ? ref_i : ref_i - 1
      episode_by_id(id)
    else
      raise CommandError, "Can't parse episode reference '#{ref}'"
    end
  end

  def last_safe
    unless config.last
      raise CommandError, <<~EOS
        Last episode is undefined.

        Please run `#{PROGRAM_NAME} next` to watch first episode
        `#{PROGRAM_NAME} set last <file-name>`, or `#{PROGRAM_NAME} set last <episode-number>` 
        to define where to start from.
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