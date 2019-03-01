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
        '--image_analytics_app_url_root', help='url_root of main image analytics application', dest='image_analytics_app_url_root', required=True
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
        client_post_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/clients')
        client_json = {"jsonClass": "OAuth2Client", "name": args.instance_name}

        redirect_uris_str = args.redirect_uris
        if not redirect_uris_str:
            from subprocess import check_output
            ip_addr = re.split(r'[\s]+', unicode_for(check_output(['hostname', '--all-ip-addresses'])))[0].strip()
            if args.forward_port:
                redirect_uris_str = 'http://{}:{}/oauth_callback.html'.format(ip_addr, args.forward_port)
        client_json['redirect_uris'] = redirect_uris_str.split(' ')
        if args.reverse_proxy_path:
            client_json['redirect_uris'].append('{}/oauth_callback.html'.format(args.reverse_proxy_path.rstrip('/')))

        session = requests.Session()

        signin_post_data = {
            "email": args.admin_email,
            "password": args.admin_password
        }
        signin_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/signin')
        signin_resp = session.post(signin_url, data=signin_post_data)
        if signin_resp.status_code !=200:
            signin_resp_json = signin_resp.json()
            print('\n\n signin failure\n', signin_resp_json)
            sys.exit(1)

        client_post_data = {
            "client_json": json.dumps(client_json),
            "client_type": "public",
            "marshal_to_google_structure": "false"
        }
        client_creds_json = session.post(client_post_url, data=client_post_data).json()

        app_config = {}
        app_config['platform_url'] = args.main_platform_url_root
        app_config['image_analytics_app_url'] = args.image_analytics_app_url_root
        app_config['oauth_client'] = {
            'client_id': client_creds_json['client_id'],
            'redirect_uris': client_creds_json['redirect_uris']
        }

        with open('conf_data/config.json', 'wb') as app_config_file:
            app_config_file.write(json.dumps(app_config, indent=2, ensure_ascii=False).encode('utf-8'))


if __name__ == '__main__':
    main(sys.argv[:])

