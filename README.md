# XParse

A shell script library for parsing and executing functions based on xorriso's argument style.

## Examples:
```sh
xparse_add_option hello 0 do_hello
#   makes an option '-hello' that takes 0 args and runs do_hello

xparse_add_option print 1 do_print
#   makes an option '-print' that takes 1 arg and runs do_print with it

xparse_add_option add '*' do_add
#   makes an option '-add' that takes an arbitrary number of arguments up
#   until the separator in $XPARSE_SEPARATOR and runs do_add with them
#   (can be changed by user with '-list_delimiter')
```
