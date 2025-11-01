#!/bin/bash
SESSION="dev"
if [ -n "$TMUX" ]; then
  # Inside a tmux session: create a new window with the layout
  echo "Creating new dev window..."
  
  # Create a new window with a descriptive name
  tmux new-window -n "dev"
  
  # Get dimensions of the new window
  cols=$(tmux display-message -p "#{window_width}")
  lines=$(tmux display-message -p "#{window_height}")
  
  left_width=$(( (cols * 7) / 10 ))
  right_width=$(( cols - left_width ))
  half_height=$(( lines / 2 ))
  
  # Split the window horizontally
  tmux split-window -h -l $right_width
  RIGHT_PANE=$(tmux display-message -p "#{pane_id}")
  
  # Split the right pane vertically
  tmux split-window -v -l $half_height -t "$RIGHT_PANE"
  
  # Return to the left pane and start helix
  tmux select-pane -t 0
  tmux send-keys 'hx .' C-m
else
  # Outside tmux: create session if it doesn't exist, then attach
  if ! tmux has-session -t $SESSION 2>/dev/null; then
    tmux -u new-session -d -s $SESSION -x- -y-
    sleep 0.1
    cols=$(tmux display-message -p -t $SESSION:0 "#{window_width}")
    lines=$(tmux display-message -p -t $SESSION:0 "#{window_height}")
    left_width=$(( (cols * 7) / 10 ))
    right_width=$(( cols - left_width ))
    half_height=$(( lines / 2 ))
    tmux split-window -h -l $right_width -t $SESSION:0
    tmux select-pane -t $SESSION:0.1
    tmux split-window -v -l $half_height -t $SESSION:0.1
    tmux select-pane -t $SESSION:0.0
    tmux send-keys 'hx .' C-m
  fi
  tmux -u attach-session -t $SESSION
fi
