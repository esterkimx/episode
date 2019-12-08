require_relative "lib/episode"

Gem::Specification.new do |s|
    s.name = 'episode'
    s.version = "#{Episode::VERSION}.0.#{Episode::VERSION_PATCH}"
    s.summary = 'Console assistant app for watching series'
    s.license = 'MIT'
    s.description = 'Episode (ep) remembers what file in the directory you viewed last time. Enumerates all files in the directory and allows to reference them only by a number.'
    s.authors = ['Maksim Esterkin']
    s.email = 'esterkimx@gmail.com'
    s.homepage = 'https://github.com/esterkimx/episode'

    s.files = [
        'lib/episode.rb', 
        'lib/episode/config.rb',
        'README.md',
        'LICENSE.md',
        'episode.gemspec'
    ]

    s.required_ruby_version = '>= 2.5.0'
    s.bindir = 'bin'
    s.executables = ['ep']

    s.metadata = {
        'bug_tracker_uri' => 'https://github.com/esterkimx/episode/issues',
        'documentation_uri' => 'https://github.com/esterkimx/episode/blob/master/README.md',
        'homepage_uri' => 'https://github.com/esterkimx/episode',
        'source_code_uri' => 'https://github.com/esterkimx/episode'
    }
end