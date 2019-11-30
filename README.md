#Episode (ep)
Remembers the last video you watched in the directory.
Enumerates all videos in the directory and allows to refrence them only by a number.



```
Usage: ep [options] <command> 

  Quick start:
    ep ls               show episodes in the current directory with their indexes
    ep 7                play episode #7
    ep next             play next episode (or first)
    ep set viewer vlc   use VLC as a video player (mpv is default)

  Commands:
    (l) last                  Re-play last watched episode 
    (n) next                  Play next episode
    (p) prev                  Play previous episode (one before 'last') 
        <number>              Same as `ep no <number>` (i.e. `ep 11`)
        no                    Play episode number #n (i.e. `ep no 11`) 
    (c) cfg                   Display config for the current directory
    (r) reset [param]         Reset config parameter (i.e. `ep reset last`)
    (s) set <param> <value>   Set config parameter (i.e. `ep set last 11`)
        ls                    List all episodes

  Options for last, next, prev, and no:
    -n, --name                       Show the episode name, but don't play it (i.e. `ep -n 11`)
    -o, --no-update                  Don't update .episode file
```