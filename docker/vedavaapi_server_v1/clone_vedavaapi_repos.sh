declare repo_names=("core_services" "vedavaapi_api" "vv_schemas" "sanskrit_data" "objectdb" "vv_objstore" "iiif" "google_services_helper" "docimage" "image_analytics")
for repo in ${repo_names[@]}; do
	giturl="https://github.com/vedavaapi/${repo}.git"
	git clone ${giturl}
	cd ./${repo}
	git checkout tags/v1.1a1
	#echo "export PYTHONPATH=\"\${PYTHONPATH}:$(pwd)\"" >> ~/.bashrc
	cd -
done
