#!/bin/bash
#  start from https://www.ubuntu.com/download/server
export DEBIAN_FRONTEND=noninteractive

parse_opts() {
	should_update_packages=1
	serve_through="flask"
	creds_path="https://apps.vedavaapi.org/creds/creds.zip"
	version_tag="v1.0"
	data_dir="/opt/vedavaapi"
	mongo_host_uri="mongodb://127.0.0.1:27017"
	server_name="api.vedavaapi.org"
	url_mount_path='py'

	OPTIND=1
	while getopts ft:c:v:d:m:s:u: opt; do
		echo "$opt: ${OPTARG}"
		case $opt in
			f ) should_update_packages=0;;
			t ) serve_through=${OPTARG};;
			c ) creds_path=${OPTARG};;
            v ) version_tag=${OPTARG};;
			d ) data_dir=${OPTARG};;
			m ) mongo_host_uri=${OPTARG};;
			s ) server_name=${OPTARG};;
			u ) url_mount_path=${OPTARG};;
		esac
	done
}


update_package_index() {
	#enable universe repos if already not
	sudo apt-get -yq install software-properties-common
	sudo apt-add-repository universe
	sudo apt-get -yq  update
}

install_dependencies() {
	sudo apt-get -yq install python3 unzip wget git python3-pip mongodb
	sudo apt-get -yq install apache2 apache2-utils libexpat1 ssl-cert libapache2-mod-wsgi-py3

	sudo apt-get -yq install python3-requests
	sudo pip3 install google-auth-oauthlib google-auth-httplib2 google-api-python-client authlib #for google_services_helper

	sudo apt-get -yq install python3-jsonschema python3-jsonpickle python3-bcrypt
	sudo pip3 install yurl
	sudo apt-get  -yq install libsm6 libxext6 libxrender-dev #required by opencv. if not exist already
	sudo apt-get install -y python3-numpy python3-scipy python3-matplotlib python3-opencv
	sudo pip3 install scikit-image Pillow

	sudo apt-get install -y python3-pymongo
	sudo apt-get install -y python3-flask
	sudo pip3 install flask-cors flask-restplus furl flask-oauthlib
	sudo pip3 install indic_transliteration

	sudo pip3 install configobj mock responses attrs
	sudo pip3 install iiif_prezi
}

clone_vedavaapi_github_repos() {
	declare repo_names=("core_services" "vedavaapi_api" "sanskrit_ld" "objectdb" "ullekhanam" "iiif" "google_services_helper" "docimage")
	for repo in ${repo_names[@]}; do
		local giturl="https://github.com/vedavaapi/${repo}.git"
		git clone ${giturl}
		cd ./${repo}
		git checkout tags/$1
		echo "export PYTHONPATH=\"\${PYTHONPATH}:$(pwd)\"" >> ~/.bashrc
		cd -
	done
}

install_loris() {
	git clone --depth 1 https://github.com/loris-imageserver/loris.git
	sudo apt-get -yq install libjpeg-turbo8-dev libfreetype6-dev zlib1g-dev liblcms2-dev liblcms2-utils libtiff5-dev python-dev libwebp-dev
}

setup_data_dir() {
	#create and own the directory to store data
	sudo mkdir $1
	sudo chown -R $USER: $1
}

get_creds() {
	
	local wd=$(pwd)
	cd $1;
	wget --no-check-certificate $2 -O creds.zip
	unzip creds.zip
	# cp -r $2 ./creds
	cd ${wd}
}

symlink_apache_conf() {
	# $2:data_dir; $1: root_dir
	local wsgi_conf_dir="$2/conf/_wsgi"
	local http_conf_file="${wsgi_conf_dir}/apache_conf.conf"
	local https_conf_file="${wsgi_conf_dir}/apache_https_conf.conf"

	local sites_available_dir="/etc/apache2/sites-available"
	local sa_http_conf_link_path="${sites_available_dir}/vedavaapi_api.conf"
	local sa_https_conf_link_path="${sites_available_dir}/vedavaapi_api-le-ssl.conf"

	sudo ln -s ${http_conf_file} ${sa_http_conf_link_path}
	sudo ln -s ${https_conf_file} ${sa_https_conf_link_path}

	local sites_enabled_dir="/etc/apache2/sites-enabled"
	sudo ln -s ${sa_http_conf_link_path} "${sites_enabled_dir}/vedavaapi_api.conf"
	sudo ln -s ${sa_https_conf_link_path} "${sites_enabled_dir}/vedavaapi_api-le-https.conf"
}

start_server() {
	# $2:data_dir; $1: root_dir; $3:: mongo_host_uri $4: serve_through; $5:server_name; $6:url_mount_path
	sudo systemctl start mongodb

	cd $1/vedavaapi_api
	python3 genconf.py -o -i $2 --db_type "mongo" --db_host "$3" --creds_dir "$1/creds" --server_name $5 --url_mount_path $6 -d --host "0.0.0.0" -p 5000 accounts objstore iiif_presentation iiif_image
	symlink_apache_conf "$1" "$2"

	case "$4" in
		flask ) python3 vedavaapi/run.py ;;
		apache ) sudo systemctl restart apache2 ;;
	esac
}


#"~/vedavaapi" is our rootdir in which all packages will reside
mkdir vedavaapi
cd vedavaapi
root_dir=$(pwd)

parse_opts "$@";
if [ ${should_update_packages} -eq 1 ]; then
	update_package_index;
fi
install_dependencies;
install_loris
clone_vedavaapi_github_repos ${version_tag};
setup_data_dir ${data_dir};
# version_specific_actions ${root_dir} ${version_tag}
get_creds ${root_dir} ${creds_path};
start_server ${root_dir} ${data_dir} ${mongo_host_uri} ${serve_through} ${server_name} ${url_mount_path};
