#!/bin/bash

# Specify directories where things are stored
mfndir=~/git/mfn       # Overall MFN
mfnsrc=$mfndir/texml # Source
mfnxml=$mfndir/xml   # XML
mfntmp=$mfndir/tmp

# Get the name of the input file
p=$1
# Strip off any pre-trailing directory information
# or ".tex" extension if it's there
fileroot=$(echo ${p##*/} | sed 's|\(.*\)\.tex|\1|')

# Add it back in, in a controlled way
# to create names of input and output files.
# Also create a temporary file to hold interrim data.
infile=$mfnsrc/$fileroot.tex
outfile=$mfnxml/$fileroot.xml
tmp=$mfntmp/$fileroot.tmp

echo "This is a temporary file." > $tmp

# Get current date for "last modified" field.
lastmod=$(date +%Y-%m-%d)

# Check to see if the XML is already there.
# If so, find out when it was created. Set this as creation date.
# If not, set lastmod as creation date.
if [[ -e $outfile ]]
then
    created=$(cat $outfile | grep "<card" | sed 's|^.*created="\([^"]*\)".*$|\1|')
else
    created=$lastmod
fi

################################################################################
##
## We often use < and > symbols in equations and this screws
## with XML. The first part of the code goes through and finds
## < or > symbols inside equations and replaces then with &lt;
## or &gt; which then parses correctly in the XML.
##
## To detect if we're inside an equation, we work character-by-character
## using a variable insideeq which is 0 until we pass a dollar sign or a \[
## and then switches to 1, but switches back again once we pass a second
## dollar sign or a \].
##
## Note that in MathJax, all equation environments (including \begin{align} etc)
## are contained inside a \[...\] or $...$, so this handles all possibilities.
##
## To make things more complicated, XML also dislikes & characters, so we
## actually need to write &#038;lt; etc.
##
## For good measure, we also convert all instances of & to &#038;
##
################################################################################

# A variable which checks if we're inside an equation or not
insideeq=0
# A variable to hold the previous character
lastchar=0

while IFS= read -n1 -r -d '' char
do
    # opc is the output character
    opc=$char

    # Always replace & by &#038;
    if [[ $char == "&" ]]
    then
	opc="&#038;"
    fi

    # If we're inside an equation, replace < with &lt;
    # and > with &gt;
    if [[ insideeq -eq 1 ]]
    then
	if [[ $char == "<" ]]
	then
	    opc="&#038;lt;"
	elif [[ $char == ">" ]]
	then
	    opc="&#038;gt;"
	fi
    fi

    # If we pass a dollar sign, toggle the variable insideeq
    if [[ $char == "$" ]]
    then
	if [[ insideeq -eq 0 ]]
	then
	    insideeq=1
	else
	    insideeq=0
	fi
    fi

    # If we pass a \[, toggle insideeq to 1
    if [[ $char == "[" ]]
    then
	if [[ $lastchar == \\ ]]
	then
	    insideeq=1
	fi
    fi

    # If we pass a \], toggle insideeq to 0
    if [[ $char == "]" ]]
    then
	if [[ $lastchar == \\ ]]
	then
	    insideeq=0
	fi
    fi

    # Output the output character to the tmp file
    # being careful not to feed printf a % sign
    if [[ $opc == "%" ]]
    then
	echo -n "$opc" >> $tmp
    else
	printf "$opc" >> $tmp
    fi

    # Keep track of this character for the next iteration (to detect
    # 2-character combinations like \[ and \] )
    lastchar=$char
done < $infile

################################################################################
##
## There will be four stages of extracting information from the file:
##  -  Stage 1 is the metadata extraction
##  -  Stage 2 writes the metadata to the outfile in a specific XML format
##  -  Stage 3 is the content extraction, which writes to outfile as we go
##  -  Stage 4 closes all XML tags
##
## We initialise a variable to remember whereabouts in the process we are.

stagenum=1

## We also initialise variables to index authors, links, tags,
## sections, items

authornum=0
linknum=0
tagnum=0
sectionnum=0
itemnum=0

# finally, we introduce a variable which remembers if we are inside a
# paragraph tag and tells us whether we need to open or close one.

inpara=0

################################################################################



# Now start reading the file line by line

while read -r line
do
    ################################################################################
    ##
    ## ACT 1 - Metadata extraction
    ##
    if [[ $stagenum -eq 1 ]]
    then
	# When we get to the beginning of the document
	# we move to the second stage
       	if echo $line | grep -q \\\\begin\{document\};
	then
	    printf "Moving to stage 2...\n" ## >>>>>>>> Go to stage 2.....
	    ((stagenum++))
	    continue
	elif echo $line | grep -q \\\\title;  ## We make a note of the title
	then
	    title=$(echo "$line" | sed 's|.*title{\(.*\)}$|\1|')
	elif echo $line | grep -q \\\\author; ## We make a note of the author
	then
	    ## We also increase the author count...
	    author[$authornum]=$(echo $line | sed 's|.*author{\(.*\)}$|\1|')
	    ## ...and fill in their email addresses with a dummy for now
	    email[$authornum]="nomail"
	    ((authornum++))
	elif echo $line | grep -q \\\\email;  ## We make note of each author's email
	then
	    email[$((authornum-1))]=$(echo $line | sed 's|.*email{\(.*\)}$|\1|')
	elif echo $line | grep -q '%@'; ## We keep track of links
	then
	    ## Links to other interesting/relevant fieldnotes
	    ## are delimited by %@ in the head of the texml source
	    link[$linknum]=$(echo $line | sed 's|^%@\(.*\)$|\1|')
	    ((linknum++))
	elif echo $line | grep -q '%#';  ## We keep track of tags
	then
	    ## Tags are delimited by %# in the head of the texml source
	    tag[$tagnum]=$(echo $line | sed 's|^%#\(.*\)$|\1|')
	    ((tagnum++))
	fi
	##
	##
	################################################################################
	##
	## ACT 2 - Writing metadata to XML file
	##
    elif [[ $stagenum -eq 2 ]]
    then
	##
	## We start writing metadata to XML, starting with generic
	## information like creation date, last modified
	##
	cat > $outfile <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="../auxil/mfno.xsl"?>

<card title="$title" created="$created" date="$lastmod" type="tex">
<metadata>
<authors>
EOF
	##
	## Then we move on to list the authors...
	##
	for ((x=0; x<$authornum; x++))
	do
	    printf "<author name=\"${author[$x]}\" email=\"${email[$x]}\"/>\n" >> $outfile
	done
	printf "</authors>\n<links>\n" >> $outfile
	##
	## ...the links...
	##
	for ((x=0; x<$linknum; x++))
	do
	    printf "<link href=\"${link[$x]}\"/>\n" >> $outfile
	done
	printf "</links>\n<tags>\n" >> $outfile
	##
	## ...the tags...
	##
	for ((x=0; x<$tagnum; x++))
	do
	    printf "<tag name=\"${tag[$x]}\"/>\n" >> $outfile
	done
	printf "</tags>\n</metadata>\n<bod>\n" >> $outfile
	##
	## We close the metadata region of the XML file and move
	## on to the next stage
	##
	printf "Moving to stage 3...\n" ### >>>>>>>> Go to stage 3.....
	((stagenum++))
	##
	##
	################################################################################
	##
	## ACT 3 - Extract content and write to XML
	##
    elif [ $stagenum -eq 3 ]
    then
	##
	## If we have reached the end of the document,
	##
	if echo $line | grep -q \\\\end{document};
	then
	    ##
	    ## check if we need to close a paragraph tag
	    ##
	    if [[ $inpara -eq 1 ]]
	    then
		echo "</p>" >> $outfile
		((inpara--))
	    fi
	    ##
	    ## and move immediately to the next stage
	    ##
	    printf "Moving to stage 4...\n" ### >>>>>>>> Go to stage 4.....
	    ((stagenum++))
	    break
	    ##########
	elif echo $line | grep -q \\\\section; ## Are we starting a new section?
	then
	    sectionname=$(echo $line | sed 's|^.*section{\(.*\)}$|\1|')
	    ##
	    ## Do we need to close the previous paragraph or section?
	    ##
	    if [[ $inpara -eq 1 ]]
	    then
		echo "</p>" >> $outfile
		((inpara--))
	    fi
	    if [[ ! $sectionnum -eq 0 ]]
	    then
		echo "</section>" >> $outfile
	    fi
	    ## Restart item numbering,
	    ((itemnum=1))
	    ## move on the section counter to the current one and
	    ((sectionnum++))
	    ## write to XML
	    echo "<section num=\"$sectionnum\" name=\"$sectionname\">" >> $outfile
	    ######################
	elif echo $line | grep -q \\\\begin; ## Are we starting something with a \begin?
	then
	    ##
	    ## Figure out what kind of environment we are beginning
	    ## store the answer as $targ
	    ##
	    
	    targ=$(echo $line | sed 's|^.*begin{\(.*\)}.*$|\1|')

	    ##
	    ## If we're NOT starting an equation-type environment
	    ## like array/align/gather/cases, we need to figure out
	    ## if we're already inside a paragraph <p> tag or not.
	    ## If we are, we should close it.
	    ##
	    if echo "$targ" | grep -vq 'array\|align\|gather\|cases';
	    then
		if [[ $inpara -eq 1 ]]
		then
		    echo "</p>" >> $outfile
		    ((inpara--))
		fi
	    fi
	    ##
	    ## Now there are several possible things we could be
	    ## \beginning.
	    ##
	    ## (1) \begin{array}, \begin{align*}, etc. (inside an equation)
	    ## (2) \begin{proof},
	    ## (3) \begin{ans},
	    ## (4) \begin{Lemma}, \begin{Theorem}, etc.
	    ##
	    
	    if echo "$targ" | grep -q 'array\|align\|gather\|cases';
	    then
		##
		## (1) In this case, we just want to transcribe the \begin
		##     verbatim into the XML.
		##
		echo $line >> $outfile
	    elif echo "$targ" | grep -q proof;
	    then
		##
		## (2) In this case, we need to create a proof environment
	       	##

		 prfnum=$((itemnum-1))
		 output="<proof vis=\"off\" id=\"prf"$sectionnum"item"$prfnum"\">"
		 echo $output >> $outfile
	    elif echo "$targ" | grep ans;
	    then
		##
		## (3) In this case, we need to create an ans environment
	       	##
		
		ansnum=$((itemnum-1))
		output="<ans vis=\"off\" id=\"ans"$sectionnum"item"$ansnum"\">" >> $outfile
		echo $output >> $outfile
	    else
		##
		## (4) We need to create an appropriate environment
		##     and label it appropriately.
		##
		## We test to see if there's a label;
		## note: the \[ inside the grep is an escaped [
		##
		if echo $line | grep -q "\[";
		then
		    ##
		    ## If so, we extract whatever's between the [...]s
		    ## with the help of sed...
		    ##
		    ref=$(echo $line | sed 's|^.*\[\([^]]*\)\]$|\1|')
		    ##
		    ## ...and we open an <env> tag with this as its id...
		    ##
		    output="<env type=\""$targ"\" id=\""$ref"\" sectionnum=\""$sectionnum"\" itemnum=\""$itemnum"\">"
		    ##
		    ## ...and we write it to XML
		    ##
		    echo $output >> $outfile
		else
		    ##
		    ## If there's no label [...] after the \begin,
		    ## we just use make up an id on the fly.
		    ##
		    output="<env type=\""$targ"\" id=\"section"$sectionnum"item"$itemnum"\" sectionnum=\""$sectionnum"\" itemnum=\""$itemnum"\">"
		    echo $output >> $outfile
		fi
		##
		## We increase the itemnum counter to register
		## the fact that we now have a new <env>.
		##
		((itemnum++))
	    fi
	    #########################
	elif echo $line | grep -q \\\\end; ## Now we look for \ends
	then
	    ##
	    ## If we have an \end marker...
	    ## figure out what kind of environment we are closing
	    ## and store it in $targ
	    ##
	    targ=$(echo $line | sed 's|^.*end{\(.*\)}.*$|\1|')
	    ##
	    ## Figure out if we need to close a p tag;
	    ## again, this only matters if we're NOT closing an equation
	    ## environment like array and if we're NOT already inside a
	    ## paragraph.
	    ##
	    if echo "$targ" | grep -vq 'array\|align\|gather\|cases';
	    then
		if [[ $inpara -eq 1 ]]
		then
		    echo "</p>" >> $outfile
		    ((inpara--))
		fi
	    fi
	    ##
	    ## As with \begins, there are several cases:
	    ##
	    ## (1) \end{array}, \end{align*}, etc. (inside an equation)
	    ## (2) \end{proof},
	    ## (3) \end{ans},
	    ## (4) \end{Lemma}, \end{Theorem}, etc.
	    ##
	    if echo "$targ" | grep -q 'array\|align\|gather\|cases';
	    then
		##
		## (1) In this case, we just want to transcribe the \begin
		##     verbatim into the XML.
		##
		echo $line >> $outfile
	    elif echo "$targ" | grep -q proof ;
	    then
		##
		## (2) In this case, we just want to close the ,proof> tag.
		##
		echo "</proof>" >> $outfile
	    elif echo "$targ" | grep ans;
	    then
		##
		## (3) In this case, we just want to close the <ans> tag.
		##
		echo "</ans>" >> $outfile
	    else
		##
		## (4) In this case, we just want to close the <env> tag.
		##
		echo "</env>" >> $outfile
	    fi
	else
	    ##
	    ## Finally if we just have text, then create a text node:
	    ##
	    ## (1) If we're inside a p tag and the line being read is empty,
	    ## close the p tag and set inpara to zero
	    ##
	    if [[ $inpara -eq 1 && -z $line ]]
	    then
		echo "</p>" >> $outfile
		((inpara--))
	    fi
	    ##
	    ## (2) If it's not contained in a p tag and it's nonempty, create one
	    ##
	    if [[ $inpara -eq 0 && ! -z $line ]]
	    then
		echo "<p>" >> $outfile
		((inpara++))
	    fi
	    ##
	    ## Go through and change all
	    ## {\em ...} or {\bf ...}s to <i>s and <b>s
	    ##
	    linemod=$(echo $line | sed 's|{\\em\([^}]*\)}|<i>\1</i>|g' | sed 's|{\\bf\([^}]*\)}|<b>\1</b>|g')
	    echo $linemod >> $outfile
	fi
    fi	 
done < $tmp
## 
## Note that we use "done < $tmp" in this last line:
## don't forget, we're now writing from the modified temporary file
## with all XML-poison removed (<,>,&)
##
##
################################################################################
##
## ACT 4 - Close all XML tags
##
## If necessary we need to close the last section...
##
if [[ ! $sectionnum -eq 0 ]]
then
    printf "</section>" >> $outfile
fi
## ...and then all remaining tags
cat >> $outfile <<EOF
</bod>
</card>
EOF
