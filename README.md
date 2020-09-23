ArchivesSpace Docker
======================
Repository containing the Docker setup and configuration for the ArchivesSpace
application. It includes CI/CD that will automatically build and deploy the Docker
image to the application servers depending on the branch of this repository.

Contents
--------
* [Setup](#setup)
* [Updating the ArchivesSpace Version](#updating-the-archivesspace-version)
* [Resetting the Solr Index](#resetting-the-solr-index)
* [Backup and Restore](#backup-and-restore)
* [Developer Notes](#developer-notes)

Setup
---------------------

### Install docker
```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common python3-pip apache2
```

Then add the key and source to apt:  
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Finally, update apt sources and install Docker and supporting packages:  
```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### Install Docker Compose
```
sudo pip3 install docker-compose
```

### Setup UFW
The local firewall needs to be updated to include the IP ranges you 
want to restrict 80/443 access to, but additionally the docker 
internal nonroutable range as well.
```
# Restricted example. Include other IP restrictions as relavent
ufw allow from 192.168.0.0/16 to any port  80,443 proto tcp

# Public example
ufw allow http
ufw allow https
```

### SSL setup
In order to use SSL, you will need to obtain an SSL certificate and 
provide the relavent files to the docker instance via a volume.  
```
# create the combined ssl certificate
cat archivesspace_interm.cer >> archivesspace_cert.cer
# create the volume
docker volume create archivesspace-docker_ssl
docker volume inspect archivesspace-docker_ssl
# copy the ssl cert files to the volume
cp archivesspace.key [volume path]/
cp archivesspace_cert.cer [volume path]/
```

### Local customizations

#### Settings
Search this repository for references of `TODO` to see all the places 
recommended for customizations.

#### config.rb
We have included a sample `config.patch` file that can be used, but for any 
additional changes you would liek to make to the `config.rb` in the image you 
can do the following: 
```
# Make my updates in this file
vim config.rb
# Make a new patch file
./make_patch
```

### (Optional) Database setup
If you want to load the instance with an initial set of data, you can import from
a dump file.  
```
cat archivesspace.sql | docker exec -i db /usr/bin/mysql -u as --password=as123 archivesspace
```

### Option 1: CI/CD Setup

#### Create a deploy user
Create a user that will have read-only access to the repository to 
pull changes.  

```
adduser deploy
passwd -l deploy
sudo -Hu deploy ssh-keygen -o -t ed25519 -C deploy@archivesspace
```

Now add that as a deploy key to the git repository providing the public key
```
cat /home/deploy/.ssh/id_ed25519.pub
```

#### Clone the repository
Create the local copy of the repository.  
```
cd /home/deploy
sudo -Hu deploy git clone git@gitlab.msu.edu:msu-libraries/public/archivesspace-docker.git
```

#### Grant access to the GitLab runner user
From the runner server, get the runner user's public key:  
```
ssh gitlab-runner
sudo cat /home/gitlab-runner/.ssh/id_rsa.pub
```

Now add that to the deploy server as an `authorized_key`.  
```
vim /home/deploy/.ssh/authorized_keys
```

Test the connection, ensure that it does not prompt for a password:  
```
ssh gitlab-runner
sudo -Hu gitlab-runner ssh deploy@archivesspace
```

Add the user to the docker group so that it can run the appropriate commands:  
```
adduser deploy docker
```

#### Grant deploy user extra privileges
The deploy user will need to be able to run `sudo` on a few commands. To do this, 
edit the sudoers file by running `sudo visudo` and adding the following lines:  

```
deploy ALL=(root) NOPASSWD: /bin/systemctl restart archivesspace, /bin/cp /home/deploy/archivesspace-docker/etc/systemd/system/archivesspace.service /etc/systemd/system/archivesspace.service, /bin/systemctl daemon-reload, /bin/systemctl enable archivesspace, /bin/systemctl status archivesspace, /bin/cp /home/deploy/archivesspace-docker/etc/logrotate.d/archivesspace-docker /etc/logrotate.d/, /bin/systemctl stop archivesspace, /bin/systemctl start archivesspace
```

### Option 2: Local Setup

#### Service setup
```
cp etc/systemd/system/archivesspace.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable archivesspace
```

#### Log rotation
```
cp etc/logrotate.d/archivesspace-docker /etc/logrotate.d/
```

Updating the ArchivesSpace Version
----------------------------------

### Config file changes
This repository contains a [patch file](config.patch) that will apply our local changes 
to the defaul configuration file. It is possible that there are new changes to the config 
that we will want applied, in that case you will need to generate a new patch file. Here 
are the steps to re-generate one:  
```
# Example contains both the AS default config and our local copy with latest changes
diff -u config.rb.orig config.rb > config.patch
```

### Backup the database
Prior to running the upgrade, take a dump of the current database state. You can get the 
command from the cron entry, or from the [backup and restore](#backup-and-restore) section. 

### Updating the version
To increase the version number installed, update the `.gitlab-ci.yml` with the version in the `AS_VERSION` argument. 
If you want to increase the version only on one environment, you can update it for only the `_TEST` containers.

Additionally, you probably will want to [reset the Solr index](#resetting-the-solr-index) to apply the lastest schema changes.  


Resetting the Solr Index
----------------------------------
Resetting the Solr index can help resolve search related issues such as records not appearing after they have 
been successfully created. It should also be used after updating the ArchivesSpace version to apply the latest 
schema changes. 

```
sudo ./reset-solr.sh
```

This command *should* remove  the contents of the data directory, but sometimes doesn't. To do so manually:
```
docker exec -it archivesspace bash
rm -rf archivesspace/data/*
exit
```

**Note**: It takes hours to do a full re-index, so ideally time this at the end of the day so it can complete 
overnight.  

Backup and Restore
--------------------
The only portion that should require backups is the database. This is because everything 
else can be generated from that data. The software and configs are all stored in the GitLab 
container registry and can be restored from there if needed. 

Here are example commands to backup and restore the database data:  
```
# Backup
docker exec db /usr/bin/mysqldump -u as --password=as123 archivesspace > archivesspace.sql

# Restore
cat archivesspace.sql | docker exec -i db /usr/bin/mysql -u as --password=as123 archivesspace
```

Troubleshooting
---------------
You can check which docker containers are running by executing:  
```
docker ps
```

To see which ports the server is listening on run:  
```
sudo lsof -i -P -n | grep LISTEN
```

To identify all of the data volumes used by  the images:  
```
docker volume ls
```

To identify the server location of the volume data:  
```
docker volume inspect [volume name]
docker volume inspect archivesspace-docker_nginx_logs
```

To see the logs for a container, given the container name (from `docker ps`):  
```
docker logs CONTAINER [-f]
docker logs archivesspace -f
```

Developer Notes
---------------------
For development and testing, you can build the images locally instead of using the 
ones stored in GitLab's container registry.
```
docker-compose up -f docker-compose.build.yml --build -d
```

To connect to an instance for debugging:  
```
docker exec -it archivesspace bash
```
