#!/bin/bash
SCRIPT_DIR=$(dirname $0)
SCRIVENER_OUTPUT=$1
PARAS_ADDED=$1.parsed
CLEANED=$1.cleaned
XMLLINT=$1.xmllint

# mark paragraphs
echo "Finding paragraphs and wrapping them in <p> tags:"
${SCRIPT_DIR}/markParagraphs.pl $SCRIVENER_OUTPUT $PARAS_ADDED
echo ""

# close sections and fix heading IDs
echo "Closing sections and fixing ID labels:"
${SCRIPT_DIR}/closeSections.pl $PARAS_ADDED $CLEANED
echo ""

# Now run tidy to see what's wrong
if [ ! -d ${SCRIPT_DIR}/HTMLBook ]
then
    echo "Getting HTMLBook repo for schema validation"
    git clone https://github.com/oreillymedia/HTMLBook.git ${SCRIPT_DIR}/HTMLBook
fi
echo "Running xmllint to analyze the output... (please wait)"
${SCRIPT_DIR}/makeComplete.sh $CLEANED > $XMLLINT
xmllint --noout --schema ${SCRIPT_DIR}/HTMLBook/schema/htmlbook.xsd $XMLLINT
if [ $? -gt 1 ]; then
    echo ""
    echo "WARNING: Validation errors were found. Fix problems and re-run process.sh."
fi

# Split the scrivener output into chapters
${SCRIPT_DIR}/splitHTMLBook.pl $CLEANED 
splitstatus=$?
if [ $splitstatus -ne 0 ]; then
    echo "Last status was $splitstatus"
    exit $splitstatus
fi 
rm $PARAS_ADDED
