require 'json'
require 'time'

DEFAULT_CFG = {
  viewer: 'mpv',
  index_from_zero: false,
  pointer: '*'
}

class Config
  attr_accessor :last
  attr_accessor :last_played_at
  attr_writer :viewer
  attr_writer :index_from_zero

  def self.load(io, opts = {})
    new JSON.parse(io.read, symbolize_names: true).merge(opts)
  end

  def initialize(opts = {})
    @default = opts[:default]&.to_h || DEFAULT_CFG
    @dir = opts[:dir]
    @last = opts[:last]
    @last_played_at = Time.parse opts[:last_played_at] rescue nil
    @viewer = opts[:viewer]
    @index_from_zero = opts[:index_from_zero]
    @pointer = opts[:pointer]
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
        index_from_zero: @index_from_zero,
        pointer: @pointer
      }.compact
    else
      { 
        dir: dir,
        last: last,
        last_played_at: last_played_at,
        viewer: viewer,
        index_from_zero: index_from_zero,
        pointer: pointer
      }
    end
  end

  def default
    self.class.new @default
  end

  def dir
    @dir || Dir.pwd
  end

  def viewer
    @viewer || @default[:viewer]
  end

  def index_from_zero
    @index_from_zero || @default[:index_from_zero]
  end

  def pointer 
    @pointer || @default[:pointer]
  end
end