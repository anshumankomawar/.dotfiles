#!/bin/zsh -l

# Load Ghostty shell integration
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

# Ghostty title functions for tmux compatibility
if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
    # Default Ghostty title format with tmux compatibility
    precmd() {
        print -rnu $_ghostty_fd $'\ePtmux;\e\e]2;'"${(%):-%(4~|…/%3~|%~)}"$'\a\e\\'
    }
    
    preexec() {
        print -rnu $_ghostty_fd $'\ePtmux;\e\e]2;'"${(V)1}"$'\a\e\\'
    }
fi

# Start tmux with proper environment
exec tmux attach || exec tmux
