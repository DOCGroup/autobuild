# $Id$

# This is the ruby code that determines whether a test has failed or not.
# The integrate scoreboard doesn't parse compile errors, that is only
# done by the regular scoreboard. If you make changes to this file
# send an email to Johnny. We will work on making this a seperate
# function that is used by the scoreboard

def parse_test_line (line)
  if (line =~ /gethostbyname: getaddrinfo returned ERROR/)
    return true

  if (line =~ /Error/ || line =~ /ERROR/ ||
      line =~ /fatal/ || line =~ /FAILED/ ||
      line =~ /EXCEPTION/ || line =~ /ACE_ASSERT/ ||
        line =~ /Assertion/ || line =~ /Mismatched free/ ||
        line =~ /are definitely lost in loss record/ ||
        line =~ /Invalid write of size/ ||
        line =~ /Invalid read of size/ ||
        line =~ /aborted due to compilation errors/ ||
        line =~ /memPartFree: invalid block/ ||
        line =~ /memPartAlloc: block too big/ ||
        line =~ /ld error: error loading file/ ||
        line =~ /C interp: unable to open/ ||
        line =~ /unknown symbol name/ ||
        line =~ /pure virtual /i )
    return true
  else
    return false
end

