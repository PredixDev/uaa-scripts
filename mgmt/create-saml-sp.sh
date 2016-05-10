#!/bin/bash
set -v -x

while getopts ":n:m:s:i" opt; do
    case $opt in
    n)
        origin_name=$OPTARG
        ;;
        m)
            saml_metadata_file=$OPTARG
            ;;
        s)
            sp_entity_id=$OPTARG
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

if [[ -z "$origin_name" ]]; then
    echo "You must specify the service provider name with option -n."
    exit 1
fi
if [[ -z "$sp_entity_id" ]]; then
    echo "You must specify the service provider entity id with option -s."
    exit 1
fi
echo $origin_name | grep ^.*[\]\^\:\ \?\/\@\#\[\{\}\!\$\&\'\(\)\*\+\,\;\=\~\`\%\|\<\>\"].*$
#A status code of 0 means that there was a special character in the origin name.
if [ $? == 0 ]; then
    echo "Origin name $origin_name contains special characters. Remove the special characters and retry."
    exit 1
fi   

if [[ -z "$saml_metadata_file" ]]; then
    echo "You must specify the sp config file with option -m."
    exit 1
fi

left='{"metaDataLocation":"'
right='","nameID":"urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified","singleSignOnServiceIndex":0,"metadataTrustCheck":false}'


esc_left=$(echo $left | sed 's/"/\\"/g')
esc_right=$(echo $right | sed 's/"/\\"/g')

# dos2unix for stupid OSX that doesn't have dos2unix
esc_middle_0=$(cat "$saml_metadata_file" | col -b)
# Replaces all newlines with \\n
esc_middle_1=$(echo "$esc_middle_0" | awk '$1=$1' ORS='\\\\n')
# Replaces all quotes with \\\"
esc_middle_2=$(echo "$esc_middle_1" | sed 's/"/\\\\\\"/g')

config="$esc_left$esc_middle_2$esc_right"

data='{"entityId":"'"$sp_entity_id"'","name":"'"$origin_name"'","config":"'"$config"'","active":true}'

if [[ -z $skip_ssl ]]; then
    uaac curl -XPOST -H"Accept:application/json" -H"Content-Type:application/json" /saml/service-providers -d "$data"
else
    uaac curl -XPOST -H"Accept:application/json" -H"Content-Type:application/json" /saml/service-providers -d "$data" --insecure
fi
