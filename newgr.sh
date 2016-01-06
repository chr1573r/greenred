#!/bin/bash

while true; do
	ping -c 1 -W 500 "$1" &> /dev/null && status="true" || status=false
	$status && tput setaf 10 || tput setaf 9
	echo -en "#" && sleep 0.5
done

tput sgr0
