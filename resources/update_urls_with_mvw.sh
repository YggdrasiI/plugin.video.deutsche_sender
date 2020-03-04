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

# Get list of channel GUIDS
GUIDS=$( grep -A 2 "<mvw_guid>" < "$SENDER_FILE" |\
  sed -n "s/.*mvw_guid>\(.*\)<\/mvw_guid.*/>\1</p")

# Fetch new urls
RSS_FEED=$(wget -O - "https://mediathekviewweb.de/feed?query=livestream%20%23livestream")
# RSS_FEED=$(cat /dev/shm/feed.rss)


# echo "Sender: $SENDER"

IFS_BACK=$IFS
IFS="
"
for GUID in $GUIDS ; do
  # echo "Sender-GUID: $GUID"

  if [ "$GUID" = "><" ] ; then
    echo "Empty GUID... skip entry"
    continue
  fi

  NEW_LINK=$( grep -B 2 "$GUID" <<< "$RSS_FEED" |\
    grep "<link>" |\
    sed -n "s/.*link>\(.*\)<\/link.*/\1/p")
  
  # Get channel name(s)
  CHANNELS=$( grep -B 8 "$GUID" < "$SENDER_FILE" |\
    grep "<title>" |\
    sed -n "s/.*title>\(.*\)<\/title.*/\1/p")

  # This only works if GUID is only used one time.
  # Sometimes, multiple channels links on the same entry...
  ## Current Link for this GUID
  #CUR_LINK=$( grep -B 8 "$GUID" < "$SENDER_FILE" |\
  #  grep "<link>" |\
  #  sed -n "s/.*link>\(.*\)<\/link.*/\1/p")

  for CHANNEL in $CHANNELS ; do

    echo "Channel: $CHANNEL"
    CUR_LINK=$( grep -A 1 "<title>$CHANNEL</title>" < "$SENDER_FILE" |\
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
			else
				echo -e "\tKein neuer Link enthalten."
			fi

    # else
    #   echo "Ok"
    fi

    # read FOO
  done

done

diff -q "$SENDER_FILE" "$SENDER_NEXT_FILE"
if [ "$?" = "1" ] ; then
  echo "URLs aktualisiert."
else
  echo "Keine URLs geändert."
fi

