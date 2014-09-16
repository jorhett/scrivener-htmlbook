#!/bin/bash
SCRIPT_DIR=$(dirname $0)
SCRIVENER_OUTPUT=$1

# Split the scrivener output into chapters
${SCRIPT_DIR}/splitHTMLBook.pl $SCRIVENER_OUTPUT 
splitstatus=$?
if [ $splitstatus -ne 0 ]; then
    echo "Last status was $splitstatus"
    exit $splitstatus
fi 
