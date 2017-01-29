#!/bin/sh
DIR_GOOGLE="./mirror/doms"
DIR_MAIN="./static"

UNICODE_UP=$(python2.7 -c "print u'\u25B2'.encode('utf8')")
UNICODE_DOWN=$(python2.7 -c "print u'\u25BC'.encode('utf8')")

escape () {
    sed -i 's/ö/\&ouml;/g' $1
    sed -i 's/ü/\&uuml;/g' $1
    sed -i 's/ä/\&auml;/g' $1
    sed -i 's/Ö/\&Ouml;/g' $1
    sed -i 's/Ü/\&Uuml;/g' $1
    sed -i 's/Ä/\&Auml;/g' $1
    sed -i 's/ß/\&szlig;/g' $1
    sed -i 's/$UNICODE_UP/&#x25B2;/g' $1
    sed -i 's/$UNICODE_DOWN/&#x25BC;/g' $1
}

export -f escape

find $DIR_GOOGLE -type f -name "*.html" -exec bash -c 'escape {}' \;
find $DIR_MAIN -type f -name "*.html" -exec bash -c 'escape {}' \;
