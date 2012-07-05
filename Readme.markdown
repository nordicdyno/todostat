##  What is todostat?

`todostat` is tool for tracking special comments in code like TODO, WTF & etc

## Install

    % cpanm http://github.com/nordicdyno/todostat/tarball/master

## Usage patterns

    % cd your-project-dir
    
    #... create config file .todostatrc... [optional] see below
    % vim .todostatrc
    
    # scan folders & create
    % todostat --scan
    
    # show full stat
    % todostat --list --color
    
    # show short stat
    % todostat

## Fast start

Fast way to see `todostat` in action:

    % git clone git://github.com/nordicdyno/todostat.git
    % cd todostat
    % perl -Ilib bin/todostat -s
    
    % perl -Ilib bin/todostat -l
    % perl -Ilib bin/todostat -l -c
    % perl -Ilib bin/todostat
    % perl -Ilib bin/todostat -c

## Config files

* user config (optional):  ~/.todostatrc
* local config (optional):  .todostatrc

### Config format

Config is YAML file .todostatrc like these:

    scan_only:
      - lib
    except:
      - lib/YxNews
    file_masks:
      - *.pm
      - *.pl
    scan:
      - TODO
      - HACK
      - FIXME
      - WTF
    colors:
      TODO:  'blue bold'
      HACK:  'bold magenta'
      FIXME: 'red on_bright_yellow'
      WTF:   'bright_red on_black'

## Options

* `--list, --ls, -l` – show full statistic
* `--quiet, -q` – quiet mode
* `--color, -c` – color mode
* `--zsh, -z` – zsh mode (useful for status line)
* `--no-br, -n` – avoid newline symbol at end
* `--help, -h`

## zsh support

My `oh-my-zsh` theme config:

    todo(){
      if [ -e .todostat.cache ]
      then
        if $(which todostat &> /dev/null)
        then
          out=$(echo $(todostat -z -c -q))
          if [ ! -z $out ]
          then
            echo "$out"
          fi
        fi
      fi
    }
 
    set_prompt () {
      export RPROMPT="$(todo)"
    }
 
    precmd() {
      title "zsh" "%m" "%55<...<%~"
      set_prompt
    }

_Some zsh colors supported, but it didn't tested heavy._

## TODO

* improve colors support
* better bash support (?)
* tests
