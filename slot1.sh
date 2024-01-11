#!/bin/bash
#
#
### Globální proměné, ručně zadané
DECRYPTIP1="10.170.22.81"
SLOT1="SLOT1"
DIR="./TANGRAM-1_PRAHA-HORNI"
REPORT="mtecl@coprosys.cz"
#
### Globální proměné, které není třeba měnit
DECRYPT1="$DIR/$SLOT1/DECRYPT1.ttx"
CHANNELS1="$DIR/$SLOT1/CHANNELS1.ttx"
STATUS1="$DIR/$SLOT1/STATUS1.ttx"
LOG1="$DIR/$SLOT1/log.ttx"
LOCK1="$DIR/$SLOT1/lock."
#
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "$DIR" ];then
	mkdir $DIR
fi
if [ ! -d "$DIR/$SLOT1" ];then
	mkdir $DIR/$SLOT1
fi
#
### Vyprázní log
### Při testování je nutné tento řádek zahashovat a dopsat si do něj, co je potřeba

> $LOG1

#
### Vypíše si data z Tangramu - seznam kanálů, co se kde dekryptuje a STATUS1 dekryptování
snmpwalk -v2c -ccoprosys $DECRYPTIP1 iso.3.6.1.4.1.7465.20.2.9.1.2.1.7.1.3.1|cut -f18 -d'.' > $CHANNELS1
snmpwalk -v2c -ccoprosys $DECRYPTIP1 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.2.1|cut -f18-19 -d'.' > $DECRYPT1
snmpwalk -v2c -ccoprosys $DECRYPTIP1 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.4.1|cut -f18-19 -d'.'|grep INTEG > $STATUS1

sed -i 's/\r$//g' $CHANNELS1
sed -i 's/\r$//g' $DECRYPT1
sed -i 's/\r$//g' $STATUS1

for SID in $(cat $DECRYPT1|awk '{ print $4 }'); do
	PROGRAM=`cat $CHANNELS1| grep -w "$SID ="|tr -d '"'|cut -f4- -d' '`
	NUMBER=`cat $DECRYPT1|grep -w " $SID" | awk '{ print $1 }'`
	STAV=`cat $STATUS1|grep $NUMBER |awk '{print $4}'`
	#
	### Vypíš info o programu, na kterém kartě je a jeho STATUS1
#	echo -e "\t Pozice: $NUMBER"
#	echo -e "\t Program: $PROGRAM"
#	echo -e "\t Staus: $STAV\n"
	if [ $STAV -eq 2 ];then
		if [ ${#PROGRAM} -ge 8 ];then
			echo -e "$PROGRAM\t\t - v pořádku"
		else
			echo -e "$PROGRAM\t\t\t - v pořádku"
		fi
	else
		if [ ${#PROGRAM} -ge 8 ];then
			echo -e "$PROGRAM\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG1
		else
			echo -e "$PROGRAM\t\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG1
		fi	
	fi
done
#
### Kontrola, že je log prázdný, pokud ne, odešle info o stavu
if [ $(cat $LOG1|wc -l) -gt 0 ]; then
	if [ -f "$LOCK1" ]; then
	echo -e "\n\tDescrabling still not working on some program/s.\n\tLOCK file exist. Nothing to do.\n"
	else
        echo -e "\n\tThere is something in the log -> Sending report to $REPORT and creating LOCK1 file.\n"
	cat $LOG1 | mail -a from:iptvmaster@coprosys.cz -s "POZOR - Už zase má krámy" $REPORT
        touch $LOCK1
	fi
else
        echo -e "\n\tLog is empty, deleting LOCK1 file...\n"
	sleep 1
        if [ ! -f "$LOCK1" ]; then
        	echo -e "\tLOCK file does not exist. Nothink to do.\n"
	        exit
        else
        	echo -e "\tLOCK file exist, deleting.\n"
        	rm $LOCK1
        fi
fi

#By Jip
