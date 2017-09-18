#! /bin/bash
set -e
echo "Build Documentation"
cd $TRAVIS_BUILD_DIR
if [[ "$DOCUMENTATION" == "TRUE" ]]; then
  #echo "Already some doc ?"
  #cd build && ls modules/doc
  echo "Generate"
  #cd build && make doc
  cd build && doxygen modules/doc/Doxyfile
  echo "Check"
  pwd
  ls ../modules
  ls ../modules/core/include/facekit/core
fi