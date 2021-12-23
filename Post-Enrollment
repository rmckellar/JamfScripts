#!/bin/bash

jamfbinary=$(/usr/bin/which jamf)
arch=$(/usr/bin/arch)

##########################################
echo "Installing Rosetta, if applicable"

if [ "$arch" == "arm64" ]; then
    echo "Apple Silicon - Installing Rosetta"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
elif [ "$arch" == "i386" ]; then
    echo "Intel - Skipping Rosetta"
else
    echo "Unknown Architecture"
fi
##########################################
echo "Reporting back to Jamf"
${jamfbinary} recon

##########################################
echo "Installing NoMADLoginAD"
${jamfbinary} policy -event "installNoLoMAD"

sleep 15

while true
do
loggedinuser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

echo $loggedinuser

    if [ "${loggedinuser}" == "root" ] || [ "${loggedinuser}" == "_mbsetupuser" ]; then
    echo "is root or mbsetupuser"
    sleep 10
    else
    echo "is local user"
    break
    fi
done

##########################################
echo "Installing depNotify and launching"
${jamfbinary} policy -event "installdepNotify"
