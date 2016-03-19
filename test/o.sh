#!/bin/bash

cat > ./acls.json << EOL0
{
  "permissive": false,
  "register_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "roles": { "type": "ANY" }}
  ],
  "run_tasks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "users": { "type": "ANY"}}
  ]
  "shutdown_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] },"framework_principals": { "type": "ANY" }}
  ]
}
EOL0
