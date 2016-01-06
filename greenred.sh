#!/bin/bash

# bugs: after terminal reset, a full display does not insert required scrolling newlines.
#       add mechanism for adding newlines according to y

function init {
	APPVERSION="2.01"

	# initiate log
	GRSTATE=init; logger "GREENRED $APPVERSION, HOST: $HOST"
	
	#set init time
	INITDATE=$(date +"%s")

	#color settings
	DEF="\x1b[0m"
	LIGHTGREEN="\x1b[32;01m"
	LIGHTRED="\x1b[31;01m"
	LIGHTCYAN="\x1b[36;01m"

	#initial states
	OLDSTATE="pending"
	NEWSTATE="pending"
	X=$(tput cols)
	Y=$(tput lines)
	((Y--))
	((Y--))
	POSX=0
	POSY=0

	declare grarray

	#counters
	REDC=0
	REDCC=0
	TESTC=0

	DOWNC=0

	#how many seconds of downtime before writing downtime stats to log upon re-connecting
	FUZZYNESS=2

	trap clean_up SIGINT SIGTERM EXIT
	echo >>con.log
	GRSTATE=init; logger "GREENRED $APPVERSION initialzed. Host $HOST"
	reset
	tput civis
	timer start
	GRSTATE=main

}

function clean_up {
	GRSTATE=exit
	logger "Exit requested"
	TERMDATE=$(date +"%s")
	timer sessionstats
	reset
	clear
	GRSTATE=stat
	logger "##### GREENRED Session Statistics #####"
	logger "Session started $SESSIONLENGTH ago."
	logger
	logger "Target host: $HOST"
	logger "$REDC disconnects/reconnects"
	logger "$TESTC tests performed in total."
	logger
	logger "Estimated total downtime: $DOWNTIME"
	logger "#######################################"
	grlogwrite
	GRSTATE=stop; logger "GREENRED $APPVERSION terminated"
	echo
	echo -e "GREENRED $APPVERSION terminated at $(date)"
	exit
}

termreset()
{
		clear
		echo Terminal size changed, resetting...
		X=$(tput cols)
		Y=$(tput lines)
		((Y--))
		((Y--))
		POSX=$(( grecontentsize % X ))
		POSY=$(( grecontentsize / X ))
		reset
		grload
}

