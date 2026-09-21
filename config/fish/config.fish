# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Prompt: oh-my-posh, configured in ~/.config/oh-my-posh/config.toml.
    # That config is a port of the old starship.toml — same glyphs, same greys —
    # so the prompt looks unchanged. Transient prompt is driven by the config's
    # [transient_prompt] block and enables itself, so there's no enable_transience
    # call here and no *_transient_prompt_func to define.
    #
    # ~/.config/starship.toml is left untouched: to switch back, restore this
    # block from config.fish.bak (starship is still installed).
    if test "$TERM" != "linux"; and command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.toml | source
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
