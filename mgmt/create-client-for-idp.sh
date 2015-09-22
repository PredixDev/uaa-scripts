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
            idp=$OPTARG
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

if [[ -z "$idp" ]]; then
    echo "You must specify the identity provider with option -p."
    exit 1
fi

if [[ -z "$redirect_uri" ]]; then
    echo "You must specify a redirect URI with option -r."
    exit 1
fi

payload='{ "client_id" : "'"$client_id"'", "client_secret" : "'"$client_secret"'", "authorized_grant_types" : ["authorization_code"], "scope" : ["openid"], "autoapprove":["openid"], "authorities":["uaa.resource"], "resource_ids":["none"], "redirect_uri":["'$redirect_uri'"], "allowedproviders" : ["'"$idp"'"]}'

if [[ -z $skip_ssl ]]; then
    uaac curl -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients
else
    uaac curl -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients --insecure
fi
