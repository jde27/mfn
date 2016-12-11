#!/bin/bash


######
##
## Each fieldnote (of type tex) is tagged with a number of hashtags, like
##
## #LieGroups or #QuantumFieldTheory
##
## Each tag A has its own XML page (of type tag) which lists all the
## fieldnotes tagged #A.
##
## This script generates these tag pages.
##
## First, it looks at the tag directory and uses this to locate XML pages
## of type tag in the main XML directory. It clears these out of the main
## XML directory.
##
## Then it completely clears out the tag directory.
##
## That done, it goes through all the XML fieldnotes and generates
## XML tag pages anew in the tag directory. Finally, it copies these
## pages across to the main XML directory (assuming there are no clashes).
##
######
##
## Initialise directories
##

mfndir=~/git/mfn
mfntag=$mfndir/tags
mfnxml=$mfndir/xml

##
## Go through files in the tag directory and remove them from the main
## directory if they exist and are recognised as tags
##

for file in $(ls $mfntag)
do
    if [ -e $mfntag/$file ]
    then
	testexist=$(cat $mfnxml/$file | grep "<card*" | grep -c 'type="tag"')
	if [ $testexist -gt "0" ]
	then
	    rm -f $mfnxml/$file
	fi
    fi
done

##
## Clear out all tags
##

rm -rf $mfntag/*

##
## Searches through XML fieldnotes looking for ones which are tagged
## and generates files for each tag listing the tagline
## and the XML files which have this tag
## excluding all emacs temp files
##

for file in $(ls $mfnxml | grep ".xml" | grep -v "~")
do
    ##
    ## For each XML file of type tex...
    ##
    filetitle=$(cat $mfnxml/$file | grep "<card*" | sed 's/.*title="\([^"]*\)".*/\1/')
    ##
    ## ... look for its tags...
    ##
    for tag in $(cat $mfnxml/$file | grep "<tag name=*" | sed 's/.*name="\(.*\)".*/\1/')
    do
	##
	## ... check to see if the tag already exists in the tag directory
	##
	if [ ! -e $mfntag/$tag.xml ]
	then
	    ##
	    ## If not, create a new one
	    ##
	    cat > $mfntag/$tag.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="../auxil/mfno.xsl"?>
<card title="$tag" date="$(date +%Y-%m-%d)" type="tag">
<!-- This page collects links to all field notes tagged $tag -->
<bod>
<index>
EOF
	fi
	##
	## If so, add this file to that tag-page
	##
	echo "<item href=\"$file\">$filetitle</item>" >> $mfntag/$tag.xml
    done
done

##
## Now go through and close all XML <...>s
##

for tagfile in $(ls $mfntag)
do
    cat >> $mfntag/$tagfile <<EOG
</index>
</bod>
</card>
EOG
done

##
## Now run through the files in the tag directory.
## Test to see if there's a non-tag file of that name in the main XML
## directory. If so, it warns of a clash to prevent it being overwritten.
## Otherwise, it copies it into the main XML directory.
##

for file in $(ls $mfntag)
do
    if [ -e $mfnxml/$file ]
    then
	nontagexists=$(cat $mfnxml/$file | grep "<card*" | grep -c 'type="tag"')
	if [ $nontagexists -gt "0" ]
	then
	    cp $mfntag/$file $mfnxml/$file
	else
	    echo "Tag clash: " $file " exists as a non-tag in main directory."
	fi
    else
	cp $mfntag/$file $mfnxml/$file
    fi
done
