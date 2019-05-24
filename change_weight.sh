#!/usr/bin/env bash

set -e # bail out early if any command fails
# set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails

if [ -z "$1" ]
  then
    echo "No argument supplied, you need to pass the name of the route/host"
    echo "You can get names by issuing cf routes and looking at the host column."
    echo ""
    echo "change_weight.sh <host> <app name> <weight>"
    exit 1
fi
if [ -z "$2" ]
  then
    echo "No argument supplied, you need to pass the weight"
    echo ""
    echo "change_weight.sh <host> <app name> <weight>"
    exit 1
fi
if [ -z "$3" ]
  then
    echo "No argument supplied, you need to pass the weight"
    echo ""
    echo "change_weight.sh <host> <app name> <weight>"
    exit 1
fi

routeName=${1}
appName=${2}
weight=${3}


appGuid=$(cf app ${appName} --guid)
routeGuid=$(cf curl "/v2/routes?q=host:${routeName}" | jq -r '.resources[].metadata.guid')
routeMappings=$(cf curl /v2/routes/${routeGuid}/route_mappings | jq -r -c '.resources[]')

post_data()
{
  cat <<EOF
{"weight": ${weight}}
EOF
}

for mapping in ${routeMappings}
do
    appRouteMappingGuid=$(echo ${mapping} | jq -r '.metadata.guid')
    appGuidMapping=$(echo ${mapping} | jq -r '.entity.app_guid')

    if [[ "${appGuidMapping}" == "${appGuid}" ]]
    then
        cf curl /v3/route_mappings/${appRouteMappingGuid} -X PATCH -d "$(post_data)"
    fi
done



