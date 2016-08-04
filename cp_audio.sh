#!/bin/bash

LIST=$1

TMPDIR=/tmp/subee_mp3-$UID

OVERWRITE=false

while :
do
    case "$1" in
		-f | --file)
			LIST="$2"   # You may want to check validity of $2
			shift 2
			;;
		-r | --replace)
			PATH_REPLACEMENT="$2" # You may want to check validity of $2
			shift 2
			;;
		-t | --tempdir)
			TMPDIR=$2
			shift 2;
			;;
		-o | --output)
			OUTDIR=$(readlink -f "$2")/$(basename ${LIST%.*})
			shift 2
			;;
		-O | --overwrite) # End of all options
			OVERWRITE=true
			shift
			;;
		--) # End of all options
			shift
			break;
			;;
		-*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
		*)  # No more options
			break
			;;
    esac
done


function docp {
	FILE=$1
	if [[ ! -e "$1" ]]; then
		echo \#skipped $1;
		return 255;
	fi
	CNT=$2
	NAME=$(basename "$FILE")
	EXISTS=`[[ -e "$FILE" ]] && echo y`
	EXT=$( echo ${NAME##*.} | tr A-Z a-z );
	NEEDS_ENCODING=false

	OUT=$( readlink -e "$3" )

	if [[ ! -e "$OUT" ]]; then
		echo ${OUT} does not exist.
		return 1;
	fi

	if [[ `ffprobe -v 0 -show_format "$FILE" | grep bit_rate | sed -e s:bit_rate=::` -gt 320000 ]]; then
		NEEDS_ENCODING=true
		EXT="aac"
	fi

	if [[ "$EXT" == "mp3" ]]; then
		NEEDS_ENCODING=false
		EXTRAOPTS="-bsf:a remove_extra"
	else
		NEEDS_ENCODING=true
		EXT="mp3"
		EXTRAOPTS="-bsf:a remove_extra"
	fi

	FNAME=`echo ${NAME%.*} | perl -pe 's:[^\w\d]+:_:g' | perl -pe 's:(^\d+_)|(_$)::g'`

	TMPFILE="${TMPDIR}/file.${EXT}"
	OUTFILE="${OUT}/${CNT}_${FNAME}.${EXT}"
	EXTGAIN="${EXT}gain"

	if [[ -e $OUTFILE ]] && ! $OVERWRITE; then
		echo ===== skipping file $OUTFILE
		return 0

	elif $NEEDS_ENCODING; then
		echo ----- encoding $FILE
		ffmpeg -threads 0 -nostdin -v 24 -y -i "$FILE" -vn -c:a libmp3lame -vsync 2 -ac 2 -q:a 0 -f adts $EXTRAOPTS "$TMPFILE"
		OUT=$?
	else
		echo ----- transfering $FILE
		ffmpeg -threads 0 -nostdin -v 24 -y -i "$FILE" -vn -c:a copy -vsync 2 $EXTRAOPTS "$TMPFILE"
		OUT=$?
	fi

	if [[ $OUT -eq 0 ]]; then
		echo ----- normalizing $TMPFILE
		${EXTGAIN} -r -k -q -s r -c -d 2.0 "$TMPFILE"
		OUT=$?
		if [[ $OUT -eq 0 ]]; then

			echo ----- transferring to destination $OUTFILE
			mv "$TMPFILE" "$OUTFILE"

			if ! [[ $OUT -eq 0 && $? -eq 0 ]]; then
				echo ===== "FAIL(4)"
				return 4;
			else
				echo ===== success!
				return 0;
			fi
		else
			echo ==== "FAIL(3)"
			return 3
		fi
	else
		echo ===== "FAIL(2)"
		rm -f "$TMPFILE"
		return 2
	fi
}


mkdir -p "${OUTDIR}" && \
mkdir -p "${TMPDIR}" && \
egrep -v '^#' "$LIST" | sed -e '1 s/^\xef\xbb\xbf//' -e 's:\\:/:g' -e "$PATH_REPLACEMENT" -e 's:\r::g' | \
	while read line; do
		((var+=1))
		docp "$line" $( printf %03d ${var} ) "${OUTDIR}"
		OUT=$?

		if ! [[ $OUT -eq 0 ]]; then
			echo Executed with exit: $OUT
			break
		fi
	done

rm $TMPDIR -rf
exit $OUT
