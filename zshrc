# BlossomOS ZSH config

# ALIAS
alias zshconfig="${=EDITOR} ~/.zshrc"
alias zshrc="${=EDITOR} ~/.zshrc"
alias resource="source ~/.zshrc"
alias cls="tput reset"
alias fastfetch-ascii="fastfetch -c ~/.config/fastfetch/config-ascii.jsonc"
alias neofetch="fastfetch"

# EXPORT
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export EDITOR='micro'
export ZSH="$HOME/.oh-my-zsh"

# ZSH
plugins=(git safe-paste virtualenvwrapper zsh-autosuggestions)
zstyle ':omz:update' mode auto
ZSH_THEME="intheloop"
COMPLETION_WAITING_DOTS="true"

# SOURCE
source $ZSH/oh-my-zsh.sh

# ---------
# COMMANDS
if [[ -n "$KITTY_WINDOW_ID" || "$TERM" == *kitty* || -n "$KONSOLE_VERSION" || "$TERM_PROGRAM" == "iTerm.app" || -n "$ITERM_SESSION_ID" ]]; then
    fastfetch
else
    fastfetch-ascii
fi
