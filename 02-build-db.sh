#!/bin/bash
# Original code written by the crew at (redacted) and good to share because `This is the way` https://www.youtube.com/watch?v=1iSz5cuCXdY

sqplex="/opt/plexsql/Plex Media Server"

function usage {
  echo ""
  echo "Usage: pumpandump.sh plex "
  echo ""
  echo "where plex is the name of your plex docker container, plex plex2 plex3"
  exit 1
}

if [ -z "$1" ]; then
  echo "please provide the name of your plex docker container"
  usage
fi
# install JQ if not installed
if hash jq 2> /dev/null; then echo "OK, you have jq installed. We will use that."; else sudo apt install jq -y; fi

dbp1=$(docker inspect "${1}" | jq -r ' .[].HostConfig.Binds[] | select( . | contains("/config:rw"))')
dbp1=${dbp1%%:*}
dbp1=${dbp1#/}
dbp1=${dbp1%/}
dbp2="Library/Application Support/Plex Media Server/Plug-in Support/Databases"
dbpath="${dbp1}/${dbp2}"
plexdbpath="/${dbpath}"
currentdb="${plexdbpath}/com.plexapp.plugins.library.db"
workingdb="com.plexapp.plugins.library.db"
USER=$(stat -c '%U' "${workingdb}")
GROUP=$(stat -c '%G' "${workingdb}")
plexdocker="${1}"

echo "perms on db are $USER:$GROUP"
echo "${plexdbpath}"
echo "${plexdocker}"

rm "${workingdb}"

echo "making adustments to new db"
"${sqplex}" --sqlite "${currentdb}" "pragma page_size=32768; vacuum;"
"${sqplex}" --sqlite "${currentdb}" "pragma default_cache_size = 20000000; vacuum;"
echo "importing old data"
"${sqplex}" --sqlite "${currentdb}" <dump.sql
echo "optimize database and fix times"
"${sqplex}" --sqlite "${currentdb}" "vacuum"
"${sqplex}" --sqlite "${currentdb}" "pragma optimize"
echo "reown to $USER:$GROUP"
sudo chown "$USER:$GROUP" "${plexdbpath}"/*

# Start Applications
echo "start applications"
docker start "${plexdocker}"
