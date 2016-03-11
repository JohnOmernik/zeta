#!/usr/bin/python

import json
import requests
import sys
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

leaderuri = "http://leader.%s:%s" % (zeta_env['ZETA_MESOS_DOMAIN'], zeta_env['ZETA_MESOS_LEADER_PORT'])

credfile = "/mapr/%s/mesos/kstore/prod/secret/credential.txt" % (zeta_env['ZETA_CLUSTER_NAME'])



# Get the creds
i = open(credfile, "r")
all = i.read()
all = all.strip()
i.close()

lcreds = all.split(" ")
AUTH=(lcreds[0], lcreds[1])

# Check for Valid Parameters
try: 
    frameworkId = sys.argv[1]
except:
    print "Must specify FrameworkId as arguement"
    sys.exit(1)

if frameworkId == "":
    print "Must specify FrameworkId as arguement"
    sys.exit(1)
    
    
# Make Request
payload = {'frameworkId':frameworkId}
r = requests.post(leaderuri + '/master/teardown', auth=AUTH, data=payload)

#Display Results
print r.status_code
print r.reason
print r.text








