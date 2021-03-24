# `cmake` Test

Tests the `cmake`, `cmake_cmd`, and `print_cmake_version` commands by running
`autobuild.pl test.xml` with the `cmake_command` variable set to
`fake_cmake.pl`.  It prints what was run to log files and the test compares
those files to the what it expects.

An autobuild log is used to test `print_cmake_version` to test that it's
printing the version, but it causes autobuild to put errors there, so it's
dumped if there's an error.
