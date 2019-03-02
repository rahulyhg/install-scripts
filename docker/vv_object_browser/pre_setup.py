import argparse
import json
import re
import sys
# noinspection PyCompatibility
from urllib.parse import quote_plus

import bcrypt
import os
from shutil import copyfile

import requests

def unicode_for(astring, encoding='utf-8', ensure=False):
    # whether it is py2.7 or py3, or obj is str or unicode or bytes, this method will return unicode string.
    if isinstance(astring, bytes):
        return astring.decode(encoding)
    else:
        if ensure:
            return astring.encode(encoding).decode(encoding)
        else:
            return astring


def sign_session(session, signin_url, email, password, exit_if_error=True):
    signin_post_data = {
        "email": email,
        "password": password
    }
    signin_resp = session.post(signin_url, data=signin_post_data)
    if signin_resp.status_code !=200:
            signin_resp_json = signin_resp.json()
            print('\n\n signin failure\n', signin_resp_json)
            sys.exit(1)
    return signin_resp.json()

def create_client(signed_session, client_post_url, client_name, client_type, redirect_uris, marshal_to_google_structure="false"):
    client_json = {"jsonClass": "OAuth2Client", "name": client_name, "redirect_uris": redirect_uris}
    client_post_data = {
        "client_json": json.dumps(client_json),
        "client_type": client_type,
        "marshal_to_google_structure": marshal_to_google_structure
    }
    client_creds_json = signed_session.post(client_post_url, data=client_post_data).json()
    return client_creds_json


def get_administrative_token(client_json, token_uri):
    token_post_data = {
        "client_id": client_json['client_id'],
        "client_secret": client_json['client_secret'],
        "grant_type": "client_credentials",
    }
    token_response = requests.post(token_uri, data=token_post_data)
    return token_response.json()

def register_with_registry(registry_url, access_token, service_name, url_root, description=None):
    headers = {
        "Authorization": "Bearer {}".format(access_token)
    }
    service = {
        "jsonClass": "VedavaapiService",
        "service_name": service_name,
        "url_root": url_root,
        "description": description
    }
    for k in service:
        if service[k] is None:
            service.pop(k)
    post_data = {
        "service_json": json.dumps(service),
        "return_projection": json.dumps({"permissions": 0})
    }
    resp = requests.post(registry_url, data=post_data, headers=headers)
    return resp.json()


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--admin_email', help='platform root_admin_email', dest='admin_email', required=True
    )
    parser.add_argument(
        '--admin_password', help='platform root admin password', dest='admin_password', required=True
    )
    parser.add_argument(
        '--main_platform_url_root', help='url_root of main platform installation', dest='main_platform_url_root', required=True
    )
    parser.add_argument(
        '--instance_name', help='a symbolic name for this instance', dest='instance_name', default='Vedavaapi Object Browser'
    )
    parser.add_argument(
        '--redirect_uris', help='redirect_uris seperated by space', dest='redirect_uris', required=False, default=''
    )
    parser.add_argument(
        '--forward_port', help='port to be forwarded', dest='forward_port', required=False, default=None
    )
    parser.add_argument(
        '--reverse_proxy_path', help='reverse proxy path', dest='reverse_proxy_path', required=False, default=None
    )

    args, unknown = parser.parse_known_args()

    os.makedirs('conf_data', exist_ok=True)

    if args.main_platform_url_root:
        args.main_platform_url_root = args.main_platform_url_root.rstrip('/')

        session = requests.Session()
        signin_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/signin') 
        sign_session(session, signin_url, args.admin_email, args.admin_password)

        client_post_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/clients')

        redirect_uris_str = args.redirect_uris
        redirect_uris = []
        if not redirect_uris_str:
            from subprocess import check_output
            ip_addr = re.split(r'[\s]+', unicode_for(check_output(['hostname', '--all-ip-addresses'])))[0].strip()
            if args.forward_port:
                redirect_uris_str = 'http://{}:{}/oauth_callback.html'.format(ip_addr, args.forward_port)
        redirect_uris = redirect_uris_str.split(' ')
        if args.reverse_proxy_path:
            redirect_uris.append('{}/oauth_callback.html'.format(args.reverse_proxy_path.rstrip('/')))

        client_creds_json = create_client(session, client_post_url, args.instance_name, 'public', redirect_uris)

        app_config = {}
        app_config['platform_url'] = args.main_platform_url_root
        app_config['oauth_client'] = {
            'client_id': client_creds_json['client_id'],
            'redirect_uris': client_creds_json['redirect_uris']
        }

        with open('conf_data/config.json', 'wb') as app_config_file:
            app_config_file.write(json.dumps(app_config, indent=2, ensure_ascii=False).encode('utf-8'))

        administrative_creds_json = create_client(session, client_post_url, args.instance_name, 'private', redirect_uris)
        administrative_creds_json.pop('permissions', None)
        with open('conf_data/administrative_client_creds.json', 'wb') as admin_client_creds_file:
            admin_client_creds_file.write(json.dumps(administrative_creds_json, indent=2, ensure_ascii=False).encode('utf-8'))

        token_uri = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/token')
        access_token_response_json = get_administrative_token(administrative_creds_json, token_uri)
        registry_url = os.path.join(args.main_platform_url_root, 'registry/v1/services')
        registered_service_json = register_with_registry(registry_url, access_token_response_json['access_token'], 'vv_object_browser', os.path.join(args.reverse_proxy_path, 'collection_test.html'), description="vedavaapi object browser")
        with open('conf_data/registered_service.json', 'wb') as registered_service_file:
            registered_service_file.write(json.dumps(registered_service_json, indent=2, ensure_ascii=False).encode('utf-8'))

if __name__ == '__main__':
    main(sys.argv[:])

