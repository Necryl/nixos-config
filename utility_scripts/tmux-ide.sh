#!/bin/bash
SESSION="dev"
if [ -n "$TMUX" ]; then
  # Inside a tmux session: split current pane only
  echo "Already inside tmux session."
  CURRENT_PANE=$(tmux display-message -p "#{pane_id}")
  
  # Get dimensions of the current pane (not window)
  cols=$(tmux display-message -p "#{pane_width}")
  lines=$(tmux display-message -p "#{pane_height}")
  
  left_width=$(( (cols * 7) / 10 ))
  right_width=$(( cols - left_width ))
  half_height=$(( lines / 2 ))
  
  # Split the current pane horizontally
  tmux split-window -h -l $right_width
  RIGHT_PANE=$(tmux display-message -p "#{pane_id}")
  
  # Split the right pane vertically
  tmux split-window -v -l $half_height -t "$RIGHT_PANE"
  
  # Return to the original left pane
  tmux select-pane -t "$CURRENT_PANE"
  tmux send-keys 'hx .' C-m
else
  # Outside tmux: create session if it doesn't exist, then attach
  if ! tmux has-session -t $SESSION 2>/dev/null; then
    tmux new-session -d -s $SESSION -x- -y-
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
  tmux attach-session -t $SESSION
fi
