#!/bin/bash

WAIT=5  # Sekunden

test_stream(){
  SENDER="$1"
  URL="$2"
  let IDENT=30-${#SENDER}
  FORMAT="%*s\n"
  echo -n "$SENDER: "

  mpv --length=$WAIT --no-video --really-quiet "$URL" && \
    printf "$FORMAT" $IDENT "ok" || printf "$FORMAT" $IDENT "fail"
  }

extract_list() {
  LIST=$( grep -e "\(<link>\|<title>\)" < "../deutschesender.xml" |\
    tail --lines=+2 |\
    sed "/^/{N;s/\s*\n\s*/ /;s#<[^>]*>#\"#g;s/^\s*//}" \
  )

  echo "Extrahierte Sender+Links:"
  echo -e "$LIST\n\nTeste…\n\n"

  IFS="
"
  # Tests starten
  for LINE in $LIST ; do
    eval test_stream $LINE
  done
}


manual_list() {
  test_stream "Das Erste" "http://mcdn.daserste.de/daserste/de/master.m3u8"
  test_stream "Tagesschau (Live)" "http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"
  test_stream "WDR" "http://wdrfsgeo-lh.akamaihd.net/i/wdrfs_geogeblockt@530016/master.m3u8"
  test_stream "NDR Fernsehen Hamburg" "http://ndrfs-lh.akamaihd.net/i/ndrfs_nds@430233/master.m3u8"
  test_stream "NDR Fernsehen Mecklenburg-Vorpommern" "http://ndrfs-lh.akamaihd.net/i/ndrfs_nds@430233/master.m3u8"
  test_stream "NDR Fernsehen Niedersachsen" "http://ndrfs-lh.akamaihd.net/i/ndrfs_nds@430233/master.m3u8"
  test_stream "NDR Fernsehen Schleswig-Holstein" "http://ndrfs-lh.akamaihd.net/i/ndrfs_nds@430233/master.m3u8"
  test_stream "rbb Berlin" "http://rbblive-lh.akamaihd.net/i/rbb_berlin@144674/master.m3u8"
  test_stream "rbb Brandenburg" "http://rbblive-lh.akamaihd.net/i/rbb_brandenburg@349369/master.m3u8"
  test_stream "MDR Sachsen-Anhalt" "http://mdrsahls-lh.akamaihd.net/i/livetvmdrsachsenanhalt_de@513999/master.m3u8"
  test_stream "MDR Sachsen" "http://mdrsnhls-lh.akamaihd.net/i/livetvmdrsachsen_de@513998/master.m3u8"
  test_stream "MDR Thüringen" "http://mdrthuhls-lh.akamaihd.net/i/livetvmdrthueringen_de@514027/master.m3u8"
  test_stream "Saarländischer Rundfunk" "http://srlive24-lh.akamaihd.net/i/sr_universal02@107595/master.m3u8"
  test_stream "Bayerischer Rundfunk Nord" "http://brlive-lh.akamaihd.net/i/bfsnord_germany@119898/master.m3u8"
  test_stream "Bayerischer Rundfunk Süd" "http://brlive-lh.akamaihd.net/i/bfsnord_germany@119898/master.m3u8"
  test_stream "Südwestrundfunk" "https://swrbwhls-i.akamaihd.net/hls/live/667638/swrbwd/master.m3u8"
  test_stream "Arte" "http://artelive-lh.akamaihd.net/i/artelive_de@393591/master.m3u8"
  test_stream "Arte (FR)" "http://artelive-lh.akamaihd.net/i/artelive_fr@344805/master.m3u8"
  test_stream "KiKA" "http://kikade-lh.akamaihd.net/i/livetvkika_de@450035/master.m3u8"
  test_stream "Phoenix" "http://zdfhls19-i.akamaihd.net/hls/live/744752/de/high/master.m3u8"
  test_stream "HR" "http://hrlive1-lh.akamaihd.net/i/hr_fernsehen@75910/master.m3u8"
  test_stream "ARD One" "http://onelivestream-lh.akamaihd.net/i/one_livestream@568814/master.m3u8"
  test_stream "ARD-Alpha" "http://brlive-lh.akamaihd.net/i/bralpha_germany@119899/master.m3u8"
  test_stream "ZDF" "http://zdf-hls-01.akamaized.net/hls/live/2002460/de/high/master.m3u8"
  test_stream "ZDFneo" "http://zdf-hls-02.akamaized.net/hls/live/2002461/de/high/master.m3u8"
  test_stream "ZDFinfo" "http://zdfhls17-i.akamaihd.net/hls/live/744750/de/high/master.m3u8"
  test_stream "3sat" "http://zdfhls18-i.akamaihd.net/hls/live/744751/dach/high/master.m3u8"
  test_stream "ORF-1" "https://orf1.mdn.ors.at/out/u/orf1/qxb/manifest.m3u8"
  test_stream "ORF-2" "https://orf2.mdn.ors.at/out/u/orf2/qxb/manifest.m3u8"
  test_stream "ORF-3" "https://orf3.mdn.ors.at/out/u/orf3/qxb/manifest.m3u8"
  test_stream "ORF-Sport" "https://orfs.mdn.ors.at/out/u/orfs/qxb/manifest.m3u8"
  test_stream "DW-TV" "http://dwstream6-lh.akamaihd.net/i/dwstream6_live@123962/master.m3u8"
  test_stream "NASA - ISS HD Earth Viewing Experiment" "http://iphone-streaming.ustream.tv/uhls/17074538/streams/live/iphone/playlist.m3u8"

}

extract_list
