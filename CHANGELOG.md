## 0.1.0 (2015-11-01)
* First test release with support for Mac OS X

## 0.2.0 (2015-11-01)
* Added support for Windows

## 0.3.0 (2015-11-02)
* Added the whitelist for functions and procedures
* Added support for Linux

## 0.4.0 (2015-11-03)
* Level 1 and Level 2 do not point to the same parser anymore
* Level 4 now correctly forwards Ruby code to the interpreter without parsing it
* The statement `$stdout.sync = true` is now implicitly added to every Ruby program to preserve the correct input/output order

## 0.4.1 (2015-11-04)
* Replaced the 64-bit executable for Windows with a 32-bit one for compatibility reasons

## 0.5.0 (2015-11-05)
* (Hopefully) fixed the compatibility problems with the darwin executable
* Fixed a bug that caused the configuration settings to be unset when updating the package
* The language settings have been simplified in that it's only possible to choose the path to the directory that contains the `ruby` command (the level code file type setting has been removed)
* Increased stability and consistency of the interaction with the Levels package

## 0.5.2 (2016-06-29)
* Executable now supports the -d flag for debugging purposes used with the levels-debugger-ruby package
* config.json now includes an "options" object for each level
* Sources have been restructured for a simpler build process