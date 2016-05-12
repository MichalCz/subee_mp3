#!/bin/bash

function docp {
	FILE=$1
	if [[ ! -e "$1" ]]; then
		echo \#skipped $1;
		return 0;
	fi
	CNT=$2
	NAME=$(basename "$FILE")
	EXISTS=`[[ -e "$FILE" ]] && echo y`
	EXT=${NAME##*.}

	OUT=$( readlink -e "$3" )

	if [[ ! -e "$OUT" ]]; then
		echo ${OUT} does not exist.
		return 1;
	fi

	FNAME=`echo ${NAME%.*} | perl -pe 's:[^\w\d]+:_:g' | perl -pe 's:(^\d+_)|(_$)::g'`
	OUTFILE="${OUT}/${CNT}_${FNAME}.mp3"

	if [[ "$EXT" == "mp3" ]]; then
		echo \#transfering $FILE
		ffmpeg -threads 0 -nostdin -y -v 24 -vn -i "$FILE" -codec:a copy "$OUTFILE"
		EXT=$?
	else
		echo \#encoding $FILE
		ffmpeg -threads 0 -nostdin -y -v 24 -vn -i "$FILE" -ab 320k "$OUTFILE"
		EXT=$?

	fi
	if [[ $EXT -eq 0 ]]; then
		echo \#normalizing $OUTFILE
		mp3gain -r -k -q -s r -c -d 2.0 $OUTFILE
		return $?
	else
		return 2;
	fi
}

LIST=$1
OUTDIR=$(readlink -f "$2")/$(basename ${LIST%.*})

mkdir -p "${OUTDIR}"

egrep -v '^#' "$LIST" | sed -e '1 s/^\xef\xbb\xbf//' -e 's:\\:/:g' -e 's/W:/../g' -e 's:\r::g' | \
	while read line && ((var+=1)) && docp "$line" $( printf %03d ${var} ) "$OUTDIR"; do true; done
