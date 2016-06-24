#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-
#
# provision-4mv4d-field-filtering-demo.sh
#
# A bash script for importing an API Proxy, then provisioning two API Products, a
# developer, and two developer apps in an organization in the Apigee Edge cloud, to
# support the Field filtering demonstration. This script also modifies the
# accompanying postman collection to allow invoking the APIs. 
#
# Last saved: <2016-June-23 21:38:59>
#

verbosity=2
netrccreds=0
apiproxyname="4mv4d-field-filtering-demo"
apiproxydir="./bundle"
apiproxyzip=""
envname="test"
apiproductnamebase="4mv4d-Field-Filtering-Product"
product_custom_attrs=(
    "filter_fields:city.name,city.state,airports.code,airports.name|filter_action:include"
    "filter_fields:city,airports.country,airports.city_code|filter_action:exclude"
)

client_custom_attrs=(
    "filter_fields:city.name,city.state,airports.location,airports.code,airports.aircraft_movements|filter_action:include"
    "filter_fields:city,airports.location|filter_action:exclude"
)

apiproductname=""
apikeys=()
developername="Lois Lane"
developeremail=""
appnamebase="4mv4d-Field-Filtering-App"
appname=""
appnames=()
defaultmgmtserver="https://api.enterprise.apigee.com"
postmancollection="1-Field-Filtering.postman.json"
credentials=""
TAB=$'\t'


function usage() {
  local CMD=`basename $0`
  echo "$CMD: "
  echo "  Creates two API Products, a Developer, and two developer apps enabled on those"
  echo "  products. Emits the client_id (aka APIKey) for each of the apps."
  echo "  Uses the curl utility."
  echo "usage: "
  echo "  $CMD [options] "
  echo "options: "
  echo "  -o org    the org to use."
  echo "  -e env    the environment to enable API Products on."
  echo "  -u user   Edge admin user for the Admin API calls. You will be prompted for pwd."
  echo "  -n        use .netrc to retrieve credentials (in lieu of -u)"
  echo "  -m url    the base url for the mgmt server."
  echo "  -d dir    directory containing the apiproxy bundle to use. default is ${apiproxydir} "
  echo "  -q        quiet; decrease verbosity by 1"
  echo "  -v        verbose; increase verbosity by 1"
  echo
  echo "Current parameter values:"
  echo "  mgmt api url: $defaultmgmtserver"
  echo "     verbosity: $verbosity"
  echo "   environment: $envname"
  echo
  exit 1
}

## function MYCURL
## Print the curl command, omitting sensitive parameters, then run it.
## There are side effects:
## 1. puts curl output into file named ${CURL_OUT}. If the CURL_OUT
##    env var is not set prior to calling this function, it is created
##    and the name of a tmp file in /tmp is placed there.
## 2. puts curl http_status into variable CURL_RC
function MYCURL() {
  [ -z "${CURL_OUT}" ] && CURL_OUT=`mktemp /tmp/apigee-edge-provision-demo-org.curl.out.XXXXXX`
  [ -f "${CURL_OUT}" ] && rm ${CURL_OUT}
  [ $verbosity -gt 0 ] && echo "curl $@"

  # run the curl command
  CURL_RC=`curl $credentials -s -w "%{http_code}" -o "${CURL_OUT}" "$@"`
  [ $verbosity -gt 0 ] && echo "==> ${CURL_RC}"
}

function CleanUp() {
    [ -f ${CURL_OUT} ] && rm -rf ${CURL_OUT}
    [ -f ${apiproxyzip} ] && rm -rf ${apiproxyzip}
}

function echoerror() { echo "$@" 1>&2; }

function choose_mgmtserver() {
  local name
  echo
  read -p "  Which mgmt server (${defaultmgmtserver}) :: " name
  name="${name:-$defaultmgmtserver}"
  mgmtserver=$name
  echo "  mgmt server = ${mgmtserver}"
}

function choose_credentials() {
  local username password
  read -p "username for Edge org ${orgname} at ${mgmtserver} ? (blank to use .netrc): " username
  echo
  if [[ "$username" = "" ]] ; then  
    credentials="-n"
  else
    echo -n "Org Admin Password: "
    read -s password
    echo
    credentials="-u ${username}:${password}"
  fi
}

function maybe_ask_password() {
  local password
  if [[ ${credentials} =~ ":" ]]; then
    credentials="-u ${credentials}"
  else
    echo -n "password for ${credentials}?: "
    read -s password
    echo
    credentials="-u ${credentials}:${password}"
  fi
}

function check_org() {
  echo "  checking org ${orgname}..."
  MYCURL -X GET  ${mgmtserver}/v1/o/${orgname}
  if [ ${CURL_RC} -eq 200 ]; then
    check_org=0
  else
    check_org=1
  fi
}

