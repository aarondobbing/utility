#!/bin/bash
# Usage:
#  ./elasticdump.sh dump/restore
# Install elasticdump (npm install -g elasticdump) and reference the dir in the ED var - This forks off a process for EVERY index in the background and writes out to elasticdump.log
# ToDo: Dont be such a scumbag with so many processes at once.
ES=http://kube-es.beta.style.com:9200/
ED=/usr/bin/elasticdump
DEST=~/elasticdump

dump() {
mkdir -p $DEST
for index in `/usr/bin/curl -s -XGET $ES/_cat/indices?h=i `
do
        echo $index
        $ED --input=$ES/$index --output=$DEST/$index.json > elasticdump.log &
done
tail -f elasticdump.log
}

restore() {
cd $DEST
FILES=*.json
for f in $FILES
do
        echo "Processing $f ..."
        $ED --bulk=true --input=$f --output=$ES > elasticdump.log &
done
tail -f elasticdump.log
}

$1; exit $?
