#!/bin/bash
yum update -y
amazon-linux-extras enable docker
yum install -y docker
service docker start
usermod -a -G docker ec2-user
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
systemctl enable Docker
yum -y install amazon-efs-utils
cd /
mkdir efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport {EFS ID}.efs.us-east-1.amazonaws.com:/ efs
cd efs
docker-compose up