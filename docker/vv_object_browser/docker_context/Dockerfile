FROM ubuntu:latest
ARG DEBIAN_FRONTEND=noninteractive


RUN apt-get -yq update;\
		apt-get -yq install unzip wget vim apache2 apache2-utils
RUN apt-get -yq install git

WORKDIR /var/www/html
RUN git clone "https://github.com/vedavaapi/vv_object_browser.git"
ARG conf_data_dir_path
COPY ${conf_data_dir_path} ./conf_data
RUN cp "conf_data/config.json" "/var/www/html/vv_object_browser/assets/config.json"

ARG sites_available_dir="/etc/apache2/sites-available"
ARG sa_http_conf_link_path="${sites_available_dir}/vv_object_store.conf"
ARG sites_enabled_dir="/etc/apache2/sites-enabled"

COPY ./apache_conf.conf "${sa_http_conf_link_path}"
RUN ln -s ${sa_http_conf_link_path} "${sites_enabled_dir}/vv_object_store.conf"; 

ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
RUN apache2ctl start

EXPOSE 80
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]

