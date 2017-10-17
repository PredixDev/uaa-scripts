#!/bin/bash
set -x -v

while getopts ":c:s:r:p:g:a:x:u:i" opt; do
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
	g)
	    # authorized_grant_types default: authorization_code
	    authorized_grant_types=$OPTARG
	    ;;
	a)
	    # authorities default: uaa.resource
	    authorities=$OPTARG	    
	    ;;
	x)
	    # auto approve default: openid
	    autoapprove=$OPTARG	    
	    ;;     
	u)
	    # scope default: openid
	    scope=$OPTARG	    
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

comma=","
IFS=',' read -ra allowed_providers <<< "$idps" 
echo "Allowed Identity Providers: ${allowed_providers[@]}"
for i in "${allowed_providers[@]}"; do
     idp_array="$idp_array\"$i\"$comma"
done
idp_array=$(echo "${idp_array%?}")

# Set authorized_grant_types
if [[ -z "$authorized_grant_types" ]]; then
  authorized_grant_types="authorization_code"
fi
IFS=',' read -ra authorized_grant_types <<< "$authorized_grant_types" 
echo "Authorized Grant Types: ${authorized_grant_types[@]}"
for i in "${authorized_grant_types[@]}"; do
     granttypes_array="$granttypes_array\"$i\"$comma"
done
granttypes_array=$(echo "${granttypes_array%?}")

# Set authorities
if [[ -z "$authorities" ]]; then
  authorities="uaa.resource"
fi
IFS=',' read -ra authorities <<< "$authorities" 
echo "Authorities: ${authorities[@]}"
for i in "${authorities[@]}"; do
     authorities_array="$authorities_array\"$i\"$comma"
done
authorities_array=$(echo "${authorities_array%?}")

# Set scope for the client
if [[ -z "$scope" ]]; then
  scope="openid"
fi
IFS=',' read -ra scope <<< "$scope" 
echo "Scope: ${scope[@]}"
for i in "${scope[@]}"; do
     scope_array="$scope_array\"$i\"$comma"
done
scope_array=$(echo "${scope_array%?}")

# Set auto approve for the client
if [[ -z "$autoapprove" ]]; then
  autoapprove="openid"
fi
IFS=',' read -ra autoapprove <<< "$autoapprove" 
echo "Auto approve: ${autoapprove[@]}"
for i in "${autoapprove[@]}"; do
     autoapprove_array="$autoapprove_array\"$i\"$comma"
done
autoapprove_array=$(echo "${autoapprove_array%?}")

if [[ -z "$redirect_uri" ]]; then
    echo "You must specify a redirect URI with option -r."
    exit 1
fi

payload='{ "client_id" : "'"$client_id"'", "client_secret" : "'"$client_secret"'", "authorized_grant_types" : ['"$granttypes_array"'], "scope" : ['"$scope_array"'], "autoapprove" : ['"$autoapprove_array"'], "authorities":['"$authorities_array"'], "resource_ids":["none"], "redirect_uri":["'$redirect_uri'"], "allowedproviders" : ['"$idp_array"']}'

if [[ -z $skip_ssl ]]; then
    uaac curl -XPUT -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients/$client_id
else
    uaac curl -XPUT -H "Accept: application/json" -H "Content-Type: application/json" -d "$payload" /oauth/clients/$client_id --insecure
fi
