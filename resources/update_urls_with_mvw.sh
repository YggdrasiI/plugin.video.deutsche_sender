#!/bin/bash
# Nutzt die 
#   <guid isPermaLink="false">{ID}</guid>
# -Zeilen zum Abgleich der Livestream-Urls (auch wenn da PermaLink false ist...)
# Die entsprechenden ids wurden als <mvw_guid> im eigenen xml ergänzt.

SENDER_FILE="../deutschesender.xml"
SENDER_BACKUP_FILE="../deutschesender.backup.xml"
SENDER_NEXT_FILE="../deutschesender.next.xml"

# Backup current xml file and prepare next version
cp "$SENDER_FILE" "$SENDER_BACKUP_FILE"
cp "$SENDER_FILE" "$SENDER_NEXT_FILE"

# Get list of channel CDATA
CDATAS=$( grep -A 2 "<mvw_cdata>" < "$SENDER_FILE" |\
  sed -n "s/.*mvw_cdata>\(.*\)<\/mvw_cdata.*/\1/p")

# Fetch new urls
# RSS_FEED=$(wget -O - "https://mediathekviewweb.de/feed?query=livestream%20%23livestream")
RSS_FEED=$(cat /dev/shm/feed.rss)

N_CHANGED=0

IFS_BACK=$IFS
IFS="
"
for CDATA in $CDATAS ; do
  echo "Sender-CDATA: $CDATA"

  if [ "$CDATA" = "[]" ] ; then
    echo "Empty CDATA... skip entry"
    continue
  fi

  NEW_LINK=$( grep -F -A 2 "$CDATA" <<< "$RSS_FEED" |\
    grep "<link>" |\
    sed -n "s/.*link>\(.*\)<\/link.*/\1/p")
  
	# Get channel name(s) for this CDATA
	CHANNELS=$( grep -F -B 11 "$CDATA" < "$SENDER_FILE" |\
		grep "<title>" |\
		sed -n "s/.*title>\(.*\)<\/title.*/\1/p")

  for CHANNEL in $CHANNELS ; do

    echo "Channel: $CHANNEL"
    CUR_LINK=$( grep -F -A 1 "<title>$CHANNEL</title>" < "$SENDER_FILE" |\
      grep "<link>" |\
      sed -n "s/.*link>\(.*\)<\/link.*/\1/p")

    if [ "$CUR_LINK" != "$NEW_LINK" ] ; then
			if [ -n "$NEW_LINK" ] ; then
				echo -e "\tOld link: $CUR_LINK"
				echo -e "\tNew link: $NEW_LINK"

				CUR_LINK_MOD=$(echo "$CUR_LINK" | sed 's#/#\\/#g')
				NEW_LINK_MOD=$(echo "$NEW_LINK" | sed 's#/#\\/#g')

				sed -i "s/<link>$CUR_LINK_MOD<\/link>/<link>$NEW_LINK_MOD<\/link>/" \
					"$SENDER_NEXT_FILE"

				(( N_CHANGED += 1 ))
			else
				echo -e "\tKein neuer Link enthalten."
			fi

    # else
    #   echo "Ok"
    fi

    # read FOO
  done
	echo -e "=================================\n"
done

diff -q "$SENDER_FILE" "$SENDER_NEXT_FILE"
if [ "$?" = "1" ] ; then
  echo "$N_CHANGED URLs aktualisiert."
else
  echo "Keine URLs geändert."
fi

