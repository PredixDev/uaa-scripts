#!/bin/bash
set -v -x

while getopts ":n:m:t:ad:c:g:" opt; do
    case $opt in
	n)
	    origin_name=$OPTARG
	    ;;
        m)
            saml_metadata_file=$OPTARG
            ;;
        t)
            link_text=$OPTARG
            ;;
        a)
            add_shadow_user_on_login="true"
            ;;
        d)
            idp_id=$OPTARG
            ;;
        c)
            config_mapping_file=$OPTARG
            ;;
	g)
	    groups_mapping_file=$OPTARG
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
    echo "You must specify the origin name with option -n."
    exit 1
fi
echo $origin_name | grep ^.*[\]\^\:\ \?\/\@\#\[\{\}\!\$\&\'\(\)\*\+\,\;\=\~\`\%\|\<\>\"].*$
#A status code of 0 means that there was a special character in the origin name.
if [ $? == 0 ]; then
    echo "Origin name $origin_name contains special characters. Remove the special characters and retry."
    exit 1
fi   

if [[ -z "$saml_metadata_file" ]]; then
    echo "You must specify the idp config file with option -m."
    exit 1
fi

if [[ -z "$idp_id" ]]; then
    echo "You must specify the idp id with option -d."
    exit 1
fi

if [[ -z "$link_text" ]]; then
    link_text="SAML SSO"
fi

if [[ -z "$config_mapping_file" ]]; then
    config_mapping="{}"
else
	config_mapping=$(cat "$config_mapping_file" | col -b)
fi

if [[ -z "$groups_mapping_file" ]]; then
    groups_list="[]"
else
	groups_list=$(cat "$groups_mapping_file" | col -b)
fi

if [[ -z "$add_shadow_user_on_login" ]]; then
    add_shadow_user_on_login="false"
fi

left='{"metaDataLocation":"'
right='","idpEntityAlias":"'"$origin_name"'","nameID":"urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified","assertionConsumerIndex":0,"metadataTrustCheck":false,"showSamlLink":true,"socketFactoryClassName":"org.apache.commons.httpclient.protocol.DefaultProtocolSocketFactory","linkText":"'"$link_text"'","iconUrl":null,"addShadowUserOnLogin":"'"$add_shadow_user_on_login"'","externalGroupsWhitelist":'"$groups_list"',"attributeMappings":'"$config_mapping"'}'


esc_left=$(echo $left | sed 's/"/\\"/g')
esc_right=$(echo $right | sed 's/"/\\"/g')

# dos2unix for stupid OSX that doesn't have dos2unix
esc_middle_0=$(cat "$saml_metadata_file" | col -b)
# Replaces all newlines with \\n
esc_middle_1=$(echo "$esc_middle_0" | awk '$1=$1' ORS='\\\\n')
# Replaces all quotes with \\\"
esc_middle_2=$(echo "$esc_middle_1" | sed 's/"/\\\\\\"/g')

config="$esc_left$esc_middle_2$esc_right"

data='{"originKey":"'"$origin_name"'","name":"'"$origin_name"'","type":"saml","config":"'"$config"'","active":true}'

uaac curl -XPUT -H"Accept:application/json" -H"Content-Type:application/json" /identity-providers/$idp_id -d "$data"
