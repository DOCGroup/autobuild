# This is the ruby code that determines whether a test has failed or not.
# The integrate scoreboard doesn't parse compile errors, that is only
# done by the regular scoreboard.

# Return true if the test succeeds, false if it fails!

def parse_test_line (line)
    if (line =~ /gethostbyname: getaddrinfo returned ERROR/ ||
        line =~ /==\d+==.*XML::XML_Error_Handler/) # valgrind stack trace
        return true
    end

    if (line =~ /Error/ || line =~ /ERROR/ ||
        line =~ /fatal/ || line =~ /FAILED/ || line =~ /FAIL:/ ||
        (line =~ /EXCEPTION/ && line !~ /NO_EXCEPTIONS/ && line !~ /DACE_HAS_EXCEPTIONS/) || line =~ /ACE_ASSERT/ ||
        line =~ /Assertion/ || line =~ /Mismatched free/ ||
        line =~ /are definitely lost in loss record/ ||
        line =~ /error while loading shared libraries/ ||
        line =~ /Compilation failed in require at/ ||
        line =~ /Invalid write of size/ ||
        line =~ /Invalid read of size/ ||
        line =~ /compilation aborted at/ ||
        line =~ /aborted due to compilation errors/ ||
        line =~ /exception resulted in call to terminate/ ||
        line =~ /terminate called after throwing an instance of/ ||
        line =~ /glibc detected/ ||
        line =~ /Segmentation fault/ ||
        line =~ /memPartFree: invalid block/ ||
        line =~ /memPartAlloc: block too big/ ||
        line =~ /ld error: error loading file/ ||
        line =~ /C interp: unable to open/ ||
        line =~ /symbol lookup error/ ||
        line =~ /Could not open/ ||
        line =~ /holds reference to undefined symbol/ ||
        line =~ /unknown symbol name/ ||
        line =~ /service name too long/ ||
        line =~ /Can't open perl script/ ||
        line =~ /Don't know how to make check/ ||
        line =~ /ThreadSanitizer:/ ||
        line =~ /AddressSanitizer:/ ||
        line =~ /pure virtual /i )
        return false
    else
        return true
    end
end

