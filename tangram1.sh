#!/bin/bash
#
#
### Globální proměné, ručně zadané
DECRYPTIP1="10.170.22.81"
SLOT1="SLOT1"
DIR="TANGRAM-1_PRAHA-HORNI"
REPORT="mtecl@coprosys.cz"
SLOT1INFO="Informace z Tangramu 1, SLOT 1"
#
### Globální proměné, které není třeba měnit
DECRYPT1="./$DIR/$SLOT1/DECRYPT1.ttx"
CHANNELS1="./$DIR/$SLOT1/CHANNELS1.ttx"
STATUS1="./$DIR/$SLOT1/STATUS1.ttx"
LOG1="./$DIR/$SLOT1/log.ttx"
LOCK1="./$DIR/$SLOT1/lock."
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "./$DIR" ];then
	mkdir ./$DIR
fi
if [ ! -d "./$DIR/$SLOT1" ];then
	mkdir ./$DIR/$SLOT1
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
#
#
### Info o slotu
echo -e "\n\t$SLOT1INFO"
#echo -e "********************************************************"
echo -e "------------------------------------------------"
#
### Kontrola, zda slot decryptuje či nikoliv
if [ ! $(cat $STATUS1|wc -l) -gt 0 ]; then
	echo -e "$DIR - $SLOT1 nic nedekriptuje. Není co hlídat\n"
	exit
fi
#
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
			echo -e "$PROGRAM\t\t - $SLOT ($DECRYPTIP1) " >> $LOG1
		else
			echo -e "$PROGRAM\t\t\t - $SLOT ($DECRYPTIP1) " >> $LOG1
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
		### Testing - send to @Martin Tecl
		curl -k -X POST --data-urlencode "payload={\"username\": \"IPTV-Praha\",\"text\": \"Nefunkční descrambling u:\n*$(cat $LOG1)*\", \"icon_emoji\": \":satellite_antenna:\"}" https://hooks.slack.com/services/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

	fi
else
        echo -e "\nLog is empty, deleting LOCK1 file..."
	sleep 1
        if [ ! -f "$LOCK1" ]; then
        	echo -e "LOCK file does not exist. Nothink to do.\n"
        else
        	echo -e "LOCK file exist, deleting.\n"
        	rm $LOCK1
        fi
fi
###################################################################################################################
###################################################################################################################
#
### Globální proměné, ručně zadané - SLOT 3 
DECRYPTIP3="10.170.22.83"
SLOT3="SLOT3"
SLOT3INFO="Informace z Tangramu 1, SLOT 3"
#
### Globální proměné, které není třeba měnit
DECRYPT3="./$DIR/$SLOT3/DECRYPT.ttx"
CHANNELS3="./$DIR/$SLOT3/CHANNELS.ttx"
STATUS3="./$DIR/$SLOT3/STATUS.ttx"
LOG3="./$DIR/$SLOT3/log.ttx"
LOCK3="./$DIR/$SLOT3/lock."
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "./$DIR" ];then
	mkdir ./$DIR
fi
if [ ! -d "./$DIR/$SLOT5" ];then
	mkdir ./$DIR/$SLOT5
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
### Info o slotu
echo -e "\t$SLOT3INFO"
#echo -e "********************************************************"
echo -e "------------------------------------------------"
#
### Kontrola, zda slot decryptuje či nikoliv
if [ ! $(cat $STATUS3|wc -l) -gt 0 ]; then
	echo -e "$DIR-$SLOT3 nic nedekriptuje. Není co hlídat\n"
	exit
fi
#
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
				echo -e "$PROGRAM\t\t - v pořádku"
			else
				echo -e "$PROGRAM\t - v pořádku"
			fi
		else
			echo -e "$PROGRAM\t\t\t - v pořádku"
		fi
	else
		if [ ${#PROGRAM} -ge 8 ];then
			if [ ${#PROGRAM} -le 16 ];then
				echo -e "$PROGRAM\t\t - $SLOT ($DECRYPTIP3) " >> $LOG3
			else
				echo -e "$PROGRAM\t - $SLOT ($DECRYPTIP3) " >> $LOG3
			fi
		else
			echo -e "$PROGRAM\t\t\t - $SLOT3 ($DECRYPTIP3) " >> $LOG3
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
		cat $LOG3 | mail -a from:iptvmaster@coprosys.cz -s "IPTV! POZOR - problém s descramblinkem" $REPORT
		### Testing - send to @Martin Tecl
		curl -k -X POST --data-urlencode "payload={\"username\": \"IPTV-Praha\",\"text\": \"Nefunkční descrambling u:\n*$(cat $LOG3)*\", \"icon_emoji\": \":satellite_antenna:\"}" https://hooks.slack.com/services/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

	        touch $LOCK3
	fi
else
        echo -e "\nLog is empty, deleting LOCK3 file..."
	sleep 1
        if [ ! -f "$LOCK3" ]; then
        	echo -e "LOCK file does not exist. Nothink to do.\n"
        else
        	echo -e "LOCK file exist, deleting.\n"
        	rm $LOCK3
        fi
fi
###################################################################################################################
###################################################################################################################
#
### Globální proměné, ručně zadané
DECRYPTIP5="10.170.22.85"
SLOT5="SLOT5"
SLOT5INFO="Informace z Tangramu 1, SLOT 5"
#
### Globální proměné, které není třeba měnit
DECRYPT5="./$DIR/$SLOT5/DECRYPT.ttx"
CHANNELS5="./$DIR/$SLOT5/CHANNELS.ttx"
STATUS5="./$DIR/$SLOT5/STATUS.ttx"
LOG5="./$DIR/$SLOT5/log.ttx"
LOCK5="./$DIR/$SLOT5/lock."
#
### Zkontroluje případně vytvoří adresáře
if [ ! -d "./$DIR" ];then
	mkdir ./$DIR
fi
if [ ! -d "./$DIR/$SLOT5" ];then
	mkdir ./$DIR/$SLOT5
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
#
### Info o slotu
echo -e "\t$SLOT5INFO"
#echo -e "********************************************************"
echo -e "------------------------------------------------"
#
if [ ! $(cat $STATUS5|wc -l) -gt 0 ]; then
	echo -e "$DIR-$SLOT5 nic nedekriptuje. Není co hlídat\n"
	exit
fi
#
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
			echo -e "$PROGRAM\t\t - $SLOT ($DECRYPTIP5) " >> $LOG5
		else
			echo -e "$PROGRAM\t\t\t - $SLOT ($DECRYPTIP5) " >> $LOG5
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
		### Testing - send to @Martin Tecl
		curl -k -X POST --data-urlencode "payload={\"username\": \"IPTV-Praha\",\"text\": \"Nefunkční descrambling u:\n*$(cat $LOG5)*\", \"icon_emoji\": \":satellite_antenna:\"}" https://hooks.slack.com/services/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

	        touch $LOCK5
	fi
else
        echo -e "\nLog is empty, deleting LOCK5 file...\n"
	sleep 1
        if [ ! -f "$LOCK5" ]; then
        	echo -e "LOCK file does not exist. Nothink to do.\n"
        else
        	echo -e "LOCK file exist, deleting.\n"
        	rm $LOCK5
        fi
fi

# By Jip 01/2024
