#!/bin/bash
#  start from https://www.ubuntu.com/download/server
export DEBIAN_FRONTEND=noninteractive

parse_opts() {
    instance_name="Vedavaapi Mirador Demo"
    client_type="public"
    forward_port="8002"
    docker_project_name="vedavaapiMiradorDemo"
    redirect_uris="";

    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
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
        --main_platform_url_root)
        main_platform_url_root="$2"
        shift # past argument
        shift # past value
        ;;
        --image_analytics_app_url_root)
        image_analytics_app_url_root="$2"
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
        --forward_port)
        forward_port="$2"
        shift # past argument
        shift # past value
        ;;
        --reverse_proxy_path)
        reverse_proxy_path="$2"
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

    if [ \( -z "${admin_email}" \) -o \( -z "${admin_password}" \) -o \( -z "${docker_project_name}" \) -o \( -z "${main_platform_url_root}" \) -o \( -z "${image_analytics_app_url_root}" \)  ]; then
        echo "mandatory arguments are not given";
        exit 1
    fi
}

run_pre_setup() {
    python3 pre_setup.py "$@"
}

export_env_vars() {
    #export conf_data_dir_path="conf_data";
    #export forward_port="${forward_port}"
    echo "COMPOSE_PROJECT_NAME=${docker_project_name}" > "docker_context/.env";
    echo "conf_data_dir_path=conf_data" >> "docker_context/.env";
    echo "forward_port=${forward_port}" >> "docker_context/.env";
}

invoke_docker_compose() {
    export_env_vars;
    cp -r "conf_data" "docker_context/"
    cd "docker_context/";
    # docker-compose -p "${docker_project_name}" up -d --build --no-recreate
    docker-compose up -d --build --no-recreate
}

parse_opts "$@";
check_opts;
run_pre_setup "$@";
invoke_docker_compose;
