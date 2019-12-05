# Episode (ep)
Remembers what file in the directory you viewed last time.
Enumerates all files in the directory and allows to reference them only by a number.

## Usage

```
Usage: ep [options] <command> 

  Quick start:
    ep ls                     show episodes in the current directory with their indexes
    ep                        same as `ep ls`
    ep 7                      play episode #7
    ep next                   play next episode (or first)
    ep -g set viewer vlc      use VLC as default video player (by default it's mpv)

  Commands:
        ls                    List all episodes and their idnexes
    (s) status                Show information about last view
    (l) last                  Re-play episode watched last time 
    (n) next                  Play next episode
    (p) prev                  Play previous episode (one before 'last') 
        <number>              Same as `ep no <number>` (i.e. `ep 11`)
        no <number>           Play episode by number (i.e. `ep no 11`) 
    (c) cfg                   Display config for the current directory
        set <param> <value>   Set config parameter (i.e. `ep set last 11`)
    (r) reset [param]         Reset config parameter (i.e. `ep reset last`)
    (h) help                  Show this help

  Options for `last`, `next`, `prev`, and `no`:
    -n, --name                       Show episode name, but don't play it (i.e. `ep -n 11`)
    -o, --no-update                  Don't update .episode file
    -v, --viewer <program>           Set viewer

  Options for `cfg`, `set` and `reset`:
    -g, --global                     Edit (or show) global config ($HOME/.config/episode)
```

## More Examples

#### Coloring the 'last' pointer
```
ep -g set pointer '\u001b[33;1m*\u001b[0m'
```
<img src="https://static.hedlx.org/episode_coloring_pointer.png">

#### Purging all `episode` data from a directory
```
ep r
```

#### Restoring global default settings
```
ep -g r
```

#### Viewing different file formats 
##### Pictures
```
ep set formats png,jpg
ep set viewer feh
```

##### PDF
```
ep set formats pdf
ep set viewer zathura
```

##### Any
```
ep set formats ''
ep set viewer 'hexdump -C'

# Invoking:
ep next | less
```
