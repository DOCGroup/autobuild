#!/bin/sh
echo "Test1" > /tmp/t1.txt
exec perl -w ./autobuild/autobuild.pl autobuild/configs/autobuild/doc/Doxygen.xml 

