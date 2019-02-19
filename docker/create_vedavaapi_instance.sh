#!/bin/bash
#  start from https://www.ubuntu.com/download/server
export DEBIAN_FRONTEND=noninteractive

parse_opts() {
	install_dev_dependencies="false"
	org_name="vedavaapi"
	org_label="Vedavaapi"
	client_name="Vedavaapi Application Client 1"
	client_type="private"
	services="objstore accounts iiif_image iiif_presentation"
	url_mount_path=""
	mongo_data_dir='/data/vedavaapi_mongo'
	vedavaapi_data_dir='/data/vedavaapi'
	vedavaapi_api_port="8002"
	vedavaapi_test_port="5002"

	POSITIONAL=()
	while [[ $# -gt 0 ]]
	do
	key="$1"

	case $key in
	    --install_dev_dependencies)
	    install_dev_dependencies="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --org_name)
	    org_name="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --org_label)
	    org_label="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --admin_email)
	    admin_email="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --admin_password)
	    admin_password="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --google_client_creds_path)
	    google_client_creds_path="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --fb_client_creds_path)
	    fb_client_creds_path="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --main_platform_url_root)
	    main_platform_url_root="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --services)
	    services="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --redirect_uris)
	    redirect_uris="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --instance_name)
	    instance_name="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --client_type)
	    client_type="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --url_mount_path)
	    url_mount_path="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --mongo_data_dir)
	    mongo_data_dir="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --vedavaapi_data_dir)
	    vedavaapi_data_dir="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --vedavaapi_api_port)
	    vedavaapi_api_port="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --vedavaapi_test_port)
	    vedavaapi_test_port="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    --docker_project_name)
	    docker_project_name="$2"
	    shift # past argument
	    shift # past value
	    ;;
	    *)    # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
	esac
	done
	set -- "${POSITIONAL[@]}" # restore positional parameters

}

check_opts() {

	if [ \( -z "${org_name}" \) -o \( -z "${org_label}" \) -o \( -z "${admin_email}" \) -o \( -z "${admin_password}" \) -o \( -z "${services}" \) -o \( -z "${docker_project_name}" \)  ]; then
		echo "mandatory arguments are not given";
		exit 1
	fi
}

install_dependencies() {
	sudo apt-get -yq install software-properties-common
	sudo apt-add-repository universe
	sudo apt-get -yq  update

	sudo apt-get -yq install python3 python3-requests python3-bcrypt curl git
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	sudo usermod -aG docker $USER
	sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
}

run_pre_setup() {
	python3 pre_setup.py "$@"
}

export_env_vars() {
	export conf_data_dir_path="conf_data";
	export services="${services}"
	export url_mount_path="${url_mount_path}"
	export mongo_data_dir="${mongo_data_dir}"
	export vedavaapi_data_dir="${vedavaapi_data_dir}"
	export vedavaapi_api_port="${vedavaapi_api_port}"
	export vedavaapi_test_port="${vedavaapi_test_port}"
}

setup_volume_dirs() {
	if [ ! -d "${mongo_data_dir}" ]; then
		sudo mkdir -p "${mongo_data_dir}"
	fi
	if [ ! -d "${vedavaapi_data_dir}" ]; then
		sudo mkdir -p "${vedavaapi_data_dir}"
	fi
}

invoke_docker_compose() {
	setup_volume_dirs;
	export_env_vars;
	cp -r "conf_data" "vedavaapi_server_v1/"
	cd "vedavaapi_server_v1/";
	sudo docker-compose -p "${docker_project_name}" up -d --build --no-recreate
}

parse_opts "$@";
check_opts;
if [ ${install_dev_dependencies} == 'true' ]; then
	install_dependencies
fi
run_pre_setup "$@";
invoke_docker_compose;
