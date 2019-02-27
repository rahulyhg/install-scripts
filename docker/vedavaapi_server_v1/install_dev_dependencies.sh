sudo apt-get -yq install software-properties-common
sudo apt-add-repository universe
sudo apt-get -yq  update

sudo apt-get -yq install python3 python3-requests python3-bcrypt curl git
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

newgrp docker
echo "installed docker and python3 successfully.. it is adviced to logot and login for docker configuration"
