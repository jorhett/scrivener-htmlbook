#!/bin/bash
SCRIPT_DIR=$(dirname $0)
SCRIVENER_OUTPUT=$1
PARAS_ADDED=$1.parsed

# mark paragraphs
${SCRIPT_DIR}/markParagraphs.pl $SCRIVENER_OUTPUT $PARAS_ADDED

# Split the scrivener output into chapters
${SCRIPT_DIR}/splitHTMLBook.pl $PARAS_ADDED 
splitstatus=$?
if [ $splitstatus -ne 0 ]; then
    echo "Last status was $splitstatus"
    exit $splitstatus
fi 
rm $PARAS_ADDED
