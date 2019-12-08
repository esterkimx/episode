# Episode (ep)
Remembers what file in the directory you viewed last time.
Enumerates all files in the directory and allows to reference them only by a number.

## Installation

#### Using `gem`
```
gem install episode
```

#### Manual
Clone this repository and add `bin/ep` to your `$PATH`.

## Quick Start

Episode creates `.episode` file in the current directory when you open some file with it. By default it will be looking for `mkv`, `avi` or `mp4` files and will use `mpv` as the viewer. Read [examples](#viewing-different-file-formats) below to see how to change this behavior.

List episodes in the current directory.
```
ep
``` 

Watch episode #7
```
ep 7
```

Watch with mpv
```
ep 7 -v mpv
``` 

Make mpv default player for this directory (add `-g` to make it global)
```
ep set viewer mpv
```

Show config for the current directory
```
ep cfg
```

Show global config
```
ep cfg -g
```

## Usage (`ep help`)
```
Usage: ep <command> [options]  
 
  Quick start:
    ep ls                            Show episodes in the current directory with their numbers
    ep                               Same as `ep ls`
    ep 7                             Play episode #7
    ep next                          Play next episode (or first)
    ep set viewer mpv -g             Use mpv as default video player (by default it's xdg-open)

  Commands:
        ls                           List all episodes and their numbers
        <number-or-file>             Same as `ep play <number-or-file>` (i.e. `ep 11`)
        play <number-or-file>        Play episode (i.e. `ep play 11`) 
    (s) status                       Show information about last view
    (l) last                         Re-play episode watched last time 
    (n) next                         Play next episode
    (p) prev                         Play previous episode (one before 'last') 
    (c) cfg                          Show config
        set <param> <value>          Set config parameter (i.e. `ep set last 11`)
    (r) reset [param]                Reset config parameter (i.e. `ep reset last`)

  Options for `play`, `last`, `next`, and `prev`:
    -n, --name                       Show episode name, but don't play it (i.e. `ep -n 11`)
    -o, --no-update                  Don't update .episode file
    -v, --viewer <program>           Specify what viewer to use (i.e. `ep 7 -v mpv`)


  Options for `cfg`, `set`, and `reset`:
    -g, --global                     Edit (or show) global config ($HOME/.config/episode)
```

## More Examples

#### Coloring the 'last' pointer
```
ep -g set pointer '\u001b[33;1m*\u001b[0m'
```
<img src="https://static.hedlx.org/episode_coloring_pointer.png">

#### Purging all `episode` data from the directory
```
ep r
```

#### Restoring global default settings
```
ep r -g
```

#### Viewing different file formats

###### Pictures
```
ep set formats png,jpg
ep set viewer feh
```

###### PDF
```
ep set formats pdf
ep set viewer zathura
```

###### Any
```
ep set formats ''
ep set viewer 'hexdump -C'

# Invoking:
ep next | less
```

#### Viewing files from read-only directories
Since `episode` creates an `.episode` file with local configuration in the directory, you can't use it in read-only directories.
However, we can work around this limitation by changing `dir` parameter. 

First, create a new directory
```
mkdir placeholder && cd placeholder
```

Then set parameter `dir` to point to the target directory
```
ep set dir /path/to/readonly/directory
```

This way `episode` will list and track files from `/path/to/readonly/directory` instead of `placeholder` directory.