#!/bin/bash

function init {
	APPVERSION="2.0"

	# initiate log
	GRSTATE=init; logger "GREENRED $APPVERSION, HOST: $HOST"
	
	#set init time
	INITDATE=$(date +"%s")

	#color settings
	DEF="\x1b[0m"
	LIGHTGREEN="\x1b[32;01m"
	LIGHTRED="\x1b[31;01m"

	#initial states
	OLDSTATE="pending"
	NEWSTATE="pending"

	#counters
	REDC=0
	TESTC=0
	DOWNC=0

	#how many seconds of downtime before writing downtime stats to log upon re-connecting
	FUZZYNESS=2

	trap clean_up SIGINT SIGTERM EXIT
	echo >>con.log
	GRSTATE=init; logger "GREENRED $APPVERSION initialzed. Host $HOST"
	reset
	timer start
	GRSTATE=main

}

function clean_up {
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
	GRSTATE=stop; logger "GREENRED $APPVERSION terminated"
	echo
	echo -e "GREENRED $APPVERSION terminated at $(date)"
	exit
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
			((DOWNC++))
			;;
		sessionstats)
			DIFF=$(($TERMDATE-$INITDATE))
			SESSIONLENGTH="$(($DIFF / 60 / 60 ))h $(($DIFF / 60))m $(($DIFF % 60))s"
			DOWNTIME="$(($DOWNC / 60 / 60 ))h $(($DOWNC / 60))m $(($DOWNC % 60 - 1))s"
			;;
	esac
	
}

function main {
	init
	while true
	do
		ping -c 1 -W 500 $HOST &> /dev/null

		if [ "$?" == "0" ]; then
			NEWSTATE="GREEN"
			echo -ne ""$LIGHTGREEN""\#""
			sleep 0.4
		else
			NEWSTATE="RED"
			echo -ne ""$LIGHTRED""\#""
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
			fi
			if [ "$NEWSTATE" == "RED" ]; then ((REDC++)); timer start; logger "Connection lost"; fi
			
		fi
		OLDSTATE=$NEWSTATE
		((TESTC++))
	done
}

if [ -z "$1" ]; then echo Please use syntax ./greenred \<HOST to ping\>; exit; else HOST=$1; fi
main
