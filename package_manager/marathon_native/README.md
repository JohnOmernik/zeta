# Marathon Native Zeta Install
---
Marathon is the tool to manage long running service on Zeta. This particular package is for the "Master" Marathon that will exist in "production"  All other instances of Marathon should run using "Marathon on Marathon" (Mom) for isolation and multi tenancy. 
The first iterations will be for one Marathon instance per role, but multi-tenant may be possible allowing your mom to service all within a department for example. 

## Package Stats
* Multiple Versions: *False* - One version only
* Multi-Tenant within Role: *False* Only one instance in Prod
* Multiple Roles: *False* Only in prod role. This is the master instance.


## Restrictions:


