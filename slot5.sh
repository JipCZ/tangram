#!/bin/bash
#
### Globální proměné, ručně zadané
DECRYPTIP5="10.170.22.85"
SLOT5="SLOT5"
DIR="./TANGRAM-1_PRAHA-HORNI"
REPORT="mtecl@coprosys.cz"
#
### Globální proměné, které není třeba měnit
DECRYPT5="$DIR/$SLOT5/DECRYPT.ttx"
CHANNELS5="$DIR/$SLOT5/CHANNELS.ttx"
STATUS5="$DIR/$SLOT5/STATUS.ttx"
LOG5="$DIR/$SLOT5/log.ttx"
LOCK5="$DIR/$SLOT5/lock."
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "$DIR" ];then
	mkdir $DIR
fi
if [ ! -d "$DIR/$SLOT5" ];then
	mkdir $DIR/$SLOT5
fi
#
### Vyprázní log
### Při testování je nutné tento řádek zahashovat a dopsat si do něj, co je potřeba

> $LOG5

#
### Vypíše si data z Tangramu - seznam kanálů, co se kde dekryptuje a STATUS5 dekryptování
snmpwalk -v2c -ccoprosys $DECRYPTIP5 iso.3.6.1.4.1.7465.20.2.9.1.2.1.7.1.3.1|cut -f18 -d'.' > $CHANNELS5
snmpwalk -v2c -ccoprosys $DECRYPTIP5 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.2.1|cut -f18-19 -d'.' > $DECRYPT5
snmpwalk -v2c -ccoprosys $DECRYPTIP5 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.4.1|cut -f18-19 -d'.'|grep INTEG > $STATUS5

sed -i 's/\r$//g' $CHANNELS5
sed -i 's/\r$//g' $DECRYPT5
sed -i 's/\r$//g' $STATUS5

if [ ! $(cat $STATUS5|wc -l) -gt 0 ]; then
	echo -e "\n\t$DIR-$SLOT5 nic nedekriptuje. Není co hlídat\n"
	exit
fi
for SID in $(cat $DECRYPT5|awk '{ print $4 }'); do
	PROGRAM=`cat $CHANNELS5| grep -w "$SID ="|tr -d '"'|cut -f4- -d' '`
	NUMBER=`cat $DECRYPT5|grep -w " $SID" | awk '{ print $1 }'`
	STAV=`cat $STATUS5|grep $NUMBER |awk '{print $4}'`
	#
	### Vypíš info o programu, na kterém kartě je a jeho STATUS5
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
			echo -e "$PROGRAM\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG5
		else
			echo -e "$PROGRAM\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG5
		fi	
	fi
done
#
### Kontrola, že je log prázdný, pokud ne, odešle info o stavu
if [ $(cat $LOG5|wc -l) -gt 0 ]; then
	if [ -f "$LOCK5" ]; then
		echo -e "\n\tDescrabling still not working on some program/s.\n\tLOCK file exist. Nothing to do.\n"
	else
	        echo -e "\n\tThere is something in the log -> Sending report to $REPORT and creating LOCK5 file.\n"
		cat $LOG5 | mail -a from:iptvmaster@coprosys.cz -s "POZOR - Už zase má krámy" $REPORT
	        touch $LOCK5
	fi
else
        echo -e "\n\tLog is empty, deleting LOCK5 file...\n"
	sleep 1
        if [ ! -f "$LOCK5" ]; then
        	echo -e "\tLOCK file does not exist. Nothink to do.\n"
	        exit
        else
        	echo -e "\tLOCK file exist, deleting.\n"
        	rm $LOCK5
        fi
fi
