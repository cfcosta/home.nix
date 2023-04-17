set -g mouse on

set -g default-terminal "tmux-256color"
set -sa terminal-features ",*256col*:RGB"
set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

# Bindings
bind-key -r k select-pane -U
bind-key -r j select-pane -D
bind-key -r h select-pane -L
bind-key -r l select-pane -R
bind-key = select-layout tiled
bind-key | select-layout even-horizontal
bind-key - select-layout even-vertical
bind-key -r Up resize-pane -U 5
bind-key -r Down resize-pane -D 5
bind-key -r Left resize-pane -L 5
bind-key -r Right resize-pane -R 5
bind-key -r M-Up resize-pane -U 1
bind-key -r M-Down resize-pane -D 1
bind-key -r M-Left resize-pane -L 1
bind-key -r M-Right resize-pane -R 1

bind-key -r S-h swap-window -t -1
bind-key -r S-l swap-window -t +1

# More straightforward splitting
unbind s
unbind %
bind e split-window -h
bind v split-window -v
