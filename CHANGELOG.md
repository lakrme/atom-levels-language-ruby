## 0.5.3 (2017-09-09)

* Updated the grammar file to use Atoms internal Ruby grammar

## 0.5.2 (2016-06-29)

* Updated the changelog to reflect the changes of the last release

## 0.5.1 (2016-06-28)

* The executables now support the `-d` flag for debugging purposes used by the `levels-debugger-ruby` package
* The `config.json` file now includes an `options` object for each level
* Sources have been restructured for a simpler build process

## 0.5.0 (2015-11-05)

* Hopefully fixed the compatibility problems with the darwin executable
* Fixed a bug that caused the configuration settings to be unset when updating the package
* The language settings have been simplified so that it is only possible to choose the path to the directory that contains the `ruby` command (the level code file type setting has been removed)
* Increased stability and consistency of the interaction with the `levels` package

## 0.4.1 (2015-11-04)

* Replaced the 64-bit executable for Windows with a 32-bit one for compatibility reasons

## 0.4.0 (2015-11-03)

* Level 1 and 2 do not point to the same parser anymore
* Level 4 now correctly forwards Ruby code to the interpreter without parsing it
* The statement `$stdout.sync = true` is now implicitly added to every Ruby program to preserve the correct input/output order

## 0.3.0 (2015-11-02)

* Added a whitelist for functions and procedures
* Added support for Linux

## 0.2.0 (2015-11-01)

* Added support for Windows

## 0.1.0 (2015-11-01)

* First test release with support for OS X