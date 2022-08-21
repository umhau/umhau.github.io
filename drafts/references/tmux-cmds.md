session management
------------------
tmux new -s session_name    | create new session 
tmux attach -t session_name | attach to session
tmux switch -t session_name | switch to session
tmux list-sessions          | list tmux sessions
prefix + d                  | detach current session

window management
-----------------
prefix + c   | create a new window
prefix + 0-9 | move to the window based on index
prefix + ,   | rename the current window
prefix + n   | move to next window
prefix + j   | move to previous window

src: robots.thoughtbot.com/a-tmux-crash-course
----------------------------------------------
