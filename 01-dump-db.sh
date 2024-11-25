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
backupdb="${plexdbpath}/com.plexapp.plugins.library.db.original"
workingdb="com.plexapp.plugins.library.db"
USER=$(stat -c '%U' "${currentdb}")
GROUP=$(stat -c '%G' "${currentdb}")
plexdocker="${1}"
echo "perms on db are $USER:$GROUP"
echo "${plexdbpath}"
echo "${plexdocker}"
echo "stopping ${plexdocker}"

docker stop "${plexdocker}"
echo "copying plex app"
docker cp "${plexdocker}":/usr/lib/plexmediaserver/ /opt/plexsql
# cd "$plexdbpath" || exit
echo "backing up current database: ${currentdb}"
cp "${currentdb}" "${backupdb}"
echo "duplicating current database: ${currentdb}"
cp "${currentdb}" .
echo "removing current database: ${currentdb}"
rm -f "${currentdb}"

echo "removing pointless items from database"
"${sqplex}" --sqlite "${workingdb}" "DROP index 'index_title_sort_naturalsort'"
"${sqplex}" --sqlite "${workingdb}" "DELETE from schema_migrations where version='20180501000000'"
"${sqplex}" --sqlite "${workingdb}" "DELETE FROM statistics_bandwidth;"
"${sqplex}" --sqlite "${workingdb}" "DELETE FROM statistics_media;"
"${sqplex}" --sqlite "${workingdb}" "DELETE FROM statistics_resources;"
"${sqplex}" --sqlite "${workingdb}" "DELETE FROM accounts;"
"${sqplex}" --sqlite "${workingdb}" "DELETE FROM devices;"

echo "dumping and removing old database"
"${sqplex}" --sqlite "${workingdb}" .dump > dump.sql

echo "dump.sql is now ready for you to edit; make any required changes then run 02-build-db.sh"

ls -al