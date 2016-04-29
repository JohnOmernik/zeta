# Apache Zeppelin Zeta Install
---
Apache Zeppelin is installed by getting the current snapshot and building from source. To change this, get different packages in get_packages.sh

## Package Stats
* Multiple Versions: *True*
* Multi-Tenant within Role: *True*
* Multiple Roles: *True*


## Restrictions/Notes:
* Big Docker images - We need to see if we can get these smaller. Difficulty: Need all the Mesos prereqs so Zeppelin can submit spark jobs to Mesos
* Large compiled code base: Can we make smaller? 
* Currently each user's instance has it's own copy of the code base, we could find a way to push this down a bit

