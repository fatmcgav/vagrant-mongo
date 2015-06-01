# Testing Mongo with replicaset and authentication

## Needs

- Virtualbox
- Vagrant
- librarian-puppet

## Usage

        librarian-puppet install
        vagrant up

## Configuration

        vagrant ssh primary

- Initialise the replicaset

        $ mongo
        MongoDB shell version: 2.6.9
        connecting to: test
        > rs.initiate()
        {
            "info2" : "no configuration explicitly specified -- making one",
            "me" : "primary:27017",
            "info" : "Config now saved locally.  Should come online in about a minute.",
            "ok" : 1
        }

- Add the secondary node

        rs.add('192.168.33.12:27017')

- Add the arbiter node

        rs.addArb('192.168.33.13:27017')

- Fix DNS resolution issue (change the primary hostname in replica with its IP)

       cfg = rs.conf()
       cfg.members[0].host = "192.168.33.11:27017"
       rs.reconfig(cfg)

- When replicaset is configured

```shell
rsmain:PRIMARY> rs.status()
{
        "set" : "rsmain",
        "date" : ISODate("2015-06-01T22:43:53Z"),
        "myState" : 1,
        "members" : [
                {
                        "_id" : 0,
                        "name" : "192.168.33.11:27017",
                        "health" : 1,
                        "state" : 1,
                        "stateStr" : "PRIMARY",
                        "uptime" : 422,
                        "optime" : Timestamp(1433198623, 1),
                        "optimeDate" : ISODate("2015-06-01T22:43:43Z"),
                        "electionTime" : Timestamp(1433198263, 1),
                        "electionDate" : ISODate("2015-06-01T22:37:43Z"),
                        "self" : true
                },
                {
                        "_id" : 1,
                        "name" : "192.168.33.12:27017",
                        "health" : 1,
                        "state" : 2,
                        "stateStr" : "SECONDARY",
                        "uptime" : 48,
                        "optime" : Timestamp(1433198623, 1),
                        "optimeDate" : ISODate("2015-06-01T22:43:43Z"),
                        "lastHeartbeat" : ISODate("2015-06-01T22:43:53Z"),
                        "lastHeartbeatRecv" : ISODate("2015-06-01T22:43:52Z"),
                        "pingMs" : 1,
                        "syncingTo" : "192.168.33.11:27017"
                },
                {
                        "_id" : 2,
                        "name" : "192.168.33.13:27017",
                        "health" : 1,
                        "state" : 7,
                        "stateStr" : "ARBITER",
                        "uptime" : 10,
                        "lastHeartbeat" : ISODate("2015-06-01T22:43:53Z"),
                        "lastHeartbeatRecv" : ISODate("2015-06-01T22:43:51Z"),
                        "pingMs" : 0
                }
        ],
        "ok" : 1
```

- Run puppet again

        vagrant provision primary
