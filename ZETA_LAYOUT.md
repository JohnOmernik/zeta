# Zeta Layout
---
The goal of Zeta is to pull together technolgies, a lot of them, in a way that people can easily get on board with.  Initially a test/example setup, one potential evolution is a way for the community that share a platform (Zeta) to share packages they've created saving work.

This is a good thing. 

To that end, Zeta is complicated. To help with the initial learning curve, Zeta, as laid out puts somethings into play to help the learning curve. Obviously Zeta can change and evolve to fit your needs, but by making an example starting place, it makes it easier for people to use. 

## Zeta Foundation
---
MapR is the foundational filesystem for Zeta. It's a capable clustered filesystem that provides multiple open API access, strong security, auditing, and a host of other features that prove a strong setup. 

In this setup, MapR-FS is installed on every node, also, every node runs a NFS server that acts as a gateway to the Shared/Clustered Filesystem.  Thus when you name your cluster, say 'zetaaws' every node will have a mount point at /mapr/zetaaws this is your clustered filesystem and is the same data on every node.  

This root is where the layout of Zeta starts. There are 5 main directories to be explained here.  The First is the users directory. Users all get their own home directory volume. It's mounted at /user/%username% (thus from a POSIX perspective on the node, it's at /mapr/$CLUSTERNAME/user/%username%). 

The next four directories all share two main "roles". The goal of this is provide groups (installed as part of the scripts) that can divide each of the following four workloads into "prod" and "dev". Prior to discussing each of the four directories, let me discuss prod and dev in Zeta. 

* prod and dev are basic examples, and correspond to roles in Mesos.
* Each of the four main directories thus have a "prod" and "dev" directory with permissions below the main directory. These are actually volumes in MapR and help to provide FS isolation between roles. 
* There can be "n" levels of roles. While not built into our current scripts, it is on the roadmap for a Zeta setup. Prod, dev, stage, test, etc. All could be roles. We also could have multi-tenant roles. 
* As we learn more and interact more with Mesos, the goal of Zeta will be to use strong filesystem access controls with ACLs/permissions in Mesos to ensure roles have guaranteed resources and can be isolated from other roles workloads. 
* Using labels/attributes in Mesos, we can even isolate certain frameworks for a given to role to specific nodes if needed. We just need a way to automate/lay that out logically. (It's added to the to-do list)
* At this point, the prod/dev just act as way to keep work clean. As you are testing something use dev. When it's time to move move it
* More env scripts/automation will be coming so to handle roles. 

---
### Directories

#### apps
The apps directory is where applications that serve specific purpose live. Say a scraper, or a dashboard. These are not "cluster" applications/frameworks, these business specific applications. These live here. In addition, put any application specifc data here. If the data is shared data, and multiple apps/frameworks can query/access using stadard formats, use /data (below) otherwise use the application's directory under /apps. Example: If an application needs a small mongodb server to save state, but the events it generates are separate from that (for data science work) use /data for the events, and use /apps/(prod|dev)/yourapplicaiton/mongo_db_data  as the location for the files used by mongodb (presumably run in a docker container)

#### data
The data directory is for shared data. This data, while it may be secured, and thus only available to proper roles, should be data that can be read by multiple different tools, spark, drill, hadoop etc. (I.e. using formats like Parquet, CSV, ORC, RC, etc). I also mount maprdb tables to this location. 

#### etl
The etl directory is where one can keep specific jobs for loading data. For example I will keep the chronos json files, the code, Docker files, and raw data used in ETL in the etl locations. 

#### mesos
The mesos directory is where one can keep cluster wide frameworks. These aren't just "applications" that serve a single business purpose, but instead services that make Zeta work. Drill, Kafka, docker registries, spark, etc. These aren't just for one purpose, but are managed by the cluster administrators. 


---
More to come
