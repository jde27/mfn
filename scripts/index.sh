#!/bin/bash

##
## Initialise directory names and locations
##

mfndir=~/git/mfn
mfnscr=$mfndir/scripts
mfntag=$mfndir/tags
mfnxml=$mfndir/xml

##
## Create output file name and metadata like title and date
##
outfile=$mfnxml/index.xml
lastmod=$(date +%Y-%m-%d)
created="2016-06-19"
title="Index"

##
## Start writing index file (metadata).
##

cat > $outfile <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="../auxil/mfno.xsl"?>

<card title="$title" created="$created" date="$lastmod" type="index">
<metadata>
<authors>
<author name="Jonny Evans" email="j.d.evans@ucl.ac.uk"/>
</authors>
</metadata>
<bod>
<section name="Recent updates">
EOF

##
## Run the RSS script to generate an RSS feed.
##

$mfnscr/rss.sh

##
## Generate a list of recent content from the newly-updated RSS feed.
##

itemno=-1
while read -r line
do
    if echo $line | grep -q "<item>";
    then
	((itemno++))
    elif [ $itemno -ge 0 ];
    then
	echo $itemno
	if echo $line | grep -q "<title>";
	then
	    echo $line
	    titlno[$itemno]=$(echo $line | sed 's|^<title>\(.*\)</title>$|\1|')
	elif echo $line | grep -q "<link>";
	then
	    linkno[$itemno]=$(echo $line | sed 's|^<link>\(.*\)</link>$|\1|')
	elif echo $line | grep -q "<pubDate>";
	then
	    pubda[$itemno]=$(echo $line | sed 's|^<pubDate>\(.*\)</pubDate>$|\1|')
	fi
    fi
done < $mfnxml/mfno.rss

##
## Write recent items to XML.
##

for ((x=0; x<$itemno; x++))
do
    cat >> $outfile <<EOF
<recent href="${linkno[$x]}" date="${pubda[$x]}"/>
EOF
done

##
## Create tag links.
##

cat >> $outfile <<EOF
</section>
<section name="Browse by tag">
EOF

for hashtag in $mfntag/*
do
    tagnam=$(echo ${hashtag##*/} | sed 's|^\(.*\)\.xml$|\1|')
    printf "<tag name=\"$tagnam\"/>" >> $outfile
done

##
## Create complete list of fieldnotes.
##

cat >> $outfile <<EOF
</section>
<section name="Browse alphabetically">
EOF

for letter in {A..Z}
do
    if ls $mfnxml | grep -i "^$letter.*\.xml$";
    then
	printf "<p><b>$letter</b><br/>" >> $outfile
	for card in $(ls $mfnxml | grep -i "^$letter.*\.xml$")
	do
	    if cat $mfnxml/$card | grep -q type=\"tex\";
	    then
	       printf "<link href=\"$card\"/>" >> $outfile
	    fi
	done
	printf "</p>" >> $outfile
    fi
done

##
## Close all tags.
##

cat >> $outfile <<EOF
</section>
</bod>
</card>
EOF


