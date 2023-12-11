#!/bin/bash
#
#
### Globální proměné, ručně zadané
DECRYPTIP="10.170.22.81"
SLOT="SLOT1"
DIR="./TANGRAM-1_PRAHA-HORNI"
#
### Globální proměné, které není třeba měnit
DECRYPT="$DIR/$SLOT/decrypt.ttx"
CHANNELS="$DIR/$SLOT/channels.ttx"
STATUS="$DIR/$SLOT/status.ttx"
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
	### prihlasi se na gpon a posle zalohu na netvision

	echo -e "\t Pozice: $NUMBER"
	echo -e "\t Program: $PROGRAM"
	echo -e "\t Staus: $STAV\n"

done
