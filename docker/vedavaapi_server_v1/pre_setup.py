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


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--org_name', help='org name. defaults to vedavaapi', default='vedavaapi', dest='org_name', required=True
    )
    parser.add_argument(
        '--org_label', help='organization label', dest='org_label', required=True
    )
    parser.add_argument(
        '--admin_email', help='platform root_admin_email', dest='admin_email', required=True
    )
    parser.add_argument(
        '--admin_password', help='platform root admin password', dest='admin_password', required=True
    )
    parser.add_argument(
        '--google_client_creds_path', help='google credentials file path', dest='google_client_creds_path', default=None
    )
    parser.add_argument(
        '--fb_client_creds_path', help='facebook client credentials file path', dest='fb_client_creds_path', default=None
    )
    parser.add_argument(
        '--main_platform_url_root', help='url_root of main platform installation', dest='main_platform_url_root', default=None
    )
    parser.add_argument(
        '--services', help='space seperated list of services to be launched', dest='services', required=True
    )
    parser.add_argument(
        '--instance_name', help='a symbolic name for this instance', dest='instance_name', default='Vedavaapi Platform Application'
    )
    parser.add_argument(
        '--redirect_uris', help='redirect_uris seperated by space', dest='redirect_uris', required=False, default=''
    )
    parser.add_argument('--client_type', help='type of client public or private', dest='client_type', default='private')

    args, unknown = parser.parse_known_args()
    if not re.match(r'^[a-z_0-9]*$', args.org_name):
        print('invalid org_name')
        sys.exit(1)

    os.makedirs('conf_data/creds/oauth', exist_ok=True)
    if args.google_client_creds_path:
        os.makedirs('conf_data/creds/oauth/google', exist_ok=True)
        try:
            copyfile(args.google_client_creds_path, 'conf_data/creds/oauth/google/default.json')
        except Exception as e:
            print('error in copying google creds file', e)
    if args.fb_client_creds_path:
        os.makedirs('conf_data/creds/oauth/facebook', exist_ok=True)
        try:
            copyfile(args.fb_client_creds_path, 'conf_data/creds/oauth/facebook/default.json')
        except Exception as e:
            print('error in copying facebook creds file', e)


    org_config = {
        "label": args.org_label,
        "root_admin": {
            "email": args.admin_email,
            "hashedPassword": bcrypt.hashpw(args.admin_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        },
        "db_type": "mongo",
        "db_host": "mongodb://vedavaapi_mongo:27017",
        "db_prefix": args.org_name,
        "file_store_base_path": args.org_name
    }

    orgs_config = {
        args.org_name: org_config
    }

    with open('conf_data/orgs.json', 'wb') as orgs_file:
        orgs_file.write(json.dumps(orgs_config, indent=2, ensure_ascii=False).encode('utf-8'))

    if args.main_platform_url_root:
        client_post_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/clients')
        client_json = {"jsonClass": "OAuth2Client", "name": args.instance_name}
        client_json['redirect_uris'] = (args.redirect_uris or '').split(' ')

        session = requests.Session()

        signin_post_data = {
            "email": args.admin_email,
            "password": args.admin_password
        }
        signin_url = os.path.join(args.main_platform_url_root, 'accounts/oauth/v1/signin')
        session.post(signin_url, data=signin_post_data)

        client_post_data = {
            "client_json": json.dumps(client_json),
            "client_type": args.client_type,
            "marshal_to_google_structure": "true"
        }
        client_creds_json = session.post(client_post_url, data=client_post_data).json()

        os.makedirs('conf_data/creds/oauth/{}/'.format(quote_plus(args.main_platform_url_root)), exist_ok=True)

        with open('conf_data/creds/oauth/{}/default.json'.format(quote_plus(args.main_platform_url_root)), 'wb') as platform_creds_file:
            platform_creds_file.write(json.dumps(client_creds_json).encode('utf-8'))


if __name__ == '__main__':
    main(sys.argv[:])

