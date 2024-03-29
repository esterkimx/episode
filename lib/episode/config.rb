require 'json'
require 'time'

class Episode
  class NotLocal < StandardError; end

  class Config
    DEFAULT = {
      dir: '.',
      viewer: 'xdg-open',
      index_from: 1,
      pointer: '*',
      formats: %w[mkv mp4 avi]
    }

    attr_writer :viewer
    attr_writer :index_from
    attr_writer :pointer
    attr_writer :formats

    def self.load(io, opts = {})
      new JSON.parse(io.read, symbolize_names: true).merge(opts)
    end

    def initialize(opts = {})
      @global_cfg = opts[:global]

      unless global?
        @local = 
          {
            dir: opts[:dir],
            last: opts[:last],
            last_played_at: (Time.parse opts[:last_played_at] rescue nil)
          }
      end

      @viewer = opts[:viewer]
      @index_from = opts[:index_from]
      @pointer = opts[:pointer]
      @formats = opts[:formats]
    end

    def save(io)
      io.write JSON.pretty_generate(to_h(remove_defaults: true))
    end

    def to_h(remove_defaults: false)
      if remove_defaults
        (@local || {}).merge({ 
          viewer: @viewer,
          index_from: @index_from,
          pointer: @pointer,
          formats: @formats
        }).compact
      else
        local_h = { 
          dir: dir,
          last: last,
          last_played_at: last_played_at
        } unless global?
        
        (local_h || {}).merge({
          viewer: viewer,
          index_from: index_from,
          pointer: pointer,
          formats: formats
        })
      end
    end

    def global?
      @global_cfg.nil?
    end

    def global
      @global_cfg 
    end

    def dir
      get_local :dir
    end

    def dir=(new_val)
      set_local :dir, new_val
    end

    def last
      get_local :last
    end

    def last=(new_val)
      set_local :last, new_val
    end

    def last_played_at
      get_local :last_played_at
    end

    def last_played_at=(new_val)
      set_local :last_played_at, new_val
    end

    def viewer
      @viewer || default(:viewer)
    end

    def index_from
      @index_from || default(:index_from)
    end

    def pointer 
      @pointer || default(:pointer)
    end

    def formats
      @formats || default(:formats)
    end

    private

    def get_local(param)
      @local && @local[param] || (block_given? ? yield : default(param))
    end

    def set_local(param, new_val)
      raise NotLocal if global?
      @local[param] = new_val
    end

    def default(param) 
      @global_cfg&.public_send(param) || DEFAULT[param]
    end
  end
end