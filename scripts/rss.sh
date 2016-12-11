#!/bin/bash

###############
##
## This script looks through the fieldnotes and generates an
## RSS feed, listing the last ten fieldnotes by modification date.
##
###############
##
## Initialise directories
##

mfndir=~/git/mfn
mfnxml=$mfndir/xml/

##
## Start writing RSS
##

cat > $mfnxml/mfno.rss <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet type="text/css" href="../auxil/rss.css"?>
<rss version="2.0">

<channel>
<title>Mathematical Field Notes</title>
  <link>http://www.homepages.ucl.ac.uk/~ucahjde/mfn/</link>
  <description>Hypertext index cards containing notes on mathematics</description>
EOF

##
## Work through fieldnotes
##

cardnum=0
for card in $(ls $mfnxml | grep ".xml")
do
    ##
    ## Find the card type
    ##
    ctype=$(cat $mfnxml/$card | grep "<card" | sed 's|^.*type="\([^"]*\)".*$|\1|')
    ##
    ## If it's a TeX card...
    ##
    if echo $ctype | grep -q tex;
    then
	##
	## ...extract metadata
	##
	created[$cardnum]=$(cat $mfnxml$card | grep "<card" | sed 's|^.*created="\([^"]*\)".*$|\1|')
	lastmod[$cardnum]=$(cat $mfnxml/$card | grep "<card" | sed 's|^.*date="\([^"]*\)".*$|\1|')
	title[$cardnum]=$(cat $mfnxml/$card | grep "<card" | sed 's|^.*title="\([^"]*\)".*$|\1|')
	link[$cardnum]=$card
	##
	## and count on
	##
	((cardnum++))
    fi
done

##
## How many cards do we have
##

totcard=$cardnum

##
## We sort the fieldnotes by their last-modified date
##

sortord=($(for ((x=0; x<$totcard; x++))
	   do
	       echo $x ${lastmod[$x]}
	   done | sort -r -k2 | sed 's|^\([0-9]*\)\s.*$|\1|'))

##
## Just print the last ten fieldnotes (ordered by last-modified date).
##

for ((y=0; y<10; y++))
do
    cat >> $mfnxml/mfno.rss <<EOF
  <item>
    <title>${title[${sortord[$y]}]}</title>
    <link>${link[${sortord[$y]}]}</link>
    <pubDate>${lastmod[${sortord[$y]}]}</pubDate>
  </item>
EOF
done

##
## Close all tags.
##

cat >> $mfnxml/mfno.rss <<EOF
</channel>
</rss>
EOF
