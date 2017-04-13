#!/bin/bash

#make sure .ssh directory exists
mkdir -p ~/.ssh && chmod 700 ~/.ssh

echo -n "IU username: "
read USERNAME
echo -n "IU password: "
read -s PASSWORD
echo

#create keytab
(
cd ~/.ssh
rm -f hpss.keytab
ktutil > /dev/null <<INTER
addent -password -p $USER@ADS.IU.EDU -k 1 -e rc4-hmac
$PASSWORD
addent -password -p $USER@ADS.IU.EDU -k 1 -e aes256-cts
$PASSWORD
wkt hpss.keytab
quit
INTER
)


#test keytab
(
module load hpss > /dev/null 2>&1
export HPSS_PRINCIPAL=$USERNAME
export HPSS_AUTH_METHOD=keytab
export HPSS_KEYTAB_PATH=$HOME/.ssh/hpss.keytab
hsi ls > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "Keytab successfully created."
else
	echo "Failed to create keytab. Common cause of errors are ..."
	echo "You've entered a wrong password (try again)"
	echo "You haven't created your SDA account created. (Create it at https://access.iu.edu/Accounts)"
	exit 1
fi
)

#add exports to .bashrc
grep "HPSS_PRINCIPAL" ~/.bashrc > /dev/null
if [ $? -eq 0 ]; then
	#looks like HPSS_PRINCIPAL is already configured in .bashrc
	echo "Please add following to $HOME/.bashrc"
	echo
	echo "export HPSS_PRINCIPAL=$USERNAME"
	echo "export HPSS_AUTH_METHOD=keytab"
	echo "export HPSS_KEYTAB_PATH=$HOME/.ssh/hpss.keytab"
else
	#not there.. add exports to .bashrc
	echo "" >> ~/.bashrc
	echo "#### added by kktgen #####" >> ~/.bashrc
	echo "export HPSS_PRINCIPAL=$USERNAME" >> ~/.bashrc
	echo "export HPSS_AUTH_METHOD=keytab" >> ~/.bashrc
	echo "export HPSS_KEYTAB_PATH=$HOME/.ssh/hpss.keytab" >> ~/.bashrc
fi

