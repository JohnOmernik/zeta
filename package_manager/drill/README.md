# Apache Drill Zeta Install
---
Apache Drill is installed via MapR RPMs to ensure compatability with MapR DB.  The current package used is a developer release that is untested/unsupported. (1.6) For more specifc installs, update the get_drill_release.sh to point to supported MapR releases.

## Package Stats
* Multiple Versions: *True*
* Multi-Tenant within Role: *True*
* Multiple Roles: *True*


## Restrictions:
As of now, a constraint for each Tenant's drill bits is setup to only allow one bit, per tenant, per node. As we look to expand the capability of Drill or even develop a Drill Mesos Framework, that could change. 

