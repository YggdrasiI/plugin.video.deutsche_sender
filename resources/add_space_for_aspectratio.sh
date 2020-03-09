#!/bin/bash
#
# Ergänzt Höhe oder Breite eines Bildes um
# transparenten Bereich um bestimmtes Seitenverhältnis
# zu erreichen.
#

IN="$1"
OUT="$2"


# Verhältnis von Höhe zu Breite
# RATIO="${3:-2.0}"
RATIO="${3:-1.0}"

WITH_BG="${4:-0}"

MAX_DIM="${5:-1200}"  # Bigger images will be rescaled

BORDER=30
BACKGROUND_COLOR="xc:transparent"
# BACKGROUND_COLOR="xc:green"
BACKGROUND_COLOR="xc:\"#656060AA\""
BACKGROUND_COLOR="xc:\"#A5A0A0AA\""


if [ "$WITH_BG" = "1" ] ; then
	BACKGROUND_IMG="\"../../../media/Kubismus.jpg\" -gravity center -composite "
else
	# BACKGROUND_IMG="\"../../../media/Wolken3.jpg\" -gravity center -composite -evaluate Multiply 0.9"
	BACKGROUND_IMG=""
fi



DIMENSION_IN=$(convert "$IN" -format "%wx%h" info:)

X=${DIMENSION_IN//x*}
Y=${DIMENSION_IN//*x}

echo "${X}x${Y}   max: $MAX_DIM"

# 1. Aspect ratio 

if [ "$(echo "${X} * ${RATIO} > ${Y}" | bc)" = "1" ] ; then
  echo "Eingang-Bild zu breit"
  NEW_X=$(echo "${X}" | bc)
  NEW_Y=$(echo "${NEW_X} * ${RATIO}" | bc)

elif [ "$(echo "${X} * ${RATIO} < ${Y}" | bc)" = "1" ] ; then
  echo "Eingangs-Bild zu hoch"
  NEW_Y=$(echo "${Y}" | bc)
  NEW_X=$(echo "${NEW_Y} / ${RATIO}" | bc)

elif [ "$(echo "${X} * ${RATIO} == ${Y}" | bc)" = "1" ] ; then
  echo "Eingangs-Bild passend"
  NEW_X=$(echo "${X}" | bc)
  NEW_Y=$(echo "${Y}" | bc)
fi

NEW_X=${NEW_X//.*}
NEW_Y=${NEW_Y//.*}

# 2. optional Rescaling
TOO_BIG=$(echo "(${NEW_X} > ${MAX_DIM}) || (${NEW_Y} > ${MAX_DIM})" | bc)
if [ "$TOO_BIG" = "1" ] ; then
	echo "Zu groß"
	echo "${NEW_X}x${NEW_Y}"
  if [ "${NEW_X}" -gt "${NEW_Y}" ] ; then
    NEW_Y=$(echo "${MAX_DIM} * ${NEW_Y} / ${NEW_X}" | bc)
    NEW_X="${MAX_DIM}"
  else
    NEW_X=$(echo "${MAX_DIM} * ${NEW_X} / ${NEW_Y}" | bc)
    NEW_Y="${MAX_DIM}"
	fi
	echo "${NEW_X}x${NEW_Y}"

  if [ "${X}" -gt "${NEW_X}" ] ; then
    Y2=$(echo "${NEW_X} * ${Y} / ${X}" | bc)
    X2=$(echo "${NEW_X}" | bc)
	else
		X2="$X"
		Y2="$Y"
	fi

	# echo "X2xY2 = ${X2}x${Y2}"
	X2=${X2//.*}
	Y2=${Y2//.*}

  if [ "${Y2}" -gt "${NEW_Y}" ] ; then
    X2=$(echo "${NEW_Y} * ${X2} / ${Y2}" | bc)
    Y2=$(echo "${NEW_Y}" | bc)
  fi
	echo "Input skaliert auf ${X2}x${Y2}"

	X2=${X2//.*}
	Y2=${Y2//.*}

  #Note {image}'[XxY]' resize image on read
  DECO="'[${X2}x${Y2}]'"
else
  DECO=""
fi

# 3. Border an "schmaler" Seite
if [ "$(echo "${NEW_X} * ${RATIO} > ${NEW_Y}" | bc)" = "1" ] ; then
	NEW_Y=$(echo "${NEW_Y} + ${BORDER}" | bc)
elif [ "$(echo "${NEW_X} * ${RATIO} < ${NEW_Y}" | bc)" = "1" ] ; then
	NEW_X=$(echo "${NEW_X} + ${BORDER}" | bc)
elif [ "$(echo "${NEW_X} * ${RATIO} == ${NEW_Y}" | bc)" = "1" ] ; then
	NEW_X=$(echo "${NEW_X} + ${BORDER}" | bc)
	NEW_Y=$(echo "${NEW_Y} + ${BORDER}" | bc)
fi

# 4. Float->Int
NEW_X=${NEW_X//.*}
NEW_Y=${NEW_Y//.*}

# TMP_IMG="/dev/shm/tmp.png"
# convert "$IN" -frame 10x10+3+3 "$TMP_IMG"

CMD=$(echo "convert -size \"${NEW_X}x${NEW_Y}\" $BACKGROUND_COLOR \
	\"${IN}\"${DECO} -gravity center -composite \
	\"$OUT\"")

CMD=$(echo "convert -size \"${NEW_X}x${NEW_Y}\" $BACKGROUND_COLOR \
	$BACKGROUND_IMG \
	\"${IN}\"${DECO} -gravity center -composite \
	\"$OUT\"" \
	)

echo "cmd: $CMD"
eval "$CMD"
