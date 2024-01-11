#!/bin/bash
#
### Globální proměné, ručně zadané
DECRYPTIP3="10.170.22.83"
SLOT3="SLOT3"
DIR="./TANGRAM-1_PRAHA-HORNI"
REPORT="mtecl@coprosys.cz"
#
### Globální proměné, které není třeba měnit
DECRYPT3="$DIR/$SLOT3/DECRYPT.ttx"
CHANNELS3="$DIR/$SLOT3/CHANNELS.ttx"
STATUS3="$DIR/$SLOT3/STATUS.ttx"
LOG3="$DIR/$SLOT3/log.ttx"
LOCK3="$DIR/$SLOT3/lock."
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

> $LOG3

#
### Vypíše si data z Tangramu - seznam kanálů, co se kde dekryptuje a STATUS3 dekryptování
snmpwalk -v2c -ccoprosys $DECRYPTIP3 iso.3.6.1.4.1.7465.20.2.9.1.2.1.7.1.3.1|cut -f18 -d'.' > $CHANNELS3
snmpwalk -v2c -ccoprosys $DECRYPTIP3 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.2.1|cut -f18-19 -d'.' > $DECRYPT3
snmpwalk -v2c -ccoprosys $DECRYPTIP3 iso.3.6.1.4.1.7465.20.2.9.6.2.1.4.1.4.1|cut -f18-19 -d'.'|grep INTEG > $STATUS3

sed -i 's/\r$//g' $CHANNELS3
sed -i 's/\r$//g' $DECRYPT3
sed -i 's/\r$//g' $STATUS3
#
### Kontrola, zda slot decryptuje či nikoliv
if [ ! $(cat $STATUS3|wc -l) -gt 0 ]; then
	echo -e "\n\t$DIR-$SLOT3 nic nedekriptuje. Není co hlídat\n"
	exit
fi


for SID in $(cat $DECRYPT3|awk '{ print $4 }'); do
	PROGRAM=`cat $CHANNELS3| grep -w "$SID ="|tr -d '"'|cut -f4- -d' '`
	NUMBER=`cat $DECRYPT3|grep -w " $SID" | awk '{ print $1 }'`
	STAV=`cat $STATUS3|grep $NUMBER |awk '{print $4}'`
	#
	### Vypíš info o programu, na kterém kartě je a jeho STATUS3
#	echo -e "\t Pozice: $NUMBER"
#	echo -e "\t Program: $PROGRAM"
#	echo -e "\t Staus: $STAV\n"
	if [ $STAV -eq 2 ];then
		if [ ${#PROGRAM} -ge 8 ];then
			if [ ${#PROGRAM} -le 16 ];then
				echo -e "$PROGRAM${#PROGRAM}\t\t - v pořádku"
			else
				echo -e "$PROGRAM${#PROGRAM}\t - v pořádku"
			fi
		else
			echo -e "$PROGRAM\t\t\t - v pořádku"
		fi
	else
		if [ ${#PROGRAM} -ge 8 ];then
			echo -e "$PROGRAM\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG3
		else
			echo -e "$PROGRAM\t\t\t - Neprobíhá descrabling, je potřeba prověřit" >> $LOG3
		fi	
	fi
done
#
### Kontrola, že je log prázdný, pokud ne, odešle info o stavu
if [ $(cat $LOG3|wc -l) -gt 0 ]; then
	if [ -f "$LOCK3" ]; then
		echo -e "\n\tDescrabling still not working on some program/s.\n\tLOCK file exist. Nothing to do.\n"
	else
	        echo -e "\n\tThere is something in the log -> Sending report to $REPORT and creating LOCK3 file.\n"
		cat $LOG3 | mail -a from:iptvmaster@coprosys.cz -s "POZOR - Už zase má krámy" $REPORT
	        touch $LOCK3
	fi
else
        echo -e "\n\tLog is empty, deleting LOCK3 file...\n"
	sleep 1
        if [ ! -f "$LOCK3" ]; then
        	echo -e "\tLOCK file does not exist. Nothink to do.\n"
	        exit
        else
        	echo -e "\tLOCK file exist, deleting.\n"
        	rm $LOCK3
        fi
fi

