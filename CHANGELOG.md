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
