#!/bin/bash
ARGS=$1
API_KEY="15b9666294d951546c3a3b4b1b2a83f55638473c"
JQ_INSTALLED=$(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed")
CU_INSTALLED=$(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed")
BC_INSTALLED=$(dpkg-query -W -f='${Status}' bc 2>/dev/null | grep -c "ok installed")
MISSING_PACKAGES=0

if [ -z "$1" ]; then
    echo "> No arguments, please specify at least one argument: ./ani.sh ARG, escape any spaces."
    exit
fi

function checkpackages {
    if [ $JQ_INSTALLED -eq 0 ]; then
        let "MISSING_PACKAGES++"
    fi
    if [ $CU_INSTALLED -eq 0 ]; then
        let "MISSING_PACKAGES++"
    fi
    if [ $BC_INSTALLED -eq 0 ]; then
        let "MISSING_PACKAGES++"
    fi

    if [ $MISSING_PACKAGES -gt 0 ]; then
        echo "One or more required packages are missing, install them? (y/n)"
        read REPLY
        if [ "$REPLY" = "y" ]; then
            sudo apt-get install jq curl bc > /dev/null
        fi
    fi
}

checkpackages

R=0
while true; do
    case "$2" in
        -1 ) R=0; shift ;;
        -2 ) R=1; shift ;;
        -3 ) R=2; shift ;;
        -4 ) R=3; shift ;;
        -5 ) R=4; shift ;;
        -- ) R=0; shift ; break ;;
        * ) break ;;
    esac
done

URL="http://tv.yuuki-chan.xyz/json.php?key=$API_KEY&controller=search&query=$ARGS"
RES=$(curl -s $URL) > /dev/null
for (( index=0; index<=$R; index++ ))
do
    ID=$(echo $RES | jq '.results['$index'].id' | tr -d '"')
    TI=$(echo $RES | jq '.results['$index'].title' | tr -d '"')
    EP=$(echo $RES | jq '.results['$index'].episode' | tr -d '"')
    SU=$(echo $RES | jq '.results['$index'].subtitle' | tr -d '"')
    ST=$(echo $RES | jq '.results['$index'].station' | tr -d '"')
    AT=$(echo $RES | jq '.results['$index'].unixtime' | tr -d '"')
    AD=$(echo $RES | jq '.results['$index'].anidb' | tr -d '"')
    NOW=$(TZ=":Asia/Tokyo" date +%s)
    DIFF=$(echo $AT-$NOW | bc)
    TIME=$(printf "%dd %dh %dm %ds" $(( DIFF / (3600 * 24) ))  $(( (DIFF / 3600 ) % 24)) $(( (DIFF / 60) % 60)) $((DIFF % 60)))

    echo -e "\e[0m>\e[31m $TI\e[0m Episode\e[31m $EP\e[0m airs on\e[31m $ST\e[0m in\e[31m $TIME\e[0m"
done
exit
