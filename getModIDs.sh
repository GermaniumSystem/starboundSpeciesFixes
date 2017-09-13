#!/bin/bash

[ -e "tmp/workshopPages" ] || mkdir -p 'tmp/workshopPages'

function getPage {
  # Steam can be pretty flaky. It'll say that no items matched our search even though there are plenty more pages.
  NUM="$1"
  FAILS=0
  while [ "$FAILS" -lt 5 ] ; do
    wget -q -O "tmp/workshopPages/list_${NUM}.html" "http://steamcommunity.com/workshop/browse/?appid=211820&browsesort=mostrecent&section=readytouseitems&actualsort=mostrecent&p=${NUM}"
    if grep -qi 'id="no_items"' "tmp/workshopPages/list_${NUM}.html" ; then
      FAILS=$((FAILS + 1))
      echo "[INFO]: Supposed end of list reached at page ${NUM}. Sleeping for ${FAILS}0 seconds and retrying...."
      sleep ${FAILS}0s
    else
      return 0
    fi 
  done
  return 100
}
for NUM in $(seq 1 1000) ; do # We could just while true, but this adds an extra safety mechanism.
  echo "[INFO]: Requesting list page '${NUM}'"
  #wget -q -O "workshopPages/list_${NUM}.html" "http://steamcommunity.com/workshop/browse/?appid=211820&browsesort=mostrecent&section=readytouseitems&actualsort=mostrecent&p=${NUM}"
  #if grep -qi 'id="no_items"' "workshopPages/list_${NUM}.html" ; then
  #  echo "[INFO]: End of list reached at page ${NUM}."
  #  break
  #fi
  if ! getPage $NUM ; then
    echo "[INFO]: End of list reached."
    break
  fi
done

echo "[INFO]: Generating ID list."
grep -E '^	*<a href="http://steamcommunity.com/sharedfiles/filedetails/\?id=' tmp/workshopPages/list_* | sed 's/.*?id=//' | sed 's/&.*//' | sort -un > tmp/IDList.txt
echo "[INFO]: - Complete with $(wc -l tmp/IDList.txt | sed 's/ .*//') mod IDs."

echo "[INFO]: Completed at $(date)."
