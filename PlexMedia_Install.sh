#!/bin/bash

##Create Environment##
if [ $(id -u) != 0 ]; then 
    echo 'Please use root user, must be root'
    exit
fi

adduser -c "Plex Media Server User" -d /home/plex -s /bin/bash plex

passwd plex

usermod -aG wheel plex

sudo yum install wget -y

if [ ! -d /home/plex/Downloads ]; then
    mkdir /home/plex/Downloads
    chown -R plex:plex /home/plex/Downloads
fi

##Install Plex##
echo 'Go here to get your RPM package:'
echo 'https://www.plex.tv/downloads/'
echo "Copy/Paste the Plex Media URL here so I may download the RPM:"
read -p ">>> " FileIWant

wget -P /home/plex/Downloads/ $FileIWant

sleep 3
echo ''
echo 'Installing Plex'
echo ''

yum localinstall /home/plex/Downloads/plexmediaserver*.rpm -y

DIREC=/var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Data/com.plexapp.agents.hama/._StoredValues
if [ ! -d "$DIREC" ]; then
    mkdir -p /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Data/com.plexapp.agents.hama/._StoredValues
    chmod 775 -R /var/lib/plexmediaserver
    chown -R plex:plex /var/lib/plexmediaserver/
fi

echo 'Shutting off IPTables'

systemctl stop iptables

sleep 2

echo ''
echo 'Starting Plex Media Server'

sleep 2
service plexmediaserver start
sleep 3
systemctl enable plexmediaserver.service

sleep 2
ipADDR=$(ip addr | grep -e 'inet' | awk 'NR==3' | awk '{print $2}' | sed 's/...$//g')
echo ''
echo "Test plex at $ipADDR:32400/web"
read -r -p "Did it work? (y/n)" answerMe

while [[ $answerMe != 'y' && $answerMe != 'n' ]]; do
	echo 'Please respond with a "y" or "n".'
	read -r -p "Did it work? (y/n)" answerMe
done

if [ $answerMe == 'n' ]; then
    echo ''
    echo 'Manual testing needed. IPTables are currently turned off.'
    exit
elif [ $answerMe == 'y' ]; then
    systemctl start iptables
    echo 'IPTables are now back up!'
fi


##IPTable rules to inject##
echo ''
echo 'Opening ports for Plex'

sleep 2

iptables -A INPUT -p udp --dport 1900 -j ACCEPT
iptables -A INPUT -p udp --dport 5353 -j ACCEPT
iptables -A INPUT -p udp --dport 32410 -j ACCEPT
iptables -A INPUT -p udp --dport 32412 -j ACCEPT
iptables -A INPUT -p udp --dport 32413 -j ACCEPT
iptables -A INPUT -p udp --dport 32414 -j ACCEPT
iptables -A INPUT -p tcp --dport 32400 -j ACCEPT
iptables -A INPUT -p tcp --dport 32469 -j ACCEPT

/sbin/service iptables save

echo ''
echo "Test Plex at $ipADDR:32400/web, this time we have IPTables turned on."
read -r -p 'Does Plex work? (y/n)' secondAnswer

while [[ $secondAnswer != 'y' && $secondAnswer != 'n' ]]; do
	echo 'Please respond with a "y" or "n".'
	read -r -p 'Does Plex work? (y/n)' secondAnswer
done


if [ $secondAnswer == 'y' ]; then
    echo 'Good, we will reboot system to ensure this shit sticks'
    echo 'Rebooting system now..'
    echo ''
    sleep 10
    reboot
elif [ $secondAnswer == 'n' ]; then
    echo 'Looks like iptables were not configured correctly. Figure it out.'
    echo 'Goodbye'
    exit
fi