function check_env() {
  echo "  checking environment ${envname}..."
  MYCURL -X GET  ${mgmtserver}/v1/o/${orgname}/e/${envname}
  if [ ${CURL_RC} -eq 200 ]; then
    check_env=0
  else
    check_env=1
  fi
}

function random_string() {
  local rand_string
  rand_string=$(cat /dev/urandom |  LC_CTYPE=C  tr -cd '[:alnum:]' | head -c 10)
  echo ${rand_string}
}

function produce_and_maybe_show_zip() {
  local curdir zipout 
  apiproxyzip="/tmp/${apiproxyname}.zip"
  
  if [ -f ${apiproxyzip} ]; then
    if [ $verbosity -gt 0 ]; then
      echo "removing the existing zip..."
    fi
    rm -rf ${apiproxyzip}
  fi
  if [ $verbosity -gt 0 ]; then
    echo "Creating the zip..."
  fi

  curdir=`pwd`
  cd "$apiproxydir"

  if [ ! -d apiproxy ]; then
    echo "Error: there is no apiproxy directory in "
    pwd
    echo
    exit 1
  fi

  zipout=`zip -r "${apiproxyzip}" apiproxy  -x "*/*.*~" -x "*/.tern-port" -x "*/Icon*" -x "*/#*.*#"`
  cd "$curdir"

  if [ $verbosity -gt 1 ]; then
    #echo $zipout
    unzip -l "${apiproxyzip}"
    echo
  fi
}

function import_and_deploy_proxy() {
    local rev
    produce_and_maybe_show_zip
    
    # import the proxy bundle (zip)
    if [ $verbosity -gt 0 ]; then
      echo "Importing the bundle as $apiproxyname..."
    fi
    MYCURL -X POST "${mgmtserver}/v1/o/${orgname}/apis?action=import&name=$apiproxyname" -T ${apiproxyzip} -H "Content-Type: application/octet-stream"
    [ $verbosity -gt 1 ] && cat ${CURL_OUT} && echo && echo

    if [ ${CURL_RC} -ne 201 ]; then
      echo
      if [ $verbosity -le 1 ]; then
        cat ${CURL_OUT}
        echo
      fi
      echo "There was an error importing that API bundle..."
      echo
      Cleanup
      exit 1
    fi

    ## what revision did we just import?
    rev=`cat ${CURL_OUT} | grep \"revision\" | tr '\r\n' ' ' | sed -E 's/"revision"|[:, "]//g'`
    echo This is revision $rev

    # deploy (with override) will implicitly undeploy any existing deployed revisions
    MYCURL -X POST -H content-type:application/x-www-form-urlencoded \
        "${mgmtserver}/v1/o/${orgname}/e/${envname}/apis/${apiproxyname}/revisions/${rev}/deployments" \
        -d "override=true&delay=60"

    if [[ ! ${CURL_RC} =~ 200 ]]; then
        echo
        echo "There was an error deploying revision $rev of $apiproxyname."
        cat ${CURL_OUT} 1>&2;
        echo
        exit
    fi
    [ -f ${apiproxyzip} ] && rm -rf ${apiproxyzip}
}


function create_new_developer() {
    local names=($developername)
    local firstname=${names[0]}
    local lastname=${names[1]}
    developeremail="${firstname}@example.com" 
    MYCURL -X GET ${mgmtserver}/v1/o/${orgname}/developers/${developeremail}
    if [ ${CURL_RC} -eq 404 ]; then
        echo  "  create a new developer (${developername} / ${developeremail})..."
        MYCURL -X POST \
               -H "Content-type:application/json" \
               ${mgmtserver}/v1/o/${orgname}/developers \
               -d '{
    "email" : "'${developeremail}'",
    "firstName" : "'${firstname}'",
    "lastName" : "'${lastname}'",
    "userName" : "'${firstname}'",
    "organizationName" : "'${orgname}'",
    "status" : "active"
  }'
        if [ ${CURL_RC} -ne 201 ]; then
            echo
            echoerror "  failed creating a new developer."
            cat ${CURL_OUT}
            echo
            echo
            exit 1
        fi
        
    elif [ ${CURL_RC} -eq 200 ]; then
        echo "  the required developer already exists"
        echo
    else 
        echo
        echo "  failed querying that product." 1>&2
        cat ${CURL_OUT} 1>&2
        echo
        echo
        CleanUp
        exit 1
    fi
}


function separate_attrs() {
    local item=$1
    attrs=()
    attrs+=(`expr "$item" : '\([^\|]*\)'`)
    attrs+=(`expr "$item" : '[^\|]+\|\([^\|]*\)'`)
}

