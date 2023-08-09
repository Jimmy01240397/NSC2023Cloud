import json
import os
import uuid
import dns.resolver
import re
import flask

import conf

allowips = ["187.187.187.254"]

def help(signtype):
    return f"""
    {signtype.ljust(20, ' ')}sign a web certificate.
                        req: certificate request file for sign
                        Ex: curl {conf.config['ListenHost']}:{conf.config['ListenPort']}/sign/{signtype} -F 'req=@<req file path>'"""
    
def checktype(cn):
    return not json.loads(os.popen(f'openssl x509 -in pki/issued/{cn.lower()}.crt -text | grep -A 1 "Basic Constraints:" | grep "CA" | sed \'s/\s//g\' | awk -F \':\' \'{{print $2}}\'').read().strip().lower())

def sign():
    if flask.request.remote_addr not in allowips:
        return "Invalid IP address.", 403
    reqname = f'/tmp/{str(uuid.uuid4())}.req'
    flask.request.files['req'].save(reqname)
    subject = json.loads('{"' + os.popen(f'openssl req -in {reqname} -text | grep -oP \'(?<=Subject:).*\' | sed \'s/\s*=\s*/\":\"/g\' | sed \'s/,\s*/\",\"/g\'').read().strip() + '"}')
    subaltname = os.popen(f'openssl req -in {reqname} -text | grep -A 1 \'Subject Alternative Name:\' | tail -n 1 | sed \'s/\s//g\'').read().strip().split(',')
    if os.path.isfile(f'pki/issued/{subject["CN"].lower()}.crt'):
        os.remove(reqname)
        return f"Common name: {subject['CN'].lower()} already exist. Please revoke old certificate first.", 403
    os.system(f'easyrsa --batch import-req {reqname} \'{subject["CN"].lower()}\'')
    os.system(f'easyrsa --copy-ext --batch sign-req server \'{subject["CN"].lower()}\'')
    return 'Certificate sign success. Please use "downloadcert" api to download your certificate.'

def revoke(cn):
    if flask.request.remote_addr not in allowips:
        return "Invalid IP address.", 403
    subaltname = os.popen('openssl x509 -in {certpath} -text | grep -A 1 \'Subject Alternative Name:\' | tail -n 1 | sed \'s/\s//g\'').read().strip().split(',')

    os.system(f'easyrsa --batch revoke \'{cn}\'')
    os.system('easyrsa gen-crl')
    return 'Success'

