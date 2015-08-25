#!/bin/bash
SCRIPT_DIR=$(dirname $0)
SCRIVENER_OUTPUT=$1
PARAS_ADDED=$1.parsed
CLEANED=$1.cleaned

# mark paragraphs
${SCRIPT_DIR}/markParagraphs.pl $SCRIVENER_OUTPUT $PARAS_ADDED

# close sections and fix heading IDs
${SCRIPT_DIR}/closeSections.pl $PARAS_ADDED $CLEANED

# Now run tidy to see what's wrong
if [ ! -d ${SCRIPT_DIR}/HTMLBook ]
then
    echo "Getting HTMLBook repo for schema validation"
    git clone https://github.com/oreillymedia/HTMLBook.git ${SCRIPT_DIR}/HTMLBook
fi
${SCRIPT_DIR}/makeComplete.sh $CLEANED > for-xmllint-analysis.html
echo "Running xmllint to analyze the output... (please wait)"
echo xmllint --noout --schema ${SCRIPT_DIR}/HTMLBook/schema/htmlbook.xsd for-xmllint-analysis.html
xmllint --noout --schema ${SCRIPT_DIR}/HTMLBook/schema/htmlbook.xsd for-xmllint-analysis.html
echo "result was $?"
exit 0
if [ $? -gt 1 ]; then
    echo ""
    echo "FATAL: Errors were found. Fix problems and re-run process.sh."
    exit 1
fi

# Split the scrivener output into chapters
${SCRIPT_DIR}/splitHTMLBook.pl $CLEANED 
splitstatus=$?
if [ $splitstatus -ne 0 ]; then
    echo "Last status was $splitstatus"
    exit $splitstatus
fi 
rm $PARAS_ADDED
