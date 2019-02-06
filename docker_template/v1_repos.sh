declare repo_names=("core_services" "vedavaapi_api" "sanskrit_ld" "objectdb" "ullekhanam" "iiif" "google_services_helper" "docimage")
for repo in ${repo_names[@]}; do
	giturl="https://github.com/vedavaapi/${repo}.git"
	git clone ${giturl}
	cd ./${repo}
	git checkout tags/v1.0
	echo "export PYTHONPATH=\"\${PYTHONPATH}:$(pwd)\"" >> ~/.bashrc
	cd -
done