function extract_name_and_value() {
  local item=$1
  ## split the elements from the chosen app
  name=`expr "$item" : '\([^:]*\)'`
  value=`expr "$item" : '[^:]*:\([^:]*\)'`
}

function get_elaborated_attrstring() {
    local startingstring="$1" attrs pair i 
    attrlist=""
    if [[ ! -z "$startingstring" ]]; then
        attrs=(${startingstring//|/ })
        for i in "${!attrs[@]}"; do
            attr=${attrs[i]}
            pair=(${attr//:/ })
            if [[ ! -z "$attrlist" ]]; then
                attrlist+=","
            fi 
            attrlist+=$'\n    {"name":"'${pair[0]}$'","value":"'${pair[1]}$'"}'
        done
    fi 
}

function create_new_api_product() {
    local attrlist attrs_this_product ix=$1 attr_string=$2
    apiproductname="${apiproductnamebase}${ix}"
    MYCURL -X GET ${mgmtserver}/v1/o/${orgname}/apiproducts/${apiproductname}

    if [ ${CURL_RC} -eq 404 ]; then
        echo "create new API Product..."
        get_elaborated_attrstring "$attr_string"
        payload=$'{\n'
        payload+=$'  "name" : "'${apiproductname}$'",\n'
        payload+=$'  "displayName" : "'${apiproductname}$'",\n'
        payload+=$'  "attributes" : [ '$attrlist$'\n  ],\n'
        payload+=$'  "description" : "Demo product for '${apiproxyname}$'",\n'
        payload+=$'  "environments": [ "'${envname}$'" ],\n'
        payload+=$'  "proxies": [ "'${apiproxyname}$'" ],\n'
        payload+=$'  "apiResources" : [ "/**" ],\n'
        if [ $ix -eq 98 ]; then
            payload+=$'  "approvalType" : "manual",\n'
        else
            payload+=$'  "approvalType" : "auto",\n'
        fi
        payload+=$'  "scopes" : []\n}'
        MYCURL -H "Content-Type:application/json" \
               -X POST ${mgmtserver}/v1/o/${orgname}/apiproducts -d "${payload}"
        
        if [ ${CURL_RC} -ne 201 ]; then
            echo
            echo "  failed creating that product." 1>&2
            cat ${CURL_OUT} 1>&2
            echo
            echo
            CleanUp
            exit 1
        fi
        
    elif [ ${CURL_RC} -eq 200 ]; then
        echo "  the required product already exists"
        echo
    else 
        echo
        echo "  failed querying that product." 1>&2
        cat ${CURL_OUT} 1>&2
        echo
        echo
        CleanUp
        exit 1
    fi
}


function create_new_developer_app() {
    local payload keyexpiry ix=$1 attr_string=$2
    appname="${appnamebase}${ix}"
    apiproductname="${apiproductnamebase}${ix}"
    MYCURL -X GET "${mgmtserver}/v1/o/${orgname}/developers/${developeremail}/apps/${appname}"
    if [ ${CURL_RC} -eq 404 ]; then
        echo "create new App..."
        get_elaborated_attrstring "$attr_string"
        payload=$'{\n'
        payload+=$'  "name" : "'${appname}$'",\n' 
        payload+=$'  "attributes" : [ '$attrlist$'\n  ],\n'
        if [ $ix -eq 99 ]; then
            # make an app that does not have authorization on any product (works for all products),
            # but expires in 45 seconds. 
            keyexpiry=45000
            payload+=$'  "keyExpiresIn" : '${keyexpiry}$',\n'
            payload+=$'  "apiProducts": [ ],\n'
        else
            payload+=$'  "apiProducts": [ "'${apiproductname}$'" ],\n'
        fi
        payload+=$'  "callbackUrl" : "thisisnotused://www.apigee.com"\n}'

        MYCURL -X POST \
               -H "Content-type:application/json" \
               ${mgmtserver}/v1/o/${orgname}/developers/${developeremail}/apps \
               -d "${payload}"

        if [ ${CURL_RC} -ne 201 ]; then
            echo
            echo "  failed creating a new app." 1>&2
            cat ${CURL_OUT} 1>&2
            echo
            echo
            CleanUp
            exit 1
        fi
        retrieve_app_keys
        
    elif [ ${CURL_RC} -eq 200 ]; then
        echo "  the required app already exists."
        echo
        retrieve_app_keys
        
    else 
        echo
        echo "  failed querying that app." 1>&2
        cat ${CURL_OUT} 1>&2
        echo
        echo
        CleanUp
        exit 1
    fi
}


function retrieve_app_keys() {
  local array consumerkey
  MYCURL -X GET ${mgmtserver}/v1/o/${orgname}/developers/${developeremail}/apps/${appname} 
  if [ ${CURL_RC} -ne 200 ]; then
    echo
    echoerror "  failed retrieving the app details."
    cat ${CURL_OUT} 1>&2
    echo
    echo
    exit 1
  fi
  
  # add it to the list of apps
  appnames+=("${appname}")

  array=(`cat ${CURL_OUT} | grep "consumerKey" | sed -E 's/[",:]//g'`)
  consumerkey=${array[1]}
  
  # add it to the list of known apikeys
  apikeys+=("${consumerkey}")
}


function report_out() {
    echo
    echo "Here are the names and apikeys for the newly-created apps:"
    local ix
    echo
    for ix in "${!appnames[@]}"; do
        printf "  %-28s  %s\n" "${appnames[ix]}" "${apikeys[ix]}"
    done
    echo
}


function modify_postman_collection() {
    local DATE=$(date +"%Y%m%d%H%M")
    local outputfile="4mv4d-field-filtering-demo-${DATE}.postman_collection"
    local newuuid=`uuid`
    if [ ! -f ${postmancollection} ]; then
        echo "No postman collection template found."
        echo 
    else
        [ -f ${outputfile} ] && rm -rf ${outputfile}

        sed -e 's/NAME_GOES_HERE/1-4mv4d-Field-Filtering/' "${postmancollection}" > ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/ORGNAME/${orgname}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/ENVNAME/${envname}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/APIKEY1/${apikeys[0]}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/APIKEY2/${apikeys[1]}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/APIKEY3/${apikeys[2]}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/APIKEY4/${apikeys[3]}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/COLLECTION_ID/${newuuid}/g" ${outputfile}

        [ -f ${outputfile} ] && [ -f ${outputfile}.tmp ] && rm -fr ${outputfile}.tmp

        if [ -f ${outputfile} ]; then
            echo "import this into postman:  ${outputfile}"
            echo
        else
            echo "Cannot produce modified postman collection.??"
            echo 
        fi
    fi
}

function uuid() {
    local N B C='89ab'
    for (( N=0; N < 16; ++N )); do
        B=$(( $RANDOM%256 ))
        case $N in
            6) printf '4%x' $(( B%16 )) ;;
            8) printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 )) ;;
            3 | 5 | 7 | 9) printf '%02x-' $B ;;
            *) printf '%02x' $B ;;
        esac
    done
    echo
}


