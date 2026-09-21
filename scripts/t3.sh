#!/bin/sh
# Раскладка для демо 1: сверху два подписчика, снизу издатель.
# Переключение панелей: мышью или Ctrl-b и стрелка. Выход: Ctrl-b d.
S=demo
tmux -u -f /demo/tmux.conf kill-session -t $S 2>/dev/null
tmux -u -f /demo/tmux.conf new-session -d -s $S
tmux split-window -v -l 45% -t $S:0.0
tmux split-window -h -t $S:0.0
tmux select-pane -t $S:0.0 -T 'SUB A'
tmux select-pane -t $S:0.1 -T 'SUB B'
tmux select-pane -t $S:0.2 -T 'PUB'
tmux select-pane -t $S:0.2
exec tmux -u attach -t $S
