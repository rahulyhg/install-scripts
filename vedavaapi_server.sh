export DEBIAN_FRONTEND=noninteractive

#enable universe repos if already not
sudo apt-get -yq install software-properties-common
sudo apt-add-repository universe
sudo apt-get update

#install python and mongodb
sudo apt-get -yq install python3 unzip python3-pip mongodb

#"~/vedavaapi" is our rootdir in which all packages will reside
mkdir vedavaapi && cd vedavaapi
ROOTDIR=$(pwd)

#git clone all related repos
declare -a gitrepos=("core_services" "vedavaapi_api" "ullekhanam" "smaps" "docimage" "objectdb" "google_services_helper" "sanskrit_data")
for repo in "${gitrepos[@]}"
do
  giturl="https://github.com/vedavaapi/${repo}.git"
  git clone --depth 1 ${giturl}
done

#install all python dependencies
sudo pip3 install requests google-auth-oauthlib google-auth-httplib2 google-api-python-client #for google_services_helper
sudo pip3 install jsonschema jsonpickle bcrypt yurl #for sanskrit_data
sudo apt-get install -y libsm6 libxext6 libxrender-dev #required by opencv. if not exist already
sudo pip3 install scikit-image numpy scipy Pillow matplotlib opencv-python # for docimage, very large libraries, takes some time.
sudo pip3 install pymongo # for interaction with mongodb
sudo pip3 install flask flask-cors flask-restplus flask-oauthlib furl # for flask. also installs jinja and werkzeug
sudo pip3 install indic_transliteration



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
python3 genconf.py -m ${DATADIR} -o --db_type "mongo" --db_host "mongodb://127.0.0.1:27017" --creds_to_copy "${ROOTDIR}/creds" -d --host "0.0.0.0" -p 9000 ullekhanam smaps # no need to mention any dependent services, as dependency services will automatically get started.


#start server
python3 vedavaapi/run.py
