# subee_mp3
Set of scripts for transferring music in right order, single volume, etc. from an m3u8 playlist to sdcards/usbs for use in Subaru cars with Hamman/Kardon audios (tested on MY 14+ Forester)

For now it's just a simple script, we'll see where we go from here - if you want to collaborate, write me a message. :)

## Dependencies

Subee_mp3 will need the following dependencies:
 * ffmpeg with mp3 codec (and any decoders you like)
 * mp3gain

## cp_audio.sh

This script does the following:

* creates a directory named the same as your .m3u8 file (without extension)
* converts all non-mp3 files to mp3
* generates filenames without strange characters
* every file gets a number (now 3 digits max)
* every file gets written in order (so our Subees can play it in order)

Warning... for some reasons this script also replaces "W:" in the begining of every file to "../". I'll remove that later. ;)

Usage:

    bash /path/to/subee_mp3/cp_audio.sh -f <your_playlist>.m3u8 -o <target_dir> -O -t <tempdir> -r <sed_path_replacement>

Options:

    -f | --file         Playlist file
    -r | --replace      Path part replacement (argument to sed -e)
    -t | --tempdir      Temporary dir
    -o | --output       Output dir
    -O | --overwrite    Overwrite files

### Samples:

Multiple playlists:

    for I in `ls *.m3u8`; do echo bash cp_audio.sh -f $I /media/subaru_usb <your opts>; done

# Future plans

Lots of!
