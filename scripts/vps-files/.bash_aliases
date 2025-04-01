alias home="cd $HOME"
alias ea="home; vim .bash_aliases"
alias d="deactivate"
alias ra=". .bashrc"

alias dtb="screen -dmS dtb bash -c 'cd ~/dakey-token-bot; . env/bin/activate; python3 dtb'"
alias gpu="screen -dmS sc bash -c 'cd ~/stock-checker; . env/bin/activate; python3 stock_checker'"
alias sl="screen -ls"

alias ssa='screen -ls | grep -o '\''[0-9]*\.[^[:space:]]*'\'' | while read session; do screen -S "$session" -X quit; done'
alias sr="screen -r"