function grsave {
	grarraysize=${#grarray[*]}
	grarray[$((grarraysize+1))]="$1"
}

function gresave {
	grearraysize=${#grearray[*]}
	grearray[$((grearraysize+1))]="$1"
	grecontent="${grearray[*]}"
 	grecontentsize=$(( ${#grecontent} - ${#grearray[@]} + 1 ))

}

function grload {
	for saved in "${grarray[@]:0}"; do echo -ne "$saved"; done
}

function grlogwrite {
	echo "BEGIN PATTERN LOG" >> con.log
	grload >> con.log
	echo -e "$DEF" >> con.log
	echo "END PATTERN LOG" >> con.log
}

function logger {
	if [[ "$GRSTATE" == main ]]; then
		echo -e "[$(date +"%Y-%m-%d %R:%S")-($GRSTATE)][$HOST] $1">>con.log
	elif [[ "$GRSTATE" == stat ]]; then
		echo -e "$1"
		echo -e "[$(date +"%Y-%m-%d %R:%S")-($GRSTATE)] $1">>con.log
	else
		echo -e "[$(date +"%Y-%m-%d %R:%S")-($GRSTATE)] $1">>con.log
	fi
	
}

function timer {

	case "$1" in
		
		start)
			timerstart=$(date +"%s")
			;;
		stop)
			timerstop=$(date +"%s")
			DIFF=$(($timerstop-$timerstart))
			DIFFSECONDS=$(($DIFF % 60))
			TIMERSTATS="downtime: $(($DIFF / 60 / 60 ))h $(($DIFF / 60))m $(($DIFF % 60))s"
			DOWNC=$((DOWNC+DIFFSECONDS ))
			;;
		sessionstats)
			DIFF=$(($TERMDATE-$INITDATE))
			SESSIONLENGTH="$(($DIFF / 60 / 60 ))h $(($DIFF / 60))m $(($DIFF % 60))s"
			DOWNTIME="$(($DOWNC / 60 / 60 ))h $(($DOWNC / 60))m $(($DOWNC % 60 - 1))s"
			;;
		spamstop)
			CURRENT=$(date +"%s")
			DIFF=$(($PREVIOUS-$CURRENT))
			if (( $DIFF < 1 )); then #todo: AND statement instead of nested ifs
				if (( $REDCC > 5)); then
					#logger "More than 5 ping fails per second, spamstop on"
					sleep 0.6
				#else
					#logger "Less than 5 ping fails per second, spamstop off"
				fi
			fi

			PREVIOUS=$CURRENT
			
	esac
	
}

function main {
	init
	while true
	do
		ping -c 1 -W 500 $HOST &> /dev/null

		if [ "$?" -eq "0" ]; then
			NEWSTATE="GREEN"
			echo -ne ""$LIGHTGREEN"#"$DEF""
			grsave "$LIGHTGREEN#"
			eventstdin
			
		else
			NEWSTATE="RED"
			echo -ne ""$LIGHTRED"#"$DEF""
			grsave "$LIGHTRED#"
			((REDCC++))
			eventstdin
			timer spamstop
		fi

		if [ "$NEWSTATE" != "$OLDSTATE" ]; then
			if [ "$NEWSTATE" == "GREEN" ]; then 
				((GREENC++))
				timer stop
				if (( "$DIFFSECONDS" > "$FUZZYNESS" )); then 
					logger "Connection re-established ($TIMERSTATS)"
				else
					logger "Connection re-established"
				fi
				REDCC=0
				STARTMSG=false
			fi
			if [ "$NEWSTATE" == "RED" ]; then ((REDC++)); timer start; logger "Connection lost"; fi
			
		fi
		OLDSTATE=$NEWSTATE
		
		((TESTC++))
		((POSX++))

		CURRENTX=$(tput cols)
		CURRENTY=$(tput lines)
		((CURRENTY--))
		((CURRENTY--))
		[[ "$X" != "$CURRENTX" ]] && termreset
		[[ "$Y" != "$CURRENTY" ]] && termreset

		if [[ "$POSX" -ge "$X" ]]; then
			POSX=0
			((POSY++))
			[[ "$POSY" -ge "$Y" ]] && tput cup $POSY $POSX && tput el && echo && echo && ((POSY--))
			tput cup $POSY $POSX
		fi
		gresave "#"


	done
}
function promptmove {
	tput cup $(( $(tput lines) - 2 )) 0
}
function prompt {
	promptmove
	echo -ne "> $@"
}

function eventstdin {
tput sc
unset EVENT
unset STDIN
tput cnorm
promptmove
read -t 1 -n 1 -p "> Press any key for event or exit" STDIN
		if [ $? == 0 ]; then
			GRSTATE=evnt
			promptmove
			tput el
			read -p "Event (write e to exit):" EVENT
			[[ "$EVENT" == "e" ]] && exit
			logger "New event: '$EVENT'"
			EVENTL=${#EVENT}
			promptmove
			tput el
			GRSTATE=main
		fi
		promptmove
		#echo -n XY: $X x $Y    XYPOS: $POSX, $POSY    ; sleep 1
tput civis
tput rc
[[ ! -z "$EVENT" ]] && echo -en "$LIGHTCYAN$EVENT$DEF" && grsave "$LIGHTCYAN$EVENT" && gresave "$EVENT" && POSX=$((POSX+EVENTL))
}

if [ -z "$1" ]; then echo Please use syntax ./greenred \<HOST to ping\>; exit; else HOST=$1; fi
main
