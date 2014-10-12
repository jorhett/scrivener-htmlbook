scrivener-htmlbook
==================

A Scrivener compile format and some scripts to produce HTMLBook for O'Reilly publications.

## Reason for existing

I used these scripts when working on the Learning Puppet book for O'Reilly Media.

My favorite writing tool is Scrivener http://www.literatureandlatte.com/scrivener.php

I created a Scrivener compile format which formats chapter names and id tags correctly.
Then I wrote some scripts to process the output from Scrivener compile to make HTMLBook.

## Requirements

* Scrivener
* Git

## How to Structure the Book in Scrivener

Unfortunately I have to make a large number of assumptions for this to work. Here is what I have come up with.

1. Make all frontmatter, backmatter, and parts as text items at the top level
    see http://oreillymedia.github.io/HTMLBook/
1. If the book has parts, use a text item at the top level named "Part (something): Part-name" to begin the part
1. All chapters should be folders at the top level

It should look something like this...

I am completely open to patches or suggestions for better approaches.

## How to Use

1. Install `HTMLBook.plist` in `~/Library/Application Support/Scrivener/CompileSettings/`
1. Install the remaining scripts anywhere you want
1. Run process.sh with the name of the Scrivener output file from within the target directory

```
$ cd /where/is/the/htmlbook/repo
$ /usr/local/scrivener-htmlbook/process.sh /scrivenings/MyBook.txt
```

## Future Plans

1. Do git add on new files
2. Call a local atlas build optionally

I am willing to accept suggestions and patches should anyone get more creative than I have been.
