# ICHC-points
ICHC points bot

##dependencies
requires `bash` + `libcurl` + `tmux`


##install
start a tmux session

Edit bot.normal.sh and add fill in the quotes for  the following variables:

- APIKey
- Room
- BotName

Add your username to the permaMods, it supports multiple users, seperated by a new line

##start the bot
In a tmux session, start the bot by running `bash run.normal.sh` or use `chmod u+x *.sh`  then `run.normal.sh`

##commands
The bot takes the following commands, either via main chat or via PM, for readme purposes, everything after # is a comment to describe the command <br>

!give username numberOfPoints (use negative value to take away points) #a mod may give points to a user<br>
!checkpoints username #checks the points of the given user<br>
!checkpoints #checks self points<br>
!removeuser username #resets the points of a given user <br>
!top5 #gives the top 5 users (highest scores) <br>
!last5 #gives the last 5 users (lowest scores)

##hosting

This code is open source, you can host your self or drop a message and I'll host it for you. You must provide the APIkey, Room name, BotName, and the list of users you want to have mod access to the bot (people that can add points and remove points)
