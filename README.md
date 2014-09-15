scrivener-htmlbook
==================

A Scrivener compile format and some scripts to produce HTMLBook for O'Reilly publications.

## Reason for existing

I used these scripts when working on the Learning Puppet book for O'Reilly Media.

My favorite writing tool is Scrivener http://www.literatureandlatte.com/scrivener.php

I created a Scrivener compile format which set up chapter headings correctly with a link 
target above them as recommended. Then I wrote some scripts to process the output from 
Scrivener compile to make HTMLBook in the flavor that O'Reilly wanted.

## Requirements

* **MacPorts** http://www.macports.org/install.php

otherwise unknown as of yet

## How to Use

1. Install `HTMLBook.plist` in `~/Library/Application Support/Scrivener/CompileSettings/`
2. Install the remaining scripts anywhere you want
3. Run process.sh with the name of the Scrivener output file from within the target directory

```
$ cd /where/is/the/htmlbook/repo
$ /usr/local/scrivener-htmlbook/process.sh /scrivenings/MyBook.scriv
```

## Future Plans

1. Call a local atlas build optionally
2. Rewrite the atlas.json file dynamically.
3. Do git add on new files

I am willing to accept suggestions and patches should anyone get more
creative than I have been.
