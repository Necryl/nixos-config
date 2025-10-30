#!/bin/bash

SESSION="dev"

# Create new detached session with default terminal size inheritance
tmux new-session -d -s $SESSION -x- -y-

# Short delay to let tmux initialize
sleep 0.1

# Get tmux session's window size (after session creation)
cols=$(tmux display-message -p -t $SESSION:0 "#{window_width}")
lines=$(tmux display-message -p -t $SESSION:0 "#{window_height}")

# Calculate pane sizes for 70/30 vertical split and 50/50 horizontal split
left_width=$(( (cols * 78) / 100 ))
right_width=$(( cols - left_width ))
half_height=$(( lines / 2 ))

# Perform the splits with tmux-reported sizes
tmux split-window -h -l $right_width -t $SESSION:0

tmux select-pane -t $SESSION:0.1
tmux split-window -v -l $half_height -t $SESSION:0.1

# Send command to left pane
tmux select-pane -t $SESSION:0.0
tmux send-keys 'hx .' C-m

# Attach to session
tmux attach-session -t $SESSION

