# BlossomOS ZSH config

# EXPORT
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export EDITOR='micro'
export ZSH="$HOME/.oh-my-zsh"
# GUM BlossomOS theme
export GUM_INPUT_CURSOR_FOREGROUND="#55CC77"
export GUM_INPUT_PROMPT_FOREGROUND="#5555FF"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="#3333AA"
export GUM_INPUT_HEADER_FOREGROUND="#AAAAFF"
export GUM_FILTER_MATCH_FOREGROUND="#FFFFFF"
export GUM_FILTER_INDICATOR_FOREGROUND="#55CC77"
export GUM_FILTER_SELECTED_PREFIX_FOREGROUND="#55CC77"
export GUM_FILTER_UNSELECTED_PREFIX_FOREGROUND="#3333AA"
export GUM_FILTER_PROMPT_FOREGROUND="#5555FF"
export GUM_FILTER_HEADER_FOREGROUND="#AAAAFF"
export GUM_FILTER_CURSOR_TEXT_FOREGROUND="#FFFFFF"
export GUM_FILTER_TEXT_FOREGROUND="#AAAAFF"
export GUM_CHOOSE_CURSOR_FOREGROUND="#55CC77"
export GUM_CHOOSE_SELECTED_FOREGROUND="#000000"
export GUM_CHOOSE_SELECTED_BACKGROUND="#55CC77"
export GUM_CHOOSE_HEADER_FOREGROUND="#AAAAFF"
export GUM_CHOOSE_ITEM_FOREGROUND="#555577"
export GUM_CONFIRM_PROMPT_FOREGROUND="#5555FF"
export GUM_CONFIRM_SELECTED_FOREGROUND="#FFFFFF"
export GUM_CONFIRM_SELECTED_BACKGROUND="#55CC77"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#555577"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#1E1E35"
export GUM_SPIN_SPINNER_FOREGROUND="#5555FF"
export GUM_SPIN_TITLE_FOREGROUND="#AAAAFF"
export GUM_WRITE_CURSOR_FOREGROUND="#55CC77"
export GUM_WRITE_PROMPT_FOREGROUND="#5555FF"
export GUM_WRITE_HEADER_FOREGROUND="#AAAAFF"
export GUM_WRITE_PLACEHOLDER_FOREGROUND="#3333AA"

# ALIAS
alias zshconfig="${=EDITOR} ~/.zshrc"
alias zshrc="${=EDITOR} ~/.zshrc"
alias resource="source ~/.zshrc"
alias cls="tput reset"
alias fastfetch-ascii="fastfetch -c ~/.config/fastfetch/config-ascii.jsonc"
alias neofetch="fastfetch"

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

if [[ ! -f "${HOME}/.config/no-terminal-warning" ]]; then
    gum style \
        --border rounded \
        --border-foreground "#FF5555" \
        --foreground "#FF5555" \
        --bold \
        --padding "1 2" \
        "$(_blossom_t terminal_warning)" \
        "" \
        "$(_blossom_t terminal_disable)"
fi
