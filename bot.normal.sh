APIKey=""; #api key for the user account
Room=""; #room to join
BotName=""; #username for the bot
sleepTime=2;
Timer=0;
idleTimer=0;
MsgCount=0;
MsgMultiplier=0;

function joinRoom() {
curl -s "http://www.icanhazchat.com/api.ashx?v=1&u=$BotName&p=$APIKey&a=join&w=$Room" | head -n 2 | tr -s "\n" " " > key;
roomKey="";
echo "key-> $key";
grep "OK" key;
if [ $? -eq 0 ]
then
	roomKey=`cut -d " " -f2 key`;
else
	echo "Failed to join Room";
	echo "1" > ichcStatus;
	echo "join room failed";
	exit 1;
fi
}

function getMsg() {
data=`curl -s "http://www.icanhazchat.com/api.ashx?v=1&u=$BotName&k=$roomKey&a=recv"`;
curlResult=$?;
if [ $curlResult -ne 0 ]
then
	echo `date`"Error occured ".$data >> bot.log
	echo "1" > ichcStatus;
	echo "failed to get message using recv, data=$data error status $curlResult";
	exit 2;
fi
echo "0" > ichcStatus;
IFS=$'\n';
for line in $data
do
#	echo "Raw data-> $line";
	echo "$line" | grep "ERROR: room key not found" -q;
	if [ $? -eq 0 ]; then
		rm key;
		echo "1" > ichcStatus;
		exit 1;		
	fi
	echo "$line" | grep -E "^\[\]$" -q;
	if [ $? -eq 0 ]; then
                rm key;
                echo "1" > ichcStatus;
                exit 1;
	fi
	echo "$line" | grep "|" | grep -e "^\[" -vq;
	if [ $? -eq 0 ]
	then
		msg=`echo "$line" | cut -d "|" -f2`;
		echo "$msg";
		parseMsg "$msg";
	else
		parseEvent "$line";
	fi
done
IFS=$OIFS;
}

function parseMsg() {
echo "Received -> "$1;
user=`echo "$1" | cut -d ":" -f1`;
userMsg=`echo "$1" | cut -d ":" -f2- | sed "s/^ //"`;
echo "$userMsg" | grep -e "^\!" -q;
if [ $? -eq 0 ]; then
        cmd=`echo "$userMsg" | cut -d " " -f1`;
        parameters=`echo "$userMsg" | cut -d " " -f2-`;

        case $cmd in

        !give) givepts "$user" "$parameters";
        ;;
        !checkpoints) checkpts "$user" "$parameters";
        ;;
        !last5) last5 "$user" "$parameters";
        ;;
        !top5) top5 "$user" "$parameters";
        ;;
        !remove) rmpts "$user" "$parameters";
        ;;
	!removeuser) rmuser "$user" "$parameters";
	;;
	*) sendMsg "/msg $user I'm sorry $user, that command does not exist";
                echo `date`" $user tried to execute command: $userMsg" >> bot.log;
        ;;
        esac
fi
}

function rmuser() {
	targetUser=`echo "$2" | cut -d " " -f1`;
        grep -E "^$1$" permaMods;
        if [ $? -eq 0 ]; then
		userLine=`grep -E "^$targetUser:" pointsLog -n | cut -d ":" -f1`;
                sed -i "$userLine d" pointsLog;
                rm "users/$targetUser";
                sendMsg "/msg $1 $targetUser has been removed";

	elif [ "$1" == "$targetUser" ]; then
		userLine=`grep -E "^$1:" pointsLog -n | cut -d ":" -f1`;
                sed -i "$userLine d" pointsLog;
		rm "users/$1";
		sendMsg "/msg $1 $1 has been removed";

	else
		sendMsg "/msg $1 you do not have permissions to remove this user";
	
	fi
}

function rmpts() {
	sendMsg "/msg $1 use the !give command with a negative point value";
}

function last5() {
        targetUser=`echo "$2" | cut -d " " -f1`;
	echo "target: $targetUser";
        if [ "$targetUser" != "" ]; then
                for line in `cat "users/$targetUser" |tail -n 5`; do
                	sendMsg "$line";
		done
        else
                for line in `cat "users/$1" |tail -n 5`; do
                sendMsg "$line";
		done
        fi
}

function top5() {
	for line in `sort -k 2 -t ":" -nr pointsLog | head -n 5`; do
		sendMsg "$line";
	done
}

function checkpts() {
	targetUser=`echo "$2" | cut -d " " -f1`;
	if [ "$targetUser" != "" ]; then
		userPts=`grep -E "^$targetUser:" pointsLog`;
		sendMsg "$userPts";
	else
		userPts=`grep -E "^$1:" pointsLog`;
                sendMsg "$userPts";
	fi
}

function givepts() {
	grep -E "^$1$" permaMods;
        if [ $? -eq 0 ]; then
		targetUser=`echo "$2" | cut -d " " -f1`;
		echo "targetUser = $targetUser";
		pts=`echo "$2" | cut -d " " -f2 `;
		isValidPts=`echo "$pts" | grep -E "^\-?[0-9]+$" -q; echo $?`;
		comments=`echo "$2" | cut -d " " -f3-`;
		echo "$targetUser" | grep -E "^[a-z0-9_]+$";
		if [ $? -eq 0 ] && [ "$isValidPts" -eq 0 ]; then
			echo "$targetUser:$pts:$1:$comments" >> "users/$targetUser";
			userPts=`grep -E "^$targetUser:" pointsLog -n`;
			if [ $? -eq 0 ] ; then
				echo "exec";
				lineNum=`echo "$userPts" | cut -d ":" -f1`;
				oldPts=`sed -n "$lineNum p" pointsLog | cut -d ":" -f2`;
				echo "| $oldPts : $pts |";
				newPts=$(( $oldPts + $pts ));
				echo "line number: $lineNum";
				sed -i "$lineNum d" pointsLog;
				sendMsg "$1 added $pts to $targetUser (now: $newPts old: $oldPts)";	
				echo "$targetUser:$newPts" >> pointsLog;
			else
				echo "$targetUser:$pts" >> pointsLog;
				sendMsg "$1 added $pts to $targetUser (now: $pts old: 0)";
			fi
		else
			sendMsg "/msg $1 this user is not valid or the points given isn't a number (received $pts). A give command looks like !give username points some comments about it here";
		fi
        else
                sendMsg "/msg $1 You do not have the prvileges to execute this command";
                echo "$1 tried remove a cam ban on $2 but is not on the mod list" >> bot.log;
        fi

}


function parseEvent() {
	echo "$1";
}

function sendMsg() {
#a quick pause to prevent spamming 
sleep 0.2;

echo "MSG:"$1;
#value=`echo "$1" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\&/%26/g;s/'\''/%28/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\//%2F/g;'"`;
value=`echo "$1" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\//%2F/g;s/\+/%2B/g;s/\[/%5B/g;s/\]/%5D/g'`;

#value=`echo "$1" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\//%2F/g;s/\+/%2B/g;s/]/%5B/g;s/[/%5D/g'`;
#echo "VALUE:"$value;
str="http://www.icanhazchat.com/api.ashx?v=1&u=$BotName&k=$roomKey&a=send&w=$value";
#echo "STR:"$str;
curl -s $str;
}

##### Main Method starts here#####

joinRoom;
echo "$APIKey" 
while [ true ]
do
	getMsg;
	sleep $sleepTime;
done
fi
