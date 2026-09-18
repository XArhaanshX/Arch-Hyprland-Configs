# Put ~/.local/bin on PATH (for `donut` and anything else installed there).
# fish_add_path is idempotent, so re-sourcing this is harmless.
if test -d $HOME/.local/bin
    fish_add_path -g $HOME/.local/bin
end
