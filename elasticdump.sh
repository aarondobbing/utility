#!/bin/bash
# Usage:
#  ./elasticdump.sh dump/restore
# Install elasticdump (npm install -g elasticdump) and reference the executable in the ED var. Dump this script into a CLEAN directory and let it go to town. Make sure you set your dest and source ES cluster urls!!!!
# ToDo: Clean up this horrible horrible threading logic, or just implement in python/ruby and have something pretty.
SOURCE_ES=http://elasticsearch-source:9200
DEST_ES=http://elasticsearch-destination:9200
ED=/usr/bin/elasticdump
THREAD=10

dump() {
mkdir -p .flag
mkdir -p logs
for index in `/usr/bin/curl -s -XGET $SOURCE_ES/_cat/indices?h=i `
do
    COUNT=$(ls -1 .flag/ | wc -l)

    while [[ $COUNT -eq $THREAD ]]; do
        echo "Max concurrent threads reached... Going to sleep..."
        sleep 15
        COUNT=$(ls -1 .flag/ | wc -l)
    done

    if [[ $COUNT -lt $THREAD ]]; then
      
        echo "Processing $index ..."
        (touch .flag/$INDEX.flag; $ED --input=$SOURCE_ES/$index --output=$index.json > logs/$INDEX.log; rm .flag/$INDEX.flag) &
    fi
done
wait
echo "Dump is completed... Cleaning up..."
rm -rf flag/

}

restore() {
FILES=*.json
mkdir -p .flag
mkdir -p logs
for f in $FILES
do
    COUNT=$(ls -1 .flag/ | wc -l)

    while [[ $COUNT -eq $THREAD ]]; do
        echo "Max concurrent threads reached... Going to sleep..."
        sleep 15
        COUNT=$(ls -1 .flag/ | wc -l)
    done

	if [[ $COUNT -lt $THREAD ]]; then
	    INDEX=`echo $f | awk -F\.json '{print $1}'`
	    
        echo "Processing $f ..."
        (touch .flag/$INDEX.flag; $ED --input=$f --output=$DEST_ES/$INDEX > logs/$INDEX.log; rm .flag/$INDEX.flag) &
    fi
done
wait
echo "Restore is completed... Cleaning up..."
rm -rf flag/
}

migrate() {
mkdir -p .flag
mkdir -p logs
for index in `/usr/bin/curl -s -XGET $SOURCE_ES/_cat/indices?h=i `
do
    COUNT=$(ls -1 .flag/ | wc -l)

    while [[ $COUNT -eq $THREAD ]]; do
        echo "Max concurrent threads reached... Going to sleep..."
        sleep 15
        COUNT=$(ls -1 .flag/ | wc -l)
    done

    if [[ $COUNT -lt $THREAD ]]; then        
        echo "Processing $index ..."
        (touch .flag/$INDEX.flag; $ED --input=$SOURCE_ES/$index --output=$DEST_ES/$index > logs/$INDEX.log; rm .flag/$INDEX.flag) &
    fi
done
wait
echo "migration is completed... Cleaning up..."
rm -rf flag/

}


$1; exit $?