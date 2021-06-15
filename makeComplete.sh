#!/bin/bash

# HTMLbook preamble
echo '<!DOCTYPE html>
<html xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.w3.org/1999/xhtml ../schema/htmlbook.xsd"
 xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>For XMLLint Analysis</title>
    <meta name="For XMLLint Analysis" content="text/html; charset=utf-8" />
</head>
<body data-type="book" class="book" id="htmlbook">
'

# Output the file
cat $1

# Close up
echo '</body></html>'
exit 0
