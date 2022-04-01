#!/bin/sh

if [ -f /Users/*user*/Library/Keychains/login.keychain-db ];	then
	rm -rf /Users/*user*/Library/Keychains/login.keychain-db
	jamf policy -trigger *custom trigger*
	else
	echo "No Keychain Exists"
	jamf policy -trigger *custom trigger*
fi

exit 0
