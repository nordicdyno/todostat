##  What is todostat?

`todostat` is tool for tracking special comments in code like TODO, WTF & etc

## Install

    % cpanm http://github.com/nordicdyno/todostat/tarball/master

## Usage patterns

    % cd your-project-dir
    
    #... create config file .todostat.rc... [optional] see below
    % vim .todostat.rc
    
    # scan folders & create
    % todostat --scan
    
    # show full stat
    % todostat --list --color
    
    # show short stat
    % todostat

## Config files

* user config (optional):  ~/.todostat.rc
* local config (optional):  .todostat.rc

### Config format

Config is YAML file .todostat.rc like these:

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
* `--zsh, -z` – zsh mode
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
          if [ -n -z $out ]
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
* any bash support (?)
* tests