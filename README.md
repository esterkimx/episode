# Episode (ep)
Remembers what video in the directory you watched last time.
Enumerates all videos in the directory and allows to reference them only by a number.

```
Usage: ep [options] <command> 

  Quick start:
    ep ls                     show episodes in current directory with their indexes
    ep 7                      play episode #7
    ep next                   play next episode (or first)
    ep -g set viewer vlc      always use VLC as a video player (default is mpv)

  Commands:
        ls                    List all episodes and their idnexes
    (s) status                Show information about last view
    (l) last                  Re-play episode watched last time 
    (n) next                  Play next episode
    (p) prev                  Play previous episode (one before 'last') 
        <number>              Same as `ep no <number>` (i.e. `ep 11`)
        no                    Play episode by number (i.e. `ep no 11`) 
    (c) cfg                   Display config for current directory
        set <param> <value>   Set config parameter (i.e. `ep set last 11`)
    (r) reset [param]         Reset config parameter (i.e. `ep reset last`)
    (h) help                  Show this help

  Options for `last`, `next`, `prev`, and `no`:
    -n, --name                       Show episode name, but don't play it (i.e. `ep -n 11`)
    -o, --no-update                  Don't update .episode file

  Options for `set` and `reset`:
    -g, --global                     Edit global config ($HOME/.config/episode)
```