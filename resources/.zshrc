export TERM="xterm-256color"

setopt menu_complete inc_append_history autocd recexact longlistjobs histignorealldups autopushd nobgnice autoparamslash

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

### Set variables
#################
HISTFILE="$HOME/.zsh/.zhistory"
HISTSIZE=1000
SAVEHIST=1000

# Custom bin paths
[ -d "$HOME/scripts" ] && PATH="$HOME/scripts:$PATH"
[ -d "/opt/bin" ] && PATH="/opt/bin:$PATH"
PATH="/usr/local/bin:/usr/local/sbin/:$PATH"

# Custom locations
ZSH_CUSTOM_COMPLETION_PATH="$HOME/.zsh/custom/completion/"

### Load colors
###############
autoload colors zsh/terminfo
[ "$terminfo[colors]" -ge 8 ] && colors
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
   eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
   eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
   (( count = $count + 1 ))
done

### set common functions
########################
function url_encode() {	python3 -c "import urllib.parse; print(urllib.parse.quote(input()))" <<< "$1"; }
function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
function makezip() { zip -r "${1%%/}.zip" "$1" ; }

### Set alias
#############
alias cls="clear"
alias ..="cd .."
alias cd..="cd .."
alias ll="ls -lisa --color=auto"
alias dfd="df -h /dev/nvme0n1p2 --output=source,fstype,size,used,avail,pcent"
alias ls="ls -CF --color=auto"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias grep='grep --color=auto'
alias open="xdg-open"
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias cpu-conservative='for i in $(find /sys/devices/system/cpu/cpufreq -name "*scaling_governor" ); do echo "conservative" | sudo tee "$i"; done'

### Add custom completions
##########################
[ -d "$ZSH_CUSTOM_COMPLETION_PATH" ] && fpath+="$ZSH_CUSTOM_COMPLETION_PATH"

### Bind keys
#############
autoload -U compinit
compinit
bindkey "^?" backward-delete-char
bindkey "\e[3~" delete-char
bindkey "\e[1;5D" backward-word
bindkey "\e[1;5C" forward-word
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end
bindkey "^r" history-incremental-search-backward
bindkey ' ' magic-space    # also do history expansion on space
bindkey '^I' complete-word # complete on tab, leave expansion to _expand

### Completion Settings
#######################
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

### Completion Styles
#####################
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# allow one error for every three characters typed in approximate completer
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( 2 )) numeric )'
    
# insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

## add colors to processes for kill completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

### Source plugins
##################
source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Use starship ( https://starship.rs )
eval "$(starship init zsh)"
