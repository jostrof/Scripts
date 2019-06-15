#!/bin/bash
# jso.sh
timestamp=$(date +'%d%m%y%_H%M%S') # DayMonthYearHourMinutesSeconds (12062019_050538)
url="www.spamhaus.org/drop/drop.lasso" # Spamhaus Don't Route Or Peer Lists
log=/var/log/spamhausDROP.log # Log file <CurrentUserPid>.<timestamp>.<log>
iptChain="SpamhausDROP" # iptables chain name
ipregex="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\/[0-3][0-9])" # regex filter for ip in cidr format

function importDROP { # add ip to chain
for ipblock in $blocks
	do
	iptables -A $iptChain -s $ipblock -j LOG --log-prefix "[SpamhausDROP-$timestamp]" # log traffic
	iptables -A $iptChain -s $ipblock -j DROP # drop traffic
done
iptables -I INPUT -j $iptChain # add to INPUT chain
iptables -I OUTPUT -j $iptChain # add to OUTPUT chain
iptables -I FORWARD -j $iptChain # add to FOWARD chain
	}
echo "############################################################################" >> $log
echo "$timestamp: Attempting to Apply the newest spamhaus DROP list to iptables..." >> $log
echo "$timestamp: Process id: $$" >> $log
curl $url | head -n 4 >> $log
blocks=$(curl $url | egrep -o $ipregex) # download and cleanup the list using regex
iptables -N $iptChain # create new chain
if [ $? ]; 
then # if chain already exists then flush and import new rules
        echo "$timestamp: Flushing existing chain [$iptChain]..." >> $log
        iptables -F $iptChain
        echo "$timestamp: Importing new rules into chain [$iptChain]..." >> $log
        importDROP
        echo "$timestamp: Import complete. run 'sudo iptables -S to confirm'" >> $log
 else # import rules
        echo "$timestamp: Importing new rules into chain [$iptChain]..." >> $log
        importDROP
        echo "$timestamp: Import complete. run 'sudo iptables -S to confirm'" >> $log
fi
