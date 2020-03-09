#!/bin/bash
#
# Normalize images:
# Rules: All images of each group get the same aspect ratio
#        (The ratio matches the requirements of the default skin.)
#        <fanart>-Images got background and jpg-format
#        <thumbnail>-Images got transparence border and png-format
#
#

BIN_PATH=$(realpath "$0")
DIR=$(dirname "$BIN_PATH")

loop(){
  RATIO="$1"
  WITH_BG="$2"
  BILDER=$(ls *.png *.jpg *.JPG)
  # BILDER=$(ls ZDF_Sendeze* )
  # BILDER=$(ls *ZDFneo* )
  # BILDER=$(ls *alpha* )
  for BILD in $BILDER ; do
    echo "$BILD"

    # Convert to png
    if [ "$WITH_BG" = "1" ] ; then
      IMG_OUT="../${BILD%.*}.jpg"
    else
      IMG_OUT="../${BILD%.*}.png"
    fi
    $DIR/add_space_for_aspectratio.sh "$BILD" "$IMG_OUT" "$RATIO" "$WITH_BG"
  done

}

extract_urls_from_xml(){
  XML="$1"
  TAG="$2"
  URLS=$(sed -n "s/.*<$TAG>\(.*\)<\/$TAG>.*/\1/p" "$XML")
  IFS="
"
  for URL in $URLS ; do 
    echo "$URL"
    wget -c "$URL"
  done

  # Manual
  cp "../../../media/Sonstige.png" .
}

main() {

  DOWNLOAD="${1:-1}"

  mkdir -p channels/thumbnail/sources
  mkdir -p channels/fanart/sources
  # mkdir -p channels/poster/sources

  cd channels/thumbnail/sources
  test "$DOWNLOAD" = "1" && \
    extract_urls_from_xml "../../../../deutschesender.xml" "thumbnail_url"
  loop 1.5 0

  cd - && cd channels/fanart/sources
  test "$DOWNLOAD" = "1" && \
    extract_urls_from_xml "../../../../deutschesender.xml" "fanart_url"
  loop 0.5625 1  # = 9:16

  # Poster base on same images as fanart
  # cd - && cd channels/poster/sources
  # test "$DOWNLOAD" = "1" && \
  #   extract_urls_from_xml "../../../../deutschesender.xml" "fanart_url"
  # loop 0.5 1
}

main "$1"

echo "Size of all resources:"
du --exclude "sources" -hs .
