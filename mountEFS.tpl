#!/bin/bash

# Stopping JIRA service
echo "${EFS_dns_name}:/ ${jira_HOME}      nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0" | sudo tee --append /etc/fstab
sudo /etc/init.d/jira stop
# Making temp directory for JIRA_HOME
sudo mkdir /tmp/JIRA_HOME
#Making sure dot files are moved.
shopt -s dotglob nullglob
# Moving Jira home directory to temporaty folder
mv -v ${jira_HOME}/* /tmp/JIRA_HOME
# Mounting EFS to ${jira_HOME}
n=0
until [ $n -ge 10 ]
do
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_dns_name}:/ ${jira_HOME} && break
n=$[$n+1]
  sleep 60
done
# Giving Correct Ownership to mounted Directory
sudo chown -R jira:jira /mnt/JIRA_HOME
# Check if ${jira_HOME} is empty
sudo DIR="${jira_HOME}"
# look for empty dir 
if [ "$(ls -A $DIR)" ]; then
     echo "Not Empty"
else
    shopt -s dotglob nullglob;sudo mv -v /tmp/JIRA_HOME/* ${jira_HOME}
fi

# Starting JIRA
sudo /etc/init.d/jira start