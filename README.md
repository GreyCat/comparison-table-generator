This repository hosts a simple static HTML5 comparison table generator.
It gets the data from a hierarchy of directories (usually stored as a
git repository), formats it and outputs it as a website.

## Usage

    generate [options] <base-dir>

Reads input comparison table data from a hierarchy of directories
starting from *base-dir* (see below for the format notes) and saves
generated website to output directory (`out` by default).

The following options are supported:

    -t, --topics=FILE                Topic dictionary file
    -l, --lang=CODE                  Language to use in output
    -o, --out=DIR                    Output directory (default: out)
    -s, --style=DIR                  Style template directory (default: style)

## Input format

Comparison table data is stored in a pretty simple hierarchy of
directories.

Top level directory must include the a file named `topics` that contains
a sequence of topics to compare (topics would be represented as columns
in the generated table), one topic per line, two tab-separated fields:
*file name* and *human-readable name*. *File name* would be used to
locate files describing a relevant topic, while *human-readable name*
would be rendered as human-readable column title.

Example (`\t` represents a tab character):

    apple\tApples
    orange\tOranges
    plum\tPlums

Starting from top level directory, one should create a hierarchy of
directories that represent sections, sub-section, sub-sub-sections, etc,
and finally - a subdirectory for every row of table in a designated
level of sectioning. Every directory (including a top-level one) must
include file named `desc` with a single line of HTML that would be
rendered as either:

* a title of whole comparison (top-level directory)
* a title of section (if directory contains no than other directories)
* a title of row (if there are comparison data in this directory)

Deepest directories (that thus represent rows) should include the
following files (all these files are optional):

* table cell data - one file per topic being compared, files should be
  named as *file names* column, as described in `topic` file (for
  example: `apple`); files should include a relatively short piece of
  HTML that would be included in a relevant table cell during rendering
* source references - in files named *topic_file_name*`-ref`, where
  *topic_file_name* is the same *file name* as in data files (for
  example: `apple-ref`) - these should have one source reference URL per
  line and would be rendered with reference icons, one icon per URL

All of the mentioned above files can be localized: if you want to create
a database of comparison data in multiple languages, just place data in
several different languages in different files, appending
`-`*language_code* to file names, for example: `topic-en`, `topic-es`,
`topic-de`, `topic-ru` or `apple-ref-en`, `apple-ref-es`,
`apple-ref-de`, etc.

If both "plain" and "localized" files coexist (for example, `desc`,
`desc-en`, `desc-gr`), generator would try to use localized file in
currently selected language (see options above) first, then will try
generic unlocalized file and, if that also failed, treat this file as
missing.

## Example of input

* `topic-en` (as seen above)
* `desc-en` => "My favorite fruits comparison"
* `10-price/`
    * `desc-en` => "Price"
    * `desc-de` => "Preis"
    * `desc-fr` => "Prix"
    * `apple` => "1000 credits"
    * `orange` => "3500 credits"
    * `plum` => "800 credits"
* `20-physical-attributes/`
    * `desc-en` => "Physical attributes"
    * `10-color/`
        * `apple` => "Green"
        * `orange` => "Orange"
        * `plum` => "Blue"
    * `20-size/`
        * `apple` => "5-9 cm"
        * `apple-ref` => "http://en.wikipedia.org/wiki/Apple"
        * `plum` => "2-8 cm"
        * Note: `orange` is missing - it's okay, this cell would have "?"

## Projects that use this generator

* [Programming languages comparison](https://github.com/GreyCat/programming-languages-comparison)

## Licensing

Script itself is licensed under GPL v3 or any later version (see
`LICENSE-generate.txt`). This software includes parts of HTML5
Boilerplate project which uses distinct licensing information (see
`LICENSE-html5boilerplate.md`).
