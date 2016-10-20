#!/bin/bash
set -x -v

while getopts ":c:s:r:p:i" opt; do
    case $opt in
	c)
	    client_id=$OPTARG
	    ;;
	s)
	    client_secret=$OPTARG
	    ;;
        r)
            redirect_uri=$OPTARG
            ;;
        p)
            idps=$OPTARG
            ;;
        i)
            skip_ssl="true"
            ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    exit 1
	    ;;
    esac
done

if [[ -z "$client_id" ]]; then
    echo "You must specify a client id with option -c."
    exit 1
fi

if [[ -z "$client_secret" ]]; then
    echo "You must specify the client secret with option -s."
    exit 1
fi

if [[ -z "$idps" ]]; then
    echo "You must specify the allowed identity providers comma separated list with option -p,"
    echo "And at least one identity provider must be input with option -p."
    exit 1
fi


echo "$idps"

IFS=',' read -ra allowed_providers <<< "$idps"
echo "${allowed_providers[@]}"
comma=","
for i in "${allowed_providers[@]}"; do
    idp_array="$idp_array\"$i\"$comma"
done

idp_array=$(echo "${idp_array%?}")
echo "$idp_array"

if [[ -z "$redirect_uri" ]]; then
    echo "You must specify a redirect URI with option -r."
    exit 1
fi

payload='{ "client_id" : "'"$client_id"'", "client_secret" : "'"$client_secret"'", "authorized_grant_types" : ["authorization_code"], "scope" : ["openid"], "autoapprove":["openid"], "authorities":["uaa.resource"], "resource_ids":["none"], "redirect_uri":["'$redirect_uri'"], "allowedproviders" : ['"$idp_array"']}'

if [[ -z $skip_ssl ]]; then
    uaac curl -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients
else
    uaac curl -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients --insecure
fi