## =======================================================

echo
echo "This script imports an API Proxy, then creates a Developer, two API Products, and four developer apps,"
echo "all but one of which are enabled on that API product. Emits the client id for each app. Then produces"
echo "a postman collection which will use those values."
echo "=============================================================================="

while getopts "ho:e:u:nm:d:qv" opt; do
  case $opt in
    h) usage ;;
    m) mgmtserver=$OPTARG ;;
    o) orgname=$OPTARG ;;
    e) envname=$OPTARG ;;
    u) credentials=$OPTARG ;;
    n) netrccreds=1 ;;
    d) apiproxydir=$OPTARG ;;
    q) verbosity=$(($verbosity-1)) ;;
    v) verbosity=$(($verbosity+1)) ;;
    *) echo "unknown arg" && usage ;;
  esac
done

echo
if [ "X$mgmtserver" = "X" ]; then
  mgmtserver="$defaultmgmtserver"
fi 

if [ "X$orgname" = "X" ]; then
    echo "You must specify an org name (-o)."
    echo
    usage
    exit 1
fi

if [ "X$envname" = "X" ]; then
    echo "You must specify an environment name (-e)."
    echo
    usage
    exit 1
fi

if [ "X$credentials" = "X" ]; then
  if [ ${netrccreds} -eq 1 ]; then
    credentials='-n'
  else
    choose_credentials
  fi 
else
  maybe_ask_password
fi 

check_org 
if [ ${check_org} -ne 0 ]; then
  echo "that org cannot be validated"
  CleanUp
  exit 1
fi

check_env
if [ ${check_env} -ne 0 ]; then
  echo "that environment cannot be validated"
  CleanUp
  exit 1
fi


import_and_deploy_proxy
create_new_developer

for ix in "${!product_custom_attrs[@]}"; do
  create_new_api_product $((ix+1)) "${product_custom_attrs[ix]}"
  create_new_developer_app $((ix+1)) "${client_custom_attrs[ix]}"
done

# this product will have no proxies in it
create_new_api_product 98

# this app will be authorized for Product98, have no access
create_new_developer_app 98

# this app will be expired
create_new_developer_app 99

report_out

modify_postman_collection

CleanUp
exit 0

