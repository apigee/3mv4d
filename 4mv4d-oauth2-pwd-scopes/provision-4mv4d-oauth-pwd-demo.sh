#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-
#
# provision-4mv4d-oauth-pwd-demo.sh
#
# A bash script for importing an API Proxy, then provisioning an API Product, a
# developer, and a developer app in an organization in the Apigee Edge cloud, to
# support the OAuth2.0 Password Grant demonstration. This script also modifies the
# accompanying postman collection to allow invoking the APIs. 
#
# Last saved: <2016-June-21 19:53:20>
#

verbosity=2
waittime=2
netrccreds=0
apiproxyname="oauth2-pwd-scopes-demo"
apiproxydir="./bundle"
apiproxyzip=""
envname="test"
scopes="scope-01 scope-02 scope-03 scope-04 scope-05 scope-06"
apiproductname="4mv4d-OAuth-pwd-TestProduct"
developername="Lois Lane"
developeremail=""
appname="4mv4d-OAuth-pwd-TestApp"
defaultmgmtserver="https://api.enterprise.apigee.com"
postmancollection="1-Oauth-Pwd-Scopes.postman.json"
collectionid="b38fa925-0b93-e8cb-7577-2c99a3d860b1"
credentials=""
TAB=$'\t'


function usage() {
  local CMD=`basename $0`
  echo "$CMD: "
  echo "  Creates an API Product, a Developer, and a developer app enabled on that"
  echo "  product. Emits the client id and secret for the app."
  echo "  Uses the curl utility."
  echo "usage: "
  echo "  $CMD [options] "
  echo "options: "
  echo "  -o org    the org to use."
  echo "  -e env    the environment to enable API Products on."
  echo "  -u user   Edge admin user for the Admin API calls."
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
    MYCURL -X POST \
        -H content-type:application/x-www-form-urlencoded \
        "${mgmtserver}/v1/o/${orgname}/e/${envname}/apis/${apiproxyname}/revisions/${rev}/deployments" \
        -d "override=true&delay=60"

    if [[ ! ${CURL_RC} =~ 200 ]]; then
        echo
        echo "There was an error deploying revision $rev of $apiproxy."
        cat ${CURL_OUT} 1>&2;
        echo
    fi
    [ -f ${apiproxyzip} ] && rm -rf ${apiproxyzip}
}



function create_new_api_product() {
    local scopelist
    MYCURL -X GET ${mgmtserver}/v1/o/${orgname}/apiproducts/${apiproductname}

    if [ ${CURL_RC} -eq 404 ]; then
        echo "create new API Product..."
        sleep 2
        scopelist=`echo "${scopes}" | sed -e ';s/ /","/g' -e 's/^/"/' -e 's/$/"/'`
        MYCURL -H "Content-Type:application/json" \
            -X POST ${mgmtserver}/v1/o/${orgname}/apiproducts -d '{
   "approvalType" : "auto",
   "attributes" : [ ],
   "displayName" : "'${apiproductname}' - '${apiproxy}' Test product",
   "name" : "'${apiproductname}'",
   "apiResources" : [ "/**" ],
   "description" : "Test for '${apiproxyname}'",
   "environments": [ "'${envname}'" ],
   "scopes" : [ '$scopelist' ],
   "proxies": [ "'${apiproxyname}'" ]
  }'
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


function create_new_developer_app() {
    local payload
    MYCURL -X GET "${mgmtserver}/v1/o/${orgname}/developers/${developeremail}/apps/${appname}"
    if [ ${CURL_RC} -eq 404 ]; then
        echo "create new App..."
        payload=$'{\n'
        payload+=$'  "attributes" : [ {\n'
        payload+=$'     "name" : "createdby",\n'
        payload+=$'     "value" : "provisioning script '
        payload+="$0"
        payload+=$'"\n'
        payload+=$'    }],\n'
        payload+=$'  "apiProducts": [ "'
        payload+="${apiproductname}"
        payload+=$'" ],\n'
        payload+=$'  "callbackUrl" : "thisisnotused://www.apigee.com",\n'
        payload+=$'  "name" : "'
        payload+="${appname}"
        payload+=$'"\n}' 

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
  local array
  MYCURL -X GET ${mgmtserver}/v1/o/${orgname}/developers/${developeremail}/apps/${appname} 

  if [ ${CURL_RC} -ne 200 ]; then
    echo
    echoerror "  failed retrieving the app details."
    cat ${CURL_OUT}
    echo
    echo
    exit 1
  fi  

  array=(`cat ${CURL_OUT} | grep "consumerKey" | sed -E 's/[",:]//g'`)
  consumerkey=${array[1]}
  array=(`cat ${CURL_OUT} | grep "consumerSecret" | sed -E 's/[",:]//g'`)
  consumersecret=${array[1]}
}


function report_out() {
    echo
    echo "client_id: $consumerkey"
    echo "client_secret: $consumersecret"
    echo
}


function modify_postman_collection() {
    local DATE=$(date +"%Y%m%d%H%M")
    local outputfile="oauth-pwd-scopes-demo-${DATE}.postman_collection"
    local newuuid=`uuid`
    if [ ! -f ${postmancollection} ]; then
        echo "No postman collection template found."
        echo 
    else
        [ -f ${outputfile} ] && rm -rf ${outputfile}

        sed -e 's/1 - Oauth-Pwd - Scopes/1-Oauth-Pwd-Scopes/' "${postmancollection}" > ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/ORGNAME/${orgname}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/ENVNAME/${envname}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/CLIENT_ID/${consumerkey}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/CLIENT_SECRET/${consumersecret}/g" ${outputfile}
        [ -f ${outputfile} ] && sed -i .tmp -e "s/${collectionid}/${newuuid}/g" ${outputfile}

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
echo "This script imports an API Proxy, then creates an API Product, a Developer, and a developer app"
echo "enabled on that API product. Emits the client id and secret for the app. Then modifies the "
echo "postman collection with those values."
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
create_new_api_product
create_new_developer
create_new_developer_app
report_out
modify_postman_collection

CleanUp
exit 0

