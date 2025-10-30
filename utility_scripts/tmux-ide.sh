#!/bin/bash

SESSION="dev"

if [ -n "$TMUX" ]; then
  # Inside a tmux session: split current window
  echo "Already inside tmux session."

  CURRENT_SESSION=$(tmux display-message -p "#{session_name}")
  CURRENT_WINDOW=$(tmux display-message -p "#{window_index}")

  cols=$(tmux display-message -p -t "$CURRENT_SESSION:$CURRENT_WINDOW" "#{window_width}")
  lines=$(tmux display-message -p -t "$CURRENT_SESSION:$CURRENT_WINDOW" "#{window_height}")

  left_width=$(( (cols * 7) / 10 ))
  right_width=$(( cols - left_width ))
  half_height=$(( lines / 2 ))

  tmux split-window -h -l $right_width -t "$CURRENT_SESSION:$CURRENT_WINDOW"
  tmux select-pane -t "$CURRENT_SESSION:$CURRENT_WINDOW.1"
  tmux split-window -v -l $half_height -t "$CURRENT_SESSION:$CURRENT_WINDOW.1"

  tmux select-pane -t "$CURRENT_SESSION:$CURRENT_WINDOW.0"
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

