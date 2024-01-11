#!/bin/bash
#
#
### Globální proměné, ručně zadané
DECRYPTIP="10.170.22.81"
SLOT="SLOT1"
DIR="./TANGRAM-1_PRAHA-HORNI"
REPORT="mtecl@coprosys.cz"
#
### Globální proměné, které není třeba měnit
DECRYPT="$DIR/$SLOT/decrypt.ttx"
CHANNELS="$DIR/$SLOT/channels.ttx"
STATUS="$DIR/$SLOT/status.ttx"
LOG="$DIR/$SLOT/log.ttx"
LOCK="$DIR/$SLOT/lock."
#
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "$DIR" ];then
	mkdir $DIR
fi
if [ ! -d "$DIR/$SLOT" ];then
	mkdir $DIR/$SLOT
fi
#
### Vyprázní log
### Při testování je nutné tento řádek zahashovat a dopsat si do něj, co je potřeba

> $LOG

#
### Vypíše si data z Tangramu - seznam kanálů, co se kde dekryptuje a status dekryptování
snmpwalk -v2c -ccoprosys $DECRYPTIP iso.3.6.1.4.1.7465.20.2.9.1.2.1.7.1.3.1|cut -f18 -d'.' > $CHANNELS
snmpwalk -v2c -ccoprosys $DECRYPTIP iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.2.1|cut -f18-19 -d'.' > $DECRYPT
snmpwalk -v2c -ccoprosys $DECRYPTIP iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.4.1|cut -f18-19 -d'.'|grep INTEG > $STATUS

sed -i 's/\r$//g' $CHANNELS
sed -i 's/\r$//g' $DECRYPT
sed -i 's/\r$//g' $STATUS

for SID in $(cat $DECRYPT|awk '{ print $4 }'); do
	PROGRAM=`cat $CHANNELS| grep -w "$SID ="|tr -d '"'|cut -f4- -d' '`
	NUMBER=`cat $DECRYPT|grep -w " $SID" | awk '{ print $1 }'`
	STAV=`cat $STATUS|grep $NUMBER |awk '{print $4}'`
	#
	### Vypíš info o programu, na kterém kartě je a jeho status
#	echo -e "\t Pozice: $NUMBER"
#	echo -e "\t Program: $PROGRAM"
#	echo -e "\t Staus: $STAV\n"
	if [ $STAV -eq 2 ];then
		if [ ${#PROGRAM} -ge 8 ];then
			echo -e "$PROGRAM\t - v pořádku"
		else
			echo -e "$PROGRAM\t\t - v pořádku"
		fi
	else
		if [ ${#PROGRAM} -ge 8 ];then
			echo -e "$PROGRAM\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG
		else
			echo -e "$PROGRAM\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG
		fi	
	fi
done
#
### Kontrola, že je log prázdný, pokud ne, odešle info o stavu
if [ $(cat $LOG|wc -l) -gt 0 ]; then
	if [ -f "$LOCK" ]; then
	echo -e "\n\tDescrabling still not working on some program/s.\n\tLOCK file exist. Nothing to do.\n"
	else
        echo -e "\n\tThere is something in the log -> Sending report to $REPORT and creating LOCK file.\n"
	cat $LOG | mail -a from:iptvmaster@coprosys.cz -s "POZOR - Už zase má krámy" $REPORT
        touch $LOCK
	fi
else
        echo -e "\n\tLog is empty, deleting LOCK file...\n"
	sleep 1
        if [ ! -f "$LOCK" ]; then
        	echo -e "\tLOCK file does not exist. Nothink to do.\n"
	        exit
        else
        	echo -e "\tLOCK file exist, deleting.\n"
        	rm $LOCK
        fi
fi
