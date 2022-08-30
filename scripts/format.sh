#!/bin/bash

# This script reformats source files using the clang-format utility.
# Set the list of source directories on the "for" line below.
#
# The file .clang-format in this directory specifies the formatting parameters.
#
# Files are changed in-place, so make sure you don't have anything open in an
# editor, and you may want to commit before formatting in case of awryness.
#
# Note that clang-format is not included with OS X or Xcode; you must
# install it yourself.  There are multiple ways to do this:
#
# - If you use Xcode, install the ClangFormat-Xcode plugin. See instructions at
#   <https://github.com/travisjeffery/ClangFormat-Xcode/>.
#   After installation, the executable can be found at
#   $HOME/Library/Application Support/Alcatraz/Plug-ins/ClangFormat/bin/clang-format.
#
# - Download an LLVM release from <http://llvm.org/releases/download.html>.
#   For OS X, use the pre-built binaries for "Darwin".
#
# - Build the LLVM tools from source. See the documentation at <http://llvm.org>.

# Set internal field separator to allow spaces in names
IFS=$'\n'


### Obj-C / C++

# Change this if your clang-format executable is somewhere else
CLANG_FORMAT="clang-format"

for FILE in $( find -E "lib" \
                        "QLabKitDemo" \
                        "QLabKitDemo-iOS" \
                        "QLabKitDemoTests" \
                        -regex ".*/.*(\.h|\.m|\.mm)" \
                        -not -regex "lib/F53OSC/.*" \
                        )
do
  echo "Formatting $FILE"
  $CLANG_FORMAT --verbose -i $FILE
done

### Swift

# Change this if your swiftformat executable is somewhere else
# https://github.com/nicklockwood/SwiftFormat
SWIFT_FORMAT="swiftformat"

for FILE in $( find -E "lib" \
                        "QLabKitDemo" \
                        "QLabKitDemo-iOS" \
                        "QLabKitDemoTests" \
                        -regex ".*/.*(\.swift)" \
                        -not -regex "lib/F53OSC/.*" \
                        )
do
  echo "Formatting $FILE"
  $SWIFT_FORMAT --verbose $FILE
done
