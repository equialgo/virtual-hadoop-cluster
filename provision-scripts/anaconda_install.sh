#!/bin/bash
sshUser=$1
anacondafile=$2
masterAddress=$3
nodesString=$4

# Install Anaconda in many connected computers as the default Python for a user in that computer
# This is what is added by Anaconda to the .bashrc of the user with the Anaconda installation
# added by Anaconda 2.1.0 installer
# export PATH="/home/yarn/anaconda/bin:$PATH"

if [[ $# < 4 ]]
then
  echo "Usage: anaconda_install.sh <ssh user> <anaconda bash install file> <master address  accessible by the current user> <list of node addresses accessible by the current user, separated by ','>"
  echo "Example: bash anaconda_install.sh root /home/user/Installers/Python/Anaconda-2.1.0-Linux-x86_64.sh 192.168.232.110 192.168.232.111,192.168.232.112"
  exit 1
fi

if [ ! -f $anacondafile ]
then
  echo "Your didn't provide an anaconda installation file"
  exit 1
fi

#nodesString="$masterAddress,$nodesString"
listOfNodes=${nodesString//,/ }

hostScriptPathComment='echo "# Add Anaconda to PATH" >> ~/.bashrc;'
toSuC='echo "export PATH=\"$HOME/anaconda/bin:\$PATH\"" >> ~/.bashrc;'

echo "creating yarn user directory on hdfs"
ssh $sshUser@$masterAddress "sudo su hdfs -c 'hdfs dfs -mkdir /user/yarn'; sudo su hdfs -c 'hdfs dfs -chown yarn:yarn /user/yarn'"
echo "rsync-ing file to master"
rsync $anacondafile $sshUser@$masterAddress:/tmp/anaconda.sh
echo "installing anaconda" 
ssh $sshUser@$masterAddress "sudo chown vagrant '/tmp/anaconda.sh';sudo chmod 775 '/tmp/anaconda.sh';bash /tmp/anaconda.sh -b;$hostScriptPathComment$toSuC" 
ssh $sshUser@$masterAddress "sudo chown yarn:hadoop '/tmp/anaconda.sh';sudo chmod 775 '/tmp/anaconda.sh';sudo su yarn -c 'bash /tmp/anaconda.sh -b';sudo su yarn -c '$hostScriptPathComment';sudo su yarn -c '$toSuC'"


for node in $listOfNodes
do
  echo "rsync-ing file to $node"
  rsync $anacondafile $sshUser@$node:/tmp/anaconda.sh
  echo "installing anaconda"
  ssh $sshUser@$node "sudo chown yarn:hadoop '/tmp/anaconda.sh';sudo chmod 775 '/tmp/anaconda.sh';sudo su yarn -c 'bash /tmp/anaconda.sh -b';sudo su yarn -c '$hostScriptPathComment';sudo su yarn -c '$toSuC'"
done
