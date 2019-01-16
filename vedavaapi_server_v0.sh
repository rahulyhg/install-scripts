export DEBIAN_FRONTEND=noninteractive

#enable universe repos if already not
sudo apt-get -yq install software-properties-common
sudo apt-add-repository universe
sudo apt-get -yq  update

#install python and mongodb
sudo apt-get -yq install python3 unzip wget git python3-pip mongodb


#"~/vedavaapi" is our rootdir in which all packages will reside
mkdir vedavaapi
cd vedavaapi
ROOTDIR=$(pwd)

#git clone all related repos
declare -A v0repos=(["core_services"]="1842b6de916c0726cd5a7dd452f164834e86734c" ["vedavaapi_api"]="4ded583471b03b0dd0e966f70deaca55425bc804" ["sanskrit_ld"]="cc98aebbfa9ec48f8778227cafc63ca62551d377" ["sanskrit_data"]="023ee9d5ab923d6b55f7349d9a66fb9ce8e3917b" ["objectdb"]="b3b63e93432519d7d575536d5e2726b34c1be549" ["ullekhanam"]="9bcd9f64fffd977264180b0d24504fc4e484f6a0" ["iiif"]="cbe02e90db4bdc35826acc8f2476a9afd9e453e7" ["google_services_helper"]="e4a29105ef257bf8ee1cbc2746b9c4ee70c8c3f6" ["docimage"]="0f30801d6c896de47e4eb2e0a22f678b3e3a89c5")
for repo in "${!v0repos[@]}"
do
	giturl="https://github.com/vedavaapi/${repo}.git"
	git clone ${giturl}
	cd ./${repo}
	git checkout ${v0repos[$repo]}
	echo "export PYTHONPATH=\"\${PYTHONPATH}:$(pwd)\"" >> ~/.bashrc
	cd -
done

#install all python dependencies
sudo pip3 install requests google-auth-oauthlib google-auth-httplib2 google-api-python-client authlib #for google_services_helper
sudo pip3 install jsonschema jsonpickle bcrypt yurl #for sanskrit_data
sudo apt-get  -yq install libsm6 libxext6 libxrender-dev #required by opencv. if not exist already
sudo pip3 install scikit-image numpy scipy Pillow matplotlib opencv-python # for docimage, very large libraries, takes some time.
sudo pip3 install pymongo # for interaction with mongodb
sudo pip3 install flask flask-cors flask-restplus flask-oauthlib furl # for flask. also installs jinja and werkzeug
sudo pip3 install indic_transliteration

git clone --depth 1 https://github.com/loris-imageserver/loris.git
sudo apt-get -yq install libjpeg-turbo8-dev libfreetype6-dev zlib1g-dev liblcms2-dev liblcms2-utils libtiff5-dev python-dev libwebp-dev
sudo pip3 install configobj requests mock responses attrs
sudo pip3 install iiif_prezi

#create and own the directory to store data
DATADIR='/opt/vedavaapi' # our root dir for storing data of all vedavaapi services
sudo mkdir ${DATADIR}
sudo chown -R $USER: ${DATADIR}

# now we have to have credentials to communicate with gservices. attatching sample creds. plz delete them after test use
wget --no-check-certificate "https://apps.vedavaapi.org/creds/creds.zip" -O creds.zip
unzip creds.zip

#start mongodb server
sudo systemctl start mongodb

cd vedavaapi_api
python3 genconf.py -m ${DATADIR} -o --db_type "mongo" --db_host "mongodb://127.0.0.1:27017" --creds_to_copy "${ROOTDIR}/creds" -d --host "0.0.0.0" -p 5000 ullekhanam users iiif_presentation iiif_image # no need to mention any dependent services, as dependency services will automatically get started.

sudo sed -i 's#oauth/google/vedavaapi/client1#oauth/google/vedavaapi/client0#' ${DATADIR}/conf/services/users.json

#start server
python3 vedavaapi/run.py
