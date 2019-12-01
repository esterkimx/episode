require 'json'
require 'time'

DEFAULT_CFG = {
  viewer: 'mpv',
  index_from_zero: false
}

class Config
  attr_accessor :last
  attr_accessor :last_played_at
  attr_writer :viewer
  attr_writer :index_from_zero

  def self.load(io)
    new JSON.parse(io.read, symbolize_names: true)
  end

  def initialize(cfg = {})
    @dir = cfg[:dir]
    @last = cfg[:last]
    @last_played_at = Time.parse cfg[:last_played_at] rescue nil
    @viewer = cfg[:viewer]
    @index_from_zero = cfg[:index_from_zero]
  end

  def save(io)
    io.write JSON.pretty_generate(to_h(remove_defaults: true))
  end

  def to_h(remove_defaults: false)
    if remove_defaults
      { 
        dir: @dir,
        last: @last,
        last_played_at: @last_played_at,
        viewer: @viewer,
        index_from_zero: @index_from_zero
      }.compact
    else
      { 
        dir: dir,
        last: last,
        last_played_at: last_played_at,
        viewer: viewer,
        index_from_zero: index_from_zero
      }
    end
  end

  def dir
    @dir || Dir.pwd
  end

  def viewer
    @viewer || DEFAULT_CFG[:viewer]
  end

  def index_from_zero
    @index_from_zero || DEFAULT_CFG[:index_from_zero]
  end
end