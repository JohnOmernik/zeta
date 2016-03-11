#!/usr/bin/python
import requests
import json
import sys
import os
import subprocess

clustername = subprocess.check_output(['ls', '/mapr']).strip()
mesos_role = "prod"
envfile = '/mapr/%s/mesos/kstore/env/zeta_%s_%s.sh' % (clustername, clustername, mesos_role)
zeta_env = subprocess.check_output([envfile, '1'])
zeta = {}
for i in  zeta_env.split("\n"):
    if i != "":
        o = i.split("=")
        zeta[o[0]] = o[1]


base_url = "https://%s:%s" % (zeta['ZETA_DRILL_WEB_HOST'], zeta['ZETA_DRILL_WEB_PORT'])


def main():
    headers = {"Content-type": "application/json"}

    workspace_exclude = ['hive', 'root', 'mapr', 'zetaadm']

    user_name = ""
    password = ""

    s = authDrill(user_name, password)        # Authenticate to Drill This returns a session that is used to run queries then 

    changed = False
    home = s.get(base_url + '/storage/home.json', verify=False)
    if home.status_code == 200:
        jhome = home.json()
  #      print jhome
  #      print json.dumps(jhome)
    u = os.listdir(zetaenv['ZETA_NFS_ROOT'] + "/user")
#    print u

    for user in u:
        if user not in workspace_exclude:
            if user not in jhome['config']['workspaces']:
                print "User Home: %s not in Drill Home Workspaces" % user
                jhome['config']['workspaces'][user] = {"writable": True, "location": "/user/" + user, "defaultInputFormat": None}
                changed = True
            else:
                print "User Home: %s found in Drill Home Workspaces" % user
 #   print jhome
 #   print json.dumps(jhome)
    if changed == True:
        print "Updating"
        r = s.post(base_url + "/storage/home.json", data=json.dumps(jhome), headers=headers, verify=False)
        print r.status_code
        print r.text
    else:
        print "No changes"

def runQuery(s, drill):
    url = base_url + "/query.json"
    payload = {"queryType":"SQL", "query":drill}
    headers = {"Content-type": "application/json"}
    
    r = s.post(url, data=json.dumps(payload), headers=headers, verify=False)

    return r


def authDrill(un, pw):

    s = requests.Session() # Create a session object
    url = base_url + "/j_security_check"

    user = un
    passwd = pw

    login = {'j_username': user, 'j_password': passwd}
   
    r = s.post(url, data=login, verify=False)

    if r.status_code == 200:
        if r.text.find("Invalid username/password credentials") >= 0:
            print "Authentication Failed - Please check Secrets - Exiting"
            sys.exit(1)
        elif r.text.find("Number of Drill Bits") >= 0:
            print "Authentication successful"
        else:
            print "Unknown Response Code 200 - Exiting"
            print r.text
            sys.exit(1)
    else:
        print "Non HTTP-200 returned - Unknown Error - Exiting"
        print "HTTP Code: %s" % r.status_code
        print r.text
        sys.exit(1)

    return s
    




if __name__ == '__main__':
    main()
