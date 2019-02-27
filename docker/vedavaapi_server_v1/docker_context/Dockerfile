FROM ubuntu:latest
ARG DEBIAN_FRONTEND=noninteractive

# first install python3, pip3, mongodb, apache
RUN apt-get -yq update;\
		apt-get -yq install unzip wget git;
RUN apt-get -yq install python3 python3-pip
RUN apt-get install -yq apt-utils vim curl apache2 apache2-utils libexpat1 ssl-cert libapache2-mod-wsgi-py3
RUN a2enmod wsgi

# install dependencies
RUN apt-get -yq install python3-requests; \
	pip3 install google-auth-oauthlib google-auth-httplib2 google-api-python-client authlib; \
	apt-get -yq install libjpeg-turbo8-dev libfreetype6-dev zlib1g-dev liblcms2-dev liblcms2-utils libtiff5-dev python-dev libwebp-dev; \
	apt-get -yq install python3-jsonschema python3-jsonpickle python3-bcrypt; \
	pip3 install yurl; \
	apt-get  -yq install libsm6 libxext6 libxrender-dev ; \
	apt-get -yq install python3-numpy python3-scipy python3-matplotlib python3-opencv; \
	pip3 install scikit-image Pillow; \
	apt-get -yq install python3-pymongo; \
	apt-get -yq install python3-flask; \
	pip3 install flask-cors flask-restplus furl flask-oauthlib; \
	pip3 install indic_transliteration; \
	pip3 install configobj mock responses attrs; \
	pip3 install iiif_prezi

# now clone vedavaapi repositories 
ENV INSTALL_DIR /vedavaapi
ENV DATA_DIR /opt/vedavaapi
RUN mkdir -p "$INSTALL_DIR"; \
				mkdir -p "$DATA_DIR";

RUN chown www-data ${INSTALL_DIR}
RUN chown www-data ${DATA_DIR}
USER www-data

WORKDIR $INSTALL_DIR
RUN git clone --depth 1 https://github.com/loris-imageserver/loris.git

# get git repos
ARG vedavaapi_repos_clone_script="clone_vedavaapi_repos.sh"
COPY ${vedavaapi_repos_clone_script} ./
RUN bash ${vedavaapi_repos_clone_script}

ARG conf_data_dir_path
COPY ${conf_data_dir_path} ./conf_data

# generate server config
WORKDIR "$INSTALL_DIR/vedavaapi_api"
ARG mongo_host
ARG mongo_port
ARG url_mount_path
ARG services
RUN python3 genconf.py -i ${DATA_DIR} -o --db_type "mongo" --db_host "mongodb://${mongo_host}:{mongo_port}" --creds_dir "${INSTALL_DIR}/conf_data/creds" -d --host "0.0.0.0" -p 5000 --url_mount_path "${url_mount_path}" --orgs_config_file_path "${INSTALL_DIR}/conf_data/orgs.json"  --services "${services}"

# symlink apache-conf
USER root
ARG wsgi_conf_dir="${DATA_DIR}/conf/_wsgi"
ARG http_conf_file="${wsgi_conf_dir}/apache_conf.conf"
ARG sites_available_dir="/etc/apache2/sites-available"
ARG sa_http_conf_link_path="${sites_available_dir}/vedavaapi_api.conf"
ARG sites_enabled_dir="/etc/apache2/sites-enabled"

# COPY "apache_http.conf" ${http_conf_file}
RUN ln -s ${http_conf_file} ${sa_http_conf_link_path}; \
	ln -s ${sa_http_conf_link_path} "${sites_enabled_dir}/vedavaapi_api.conf"; 

ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
RUN apache2ctl start

EXPOSE 80
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
