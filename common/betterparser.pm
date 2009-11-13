##############################################################################
# $Id$
##############################################################################

package BetterParser;

use strict;
use FileHandle;
use File::Basename;
use POSIX qw(strftime);

##############################################################################
# Constructor
#
sub new
{
  my $proto = shift;
  my $class = ref ($proto) || $proto;
  my $self = {};

  bless ($self, $class);
  return $self;
}

###############################################################################
# ParseQuotes
# This parses double quoted strings removing the whole string from the input
# stream and returning this string (less the surrounding quotes) with any
# escape sequences within the string expanded.
#
sub ParseQuotes (\$)
{
  my ($inputString) = @_;

  # Split off the quoted string from the front of the inputString, NOTE
  # we can't capture the matching string due to the complex nesting search
  # pattern, so we have to store the before value and remove what's left
  # from this.
  #
  my $outputString= $$inputString;
  if ($$inputString !~
      s/^(?:"(?:[^"\\]*(?:\\(?:0?[xX][[:xdigit:]]{0,2}|0[0-2]?[0-7]{0,2}|.))*)*")*//) {
    print STDERR "INTERNAL ERROR: ParseQuotes didn't match quoted string\n";

    # If this occures, it will be due to the original <open..end> tag search
    # failing to match the same pattern, i.e. the two patterns are out-of-
    # sync with each other.

    exit 0;
  }
  my $lengthToRemove= -length ($$inputString);
  if ($lengthToRemove < 0) {
    $outputString = substr ($outputString, 0, $lengthToRemove);
  }
  $$inputString =~ s/^\s+//; ## Remove any leading space in remaining string.

  # Remove the surrounding quotes. Then replace any non-escaped double quoted
  # sequence with a single escaped quote sequence. i.e. "hello ""simon"""
  # will become: hello \"simon\"
  #
  $outputString =~ s/^"(.*)"$/$1/;
  my $frontOfString= $outputString;  ## Save the original string
  while ($outputString =~ s/^(?:[^"\\]*(?:\\(?:0?[xX][[:xdigit:]]{0,2}|0[0-2]?[0-7]{0,2}|.))*)*""/\\"/) {
    $lengthToRemove= -length ($outputString);
    if ($lengthToRemove < 0) {
      $frontOfString = substr ($frontOfString, 0, $lengthToRemove);
    }
    $outputString = $frontOfString . $outputString;
    $frontOfString= $outputString;  ## Save the original string for next loop
  }

  # Now check though the string for any escaped character sequences and expand
  # them into their actual values
  #
  $frontOfString= '';
  while ($outputString =~ s/^([^\\]*)(?:\\(0?[xX][[:xdigit:]]{0,2}|0[0-2]?[0-7]{0,2}|.))//) {
     $frontOfString .= $1;       ## The string prior to any escaped sequence.
     my $escaped = $2;           ## What characters were actually escaped
     if ($escaped =~ m/^[xX]/) { ## Hex encoding of character.
       $escaped = chr (hex ($escaped));
     }
     elsif ($escaped =~ m/^0/) { ## Octal (or 0x hex) encoding of character
       $escaped = chr (oct ($escaped));
     }
     elsif ("n" eq $escaped) { ## New-Line wanted
       $escaped = "\n";
     }
     elsif ("b" eq $escaped) { ## Backspace
       $escaped = "\b";
     }
     elsif ("r" eq $escaped) { ## return
       $escaped = "\r";
     }
     elsif ("t" eq $escaped) { ## Tab
       $escaped = "\t";
     }
     elsif ("'" eq $escaped) { ## Single Quotes
       $escaped = "'";
     }
     elsif ("\"" eq $escaped) { ## Double Quotes
       $escaped = "\"";
     }
     elsif ("\\" eq $escaped) { ## Escape character itself
       $escaped = "\\";
     }
     else { ## Unknown, assume it wasn't meant to be escaped.
       $escaped = "\\$escaped";
     }

     # The above escape sequences can generate some characters that "options"
     # processing must still see as escaped, thus however we generated these
     # they must be re-encoded in a standard form for the various command
     # options to decode correctly.
     #
     if ("'" eq $escaped) { ## Single quotes
       $frontOfString .= "\\x27";  # Must not be \' as ' will still be seen
     }
     elsif ("\n" eq $escaped) { ## New-Line
       $frontOfString .= "\\n";
     }
     else { ## Just the character as processed above
       $frontOfString .= $escaped;
     }
  }
  return $frontOfString . $outputString;
}

###############################################################################
# ParseAttribute
# This splits up the attribute string into the first XML tag attribute and its
# value (if any) having removed these from the original inputString.
#
sub ParseAttribute (\$)
{
  my ($attributes) = @_;

  # Work on isolating the leading attribute name.
  #
  my $firstAttribute;
  if ($$attributes =~ s/^\s*"/"/) { ## Attribute is quoted, parse it
    $firstAttribute = ParseQuotes ($$attributes);
  }
  else { ## Attribute is normal word (or lack of it).
    $$attributes =~ s/^\s*([^\s="]*)//;
    $firstAttribute = $1;
  }
  
  # Now identify if there is a value, and if so isolate that.
  #
  my $value;
  if ($$attributes =~ s/^\s*=\s*"/"/) { ## value is quoted, parse it
    $value= ParseQuotes ($$attributes);
  }
  elsif ($$attributes =~ s/^\s*=\s*([^\s="]*)//) { ## value is unquoted
    $value = $1;
  }
  else { ## value is missing.
    $value= '';
  }

  # Remove any leading space in remaining string.
  #
  $$attributes =~ s/^\s+//;
  return ($firstAttribute, $value);
}

###############################################################################
# DisplayProblem
# This outputs a warning or error text with the filename and line numbers in a
# standard format.
#
my $lastFilename= '';
my $lastStart= 0;
my $lastEnd= 0;
sub DisplayProblem ($$$$$)
{
  my ($filename, $lineStart, $lineEnd, $type, $message) = @_;

  if ($lastFilename ne $filename  ||
      $lastStart    != $lineStart ||
      $lastEnd      != $lineEnd) {
    print STDERR "$type: $filename($lineStart";
    if ($lineStart != $lineEnd) {
      print STDERR "-$lineEnd";
    }
    print STDERR "):\n";
  }
  $lastFilename = $filename;
  $lastStart    = $lineStart;
  $lastEnd      = $lineEnd;
  print STDERR "  $message\n";
}

###############################################################################
# NoAttributesAllowed
# This outputs a warning if any attributes have been given.
#
sub NoAttributesAllowed ($$$$$)
{
  my ($filename, $lineStart, $lineEnd, $tag, $attributes) = @_;

  if ("" ne $attributes) {
    DisplayProblem (
      $filename,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Unknown Tag attributes <$tag $attributes>");
  }
}

###############################################################################
# ParseIfAttribute
# Works out if the string means true or false.
#
sub ParseIfAttribute ($$$$$$$;$)
{
  my ($file, $lineStart, $lineEnd,
      $tag, $thisAttrib, $thisValue,
      $processIF, $existingIF) = @_;

  if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Missing attribute value <$tag $thisAttrib=?>" );
  }
  elsif (defined $existingIF) {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Ignoring multiple <$tag $thisAttrib=\"$thisValue\">," .
        " using previous $thisAttrib=\"$existingIF\"");
  }
  else {
    $existingIF = $thisValue;
    $existingIF =~ s/^\s*(?:true|)\s*$/1/i;
    if ($processIF) {
      $existingIF =
        main::subsituteVars ($existingIF, $file, $lineStart, $lineEnd);
      if ($existingIF !~ s/^\s*(?:true|)\s*$/1/i) {
        chomp ($existingIF = eval ($existingIF));
        $existingIF = 0 if (!defined $existingIF ||
                            $existingIF !~ s/^\s*(.+?)\s*$/$1/);
      }
    }
  }
  
  return $existingIF;
}

###############################################################################
# OnlyIfAttributeAllowed
# This outputs a warning if any attributes have been given other than if which
# must have a value. It returns the evaluated if value found.
#
sub OnlyIfAttributeAllowed ($$$$$$)
{
  my ($filename, $lineStart, $lineEnd, $tag, $attributes, $allowIF) = @_;
  my $IF_TEXT;

  while ($attributes) {
    my ($thisAttribute, $thisValue) = ParseAttribute ( $attributes );
    if ($thisAttribute =~ m/^if$/i) {
      $IF_TEXT =
        ParseIfAttribute (
          $filename,
          $lineStart,
          $lineEnd,
          $tag,
          $thisAttribute,
          $thisValue,
          $allowIF,
          $IF_TEXT );
    }
    else {
      DisplayProblem (
        $filename,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "tag attribute <$tag $thisAttribute> is unknown" );
    }
  } ## end of parsing all attributes

  return (!$allowIF ? 0 : (defined $IF_TEXT ? $IF_TEXT : 1));
}

###############################################################################
# ShouldBeSelfClosedTag
# This outputs a warning if the tag is NOT self-closed.
#
sub ShouldBeSelfClosedTag ($$$$\$)
{
  my ($filename, $lineStart, $lineEnd, $tag, $attributes) = @_;

  if ($$attributes !~ s!\s*/$!!) {
    DisplayProblem (
      $filename,
      $lineStart,
      $lineEnd,
      "WARNING",
      "Should be a self-closed tag <$tag $$attributes />" );
  }
}

###############################################################################
# NeverSelfClosedTag
# This outputs a warning if the tag IS self-closed.
#
sub NeverSelfClosedTag ($$$$\$)
{
  my ($filename, $lineStart, $lineEnd, $tag, $attributes) = @_;

  if ($$attributes =~ s!\s*/$!!) {
    DisplayProblem (
      $filename,
      $lineStart,
      $lineEnd,
      "WARNING",
      "Should NOT be a self-closed tag <$tag $$attributes />" );
  }
}

###############################################################################

my $nestedLevel = 0;
my $state = '';
my $IF_autobuild = 1;
my $IF_configuration = 1;

###############################################################################
# DealWithInclude
# Deals with any <include> tag.
#
sub DealWithInclude ($$$$$\%$)
{
  my ($self, $filename, $lineStart,
      $lineEnd, $oldState, $data, $attributes) = @_;
  
  my $includeOK = 1;
  my $includeFile = '';
  my $includeIf;
  while ($attributes) {
    my ($thisAttribute, $thisValue) = ParseAttribute ( $attributes );
    #-------------------------------------------------------------------------
    if ($thisAttribute =~ m/^if$/i) {
      $includeIf =
        ParseIfAttribute (
          $filename,
          $lineStart,
          $lineEnd,
          "include",
          $thisAttribute,
          $thisValue,
          ($IF_autobuild && $IF_configuration),
          $includeIf );
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttribute =~ m/^(?:file)?(?:name|path)?$/i) {
      if ($thisValue =~ s/^\s*([^\s]+)\s*/$1/) {
        if ("" eq $includeFile) {
          $includeFile = $thisValue;
        }
        elsif ("" eq $thisAttribute) {
          DisplayProblem (
            $filename,
            $lineStart,
            $lineEnd,
            "IGNORING",
            "Unknown value <include =\"$thisValue\">" );
        }
        else {
          DisplayProblem (
            $filename,
            $lineStart,
            $lineEnd,
            "WARNING",
            "tag <include $thisAttribute=\"$thisValue\"> ".
              "already has filename \"$includeFile\"" );
        }
      }
      else {
        DisplayProblem (
          $filename,
          $lineStart,
          $lineEnd,
          "WARNING",
          "tag <include $thisAttribute> requires a filename/path value" );
      }
    }
    #-------------------------------------------------------------------------
    elsif ("" eq $includeFile && "" ne $thisAttribute && "" eq $thisValue) {
      # We assume the unknown attribute is actually the filename to include
      #
      $includeFile = $thisAttribute;
    }
    else {
      DisplayProblem (
        $filename,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Unknown attribute <include $thisAttribute" .
          (("" eq $thisValue) ? ">" : "=\"$thisValue\">") );
    }
  } ## end of parsing all attributes

  if ("" eq $includeFile) {
    DisplayProblem (
      $filename,
      $lineStart,
      $lineEnd,
      "WARNING",
      "tag <include> requires a filename/path value" );
  }
  elsif ($IF_autobuild &&
         $IF_configuration &&
         (defined $includeIf ? $includeIf : 1)) {
    # Test for the file as is, and if not found try prefixing the path
    # from current file.
    #
    if (!-e $includeFile) {
      my $path= File::Spec->file_name_is_absolute ($filename) ?
                $filename : File::Spec->rel2abs ($filename);
      $path= File::Basename::dirname ($path);
      $includeFile = $path . $main::dirsep . $includeFile;
    }

    if (-e $includeFile) {
      # Process the included file (after saving the current state)
      #
      ++$nestedLevel;
      $includeOK = $self->Parse ($includeFile, $data);
      --$nestedLevel;
      my $nested_spaces = '  'x$nestedLevel;
      print "Back to: $nested_spaces$filename($lineEnd)\n" if ($main::verbose);
      $state = $oldState;
      $IF_autobuild = 1;
      $IF_configuration = 1;
    }
    else {
      DisplayProblem (
        $filename,
        $lineStart,
        $lineEnd,
        "ERROR",
        "Could not find include file \"$includeFile\"" );
      $includeOK = 0;
    }
  }
  return $includeOK;
}

###############################################################################
# FindNameTypeIF
# Scans through the attribute string and partitions up the attribute=value
# pairs removing any name, type and IF attribute(s) returning these values and
# the remaining pairs array. It also processes any "type" values returning them
# if found.
#
sub FindNameTypeIF ($$$$$$)
{
  my ($file, $lineStart, $lineEnd, $tag, $attributes, $allowIF) = @_;
  my @PAIRS= ();
  my $NAME= '';
  my $VALUE= '';
  my $TYPE;
  my $IF_TEXT;

  while ($attributes) {
    my ($thisAttrib, $thisValue) = ParseAttribute ($attributes);
    #-------------------------------------------------------------------------
    if ($thisAttrib =~ m/^name$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Missing attribute value <$tag $thisAttrib=?>" );
      }
      elsif ('' eq $NAME) {
        $NAME = $thisValue;
      }
      else {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Multiple names given <$tag $thisAttrib=\"$thisValue\">," .
          " using the first \"$NAME\"" );
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^type$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Missing attribute value <$tag $thisAttrib=?>" );
      }
      elsif (defined $TYPE) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Multiple types given <$tag $thisAttrib" .
            (("" eq $thisValue) ? "" : "=\"$thisValue\"") .
            ">, using the first \"$TYPE\"" .
            (("" eq $VALUE) ? "" : "=\"$VALUE\"") );
      }
      elsif ($thisValue =~
        m/^(?:default(?:_(?:only|value)?)?|ifundefined|replace|prefix|postfix|suffix|(?:un)?set|delete|remove)$/i) {
        $TYPE = $thisValue;
      }
      else {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Unknown type <$tag $thisAttrib=$thisValue>" );
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~
      m/^(default(?:_(?:only|value)?)?|ifundefined|replace|prefix|postfix|suffix|(?:un)?set|delete|remove)$/i) {
      if (!defined $TYPE) {
        $TYPE = $thisAttrib;
        if ($TYPE !~ m/^(?:unset|delete|remove)$/i) {
          $VALUE= $thisValue;
        }
        elsif ("" ne $thisValue) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "IGNORING",
            "Ignoring value for <$tag $thisAttrib=\"$thisValue\">");
        }
      }
      else {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Multiple types given <$tag $thisAttrib" .
            (("" eq $thisValue) ? "" : "=\"$thisValue\"") .
            ">, using the first \"$TYPE\"" .
            (("" eq $VALUE) ? "" : "=\"$VALUE\"") );
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^if$/i) {
      $IF_TEXT =
        ParseIfAttribute (
          $file,
          $lineStart,
          $lineEnd,
          $tag,
          $thisAttrib,
          $thisValue,
          $allowIF,
          $IF_TEXT );
    }
    #-------------------------------------------------------------------------
    else {
      my @thisPAIR = ($thisAttrib, $thisValue);
      push @PAIRS, \@thisPAIR;
    }
  } # dealt with all attributes

  $TYPE= "replace" if (!defined $TYPE);
  $IF_TEXT= 0 if (!$allowIF);
  $IF_TEXT= 1 if (!defined $IF_TEXT);

  return \@PAIRS, $NAME, $TYPE, $VALUE, $IF_TEXT;
}

###############################################################################
# DealWithVariableTagAttributes
# Deals with <configuration> section <variable> & <environment> tag attributes.
#
sub DealWithVariableTagAttributes ($$$$$\%$)
{
  my ($file, $lineStart, $lineEnd, $tag, $attributes, $data, $allowGroups) = @_;

  ShouldBeSelfClosedTag ($file, $lineStart, $lineEnd, $tag, $attributes);
  my ($PAIRS, $NAME, $TYPE, $VALUE, $IF_TEXT) =
    FindNameTypeIF (
      $file,
      $lineStart,
      $lineEnd,
      $tag,
      $attributes,
      $IF_autobuild && $IF_configuration );
  my $JOIN= " ";
  my $SUBVARS = 2; # 0= Never, 1=Always, 2=Default
  my $EVAL= 0;
  my @GROUPS;
  $IF_TEXT = $IF_autobuild && $IF_configuration && $IF_TEXT;

  # Process the attributes for this variable definition.
  #
  while (scalar @$PAIRS) {
    my $thisPAIR = shift (@$PAIRS);
    my ($thisAttrib, $thisValue) = @$thisPAIR;

    #-------------------------------------------------------------------------
    if ($thisAttrib =~ m/^(?:(relative_)?val(?:ue)?)$/i) {
      # relative_value is an DEPRECATED prismtech form that implies this
      # value should have variables sustituted. To avoid missing variable
      # warnings this is only done if we are actually creating this variable.
      #
      if (defined $1 && $IF_TEXT) {
        $thisValue =
          main::subsituteVars ($thisValue, $file, $lineStart, $lineEnd);
      }

      if ('' eq $VALUE) {
        $VALUE = $thisValue;
      }
      else {
        $VALUE .= $JOIN . $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^var(?:iable)?$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "WARNING",
          "attribute <$tag $thisAttrib=?> should give a variable name" );
      }
      else {
        my $var_val= $data->{VARS}->{$thisValue};
        if (!defined $var_val) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Variable is undefined <$tag $thisAttrib=$thisValue>"
          ) if ($IF_TEXT);
        }
        elsif ('' eq $VALUE) {
          $VALUE = $var_val;
        }
        else {
          $VALUE .= $JOIN . $var_val;
        }
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^env(?:ironment)?(?:_var(?:iable)?)?$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "WARNING",
          "attribute <$tag $thisAttrib=?> should give an" .
          " environment variable name" );
      }
      else {
        my $env_val = $ENV{$thisValue};
        if (!defined $env_val) {
          # Note windows does not save any environment variable that has
          # a null value. Thus we can't complain about those we can't find,
          # because they could have been defined as null strings.
          #
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Environment Variable is undefined " .
            "<$tag $thisAttrib=$thisValue>" ) if ($IF_TEXT && $^O ne "MSWin32");
        }
        elsif ('' eq $VALUE) {
          $VALUE = $env_val;
        }
        else {
          $VALUE .= $JOIN . $env_val;
        }
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^join$/i) {
      if ($thisValue =~ m/^(?:dir(?:ectory)?|folder)$/i) {
        $JOIN = $main::dirsep;
      }
      elsif ($thisValue =~ m/^path$/i) {
        $JOIN = $main::pathsep;
      }
      else {
        $JOIN = $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^eval(?:uate)?$/i) {
      # Check for old prismtech meaning (=true) or new style (empty or no
      # string given) meaning that ALL of the resultant value must be evaluated
      # before being stored. (Note that we now do this AFTER we have susituted
      # any variables in this string AND only if we are actually creating this
      # variable.)
      #
      if ($IF_TEXT) {
        $thisValue=
          main::subsituteVars ($thisValue, $file, $lineStart, $lineEnd);
        if ($thisValue =~ m/^\s*(true|)\s*$/i) {
          $EVAL= 1;
        }
        else {
          # Otherwise the new meaning is assumed where the string given is
          # itself evaluated and the result of this is stored as the next part
          # of the resultant string being created.
          #
          chomp ($thisValue= eval ($thisValue));
          $thisValue = 0 if (!defined $thisValue || "" eq $thisValue);
          if ('' eq $VALUE) {
            $VALUE = $thisValue;
          }
          else {
            $VALUE .= $JOIN . $thisValue;
          }
        }
      } # IF_TEXT
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~
      m/^(?:(no)?subs(?:itute)?(?:_?var(?:iable)?s)?)$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        # This is a signal to globally subsitute variables within the whole
        # resultant value.
        #
        if (2 == $SUBVARS) {
          $SUBVARS = (defined $1) ? 0 : 1;
        }
        else {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "IGNORING",
            "Ignoring the multiple attribute $thisAttrib" );
        }
      }
      elsif (defined $1) { ## nosubsitute_variables="value" doesn't make sense
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "WARNING",
          "attribute <$tag $thisAttrib=\"$thisValue\">" .
          " should not have a value" );
      }
      elsif ($IF_TEXT) {
        # Subsitute_variables for just this given part, assuming we are
        # actually creating the variable.
        #
        $thisValue =
          main::subsituteVars ($thisValue, $file, $lineStart, $lineEnd);
        if ('' eq $VALUE) {
          $VALUE = $thisValue
        }
        else {
          $VALUE .= $JOIN . $thisValue;
        }
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^(?:env(?:ironment)?(?:_?))?group(?:s)?$/i) {
      if (!$allowGroups) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Unknown tag <$tag $thisAttrib" .
            (("" eq $thisValue) ? "" : "=\"$thisValue\"") . ">" );
      }
      elsif ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "tag <$tag $thisAttrib=?> should give group name(s)" );
      }
      elsif ($IF_TEXT) {
        foreach my $grp (split (/[\s,]/,$thisValue)) {
          if ("" ne $grp) {
            $grp = lc $grp;
            foreach my $alreadySeen (@GROUPS) {
              if ($alreadySeen eq $grp) {
                DisplayProblem (
                  $file,
                  $lineStart,
                  $lineEnd,
                  "WARNING",
                  "Same group given more than once <$tag $thisAttrib=$grp>" );
                $grp = "";
                last;
              }
            }
            if ("" ne $grp) {
              push @GROUPS, $grp;

              # If we have not seen this group name before, create a new hash
              # entry associated with this name that has a COPY of the original
              # environment.
              #
              if (!defined $data->{GROUPS}->{$grp}) {
                my %copyENV = %ENV;
                $data->{GROUPS}->{$grp} = \%copyENV;
                push @{$data->{UNUSED_GROUPS}}, $grp;
              }
            }
          }
        }
      }
    }
    #-------------------------------------------------------------------------
    # We have an unknown attribute and possiable value, treat this as
    # a command name with options, if we have not seen the name yet.
    #
    elsif ("" eq $NAME) {
      if ("" ne $thisAttrib) {
        $NAME = $thisAttrib;
        if ("" ne $thisValue) {
          if ('' eq $VALUE) {
            $VALUE = $thisValue;
          }
          else {
            $VALUE .= $JOIN . $thisValue;
          }
        }
      }
      else {
        $NAME = $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    # Since we have seen the name. Treat any unknown attribute (not
    # attribute values) as value.
    #
    elsif ("" eq $thisAttrib) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Unknown value <$tag =$thisValue>" );
    }
    #-------------------------------------------------------------------------
    elsif ("" ne $thisValue) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Unknown attribute <$tag $thisAttrib=$thisValue>" );
    }
    #-------------------------------------------------------------------------
    elsif ('' eq $VALUE) {
      $VALUE = $thisAttrib;
    }
    else {
      $VALUE .= $JOIN . $thisAttrib;
    }
  } ## end of attributes to process

  if ("" eq $NAME) {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "No name attribute given <$tag" .
        (("" eq $attributes) ? "" : " $attributes" ) .
        ">" );
    $IF_TEXT = 0;
  }
  elsif ("" ne $VALUE && $TYPE =~ m/^(?:unset|delete|remove)$/i) {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Ignoring value for <$tag name=\"$NAME\" value=\"$VALUE\" type=$TYPE>");
    $VALUE = '';
  }
  elsif ($IF_TEXT) {
    if (1 == $SUBVARS) {
      $VALUE = main::subsituteVars ($VALUE, $file, $lineStart, $lineEnd);
    }
    if ($EVAL) {
      $VALUE = 1 if ($VALUE =~ m/^\s*(true|)\s*$/i);
      chomp ($VALUE = eval ($VALUE));
      $VALUE = 0 if (!defined $VALUE || "" eq $VALUE);
    }
  }
  
  return ($IF_TEXT, $NAME, $TYPE, $VALUE, \@GROUPS);
}

###############################################################################
# DealWithConfigSection
# Deals with any <configuration> .. </configuration> section tag.
#
sub DealWithConfigSectionTags ($$$$$\%)
{
  my ($file, $lineStart, $lineEnd, $tag, $attributes, $data) = @_;
  my ($IF_TEXT, $NAME, $TYPE, $VALUE, $GROUPS);

  #---------------------------------------------------------------------------
  if ($tag =~ m/^var(?:iable)?$/i) {
    ($IF_TEXT, $NAME, $TYPE, $VALUE) =
      DealWithVariableTagAttributes (
        $file,
        $lineStart,
        $lineEnd,
        $tag,
        $attributes,
        %$data,
        0 );  ## Groups not allowed
    my $original= $data->{VARS}->{$NAME};
    if (!$IF_TEXT) {
      print "  Ignoring variable $NAME=\"$VALUE\"\n" if (1 < $main::verbose);
    }
    elsif (!defined $original || $TYPE =~ m/^(replace|set)$/i) {
      $data->{VARS}->{$NAME} = $VALUE;
      print "  ", (!defined $original ? "Created" : "Replaced"),
        " variable $NAME=\"$VALUE\"\n" if (1 < $main::verbose);
    }
    elsif ($TYPE =~ m/^(default(?:_(?:only|value)?)?|ifundefined)$/i) {
      if (1 < $main::verbose) {
        print "  Keeping" if (1 < $main::verbose);
        $VALUE= $original;
      }
      else {
        print "  Created" if (1 < $main::verbose);
      }
      print " variable $NAME=\"$VALUE\"\n" if (1 < $main::verbose);
    }
    elsif ($TYPE =~ m/^prefix$/i) {
      $VALUE .= $original;
      $data->{VARS}->{$NAME} = $VALUE;
      print "  Prefixed variable $NAME=\"$VALUE\"\n" if (1 < $main::verbose);
    }
    elsif ($TYPE =~ m/^(delete|unset|remove)$/i) {
      delete $data->{VARS}->{$NAME};
      print "  Deleted variable $NAME\n" if (1 < $main::verbose);
    }
    else { # postfix or suffix
      $VALUE= $original . $VALUE;
      $data->{VARS}->{$NAME} = $VALUE;
      print "  Suffixed variable $NAME=\"$VALUE\"\n" if (1 < $main::verbose);
    }
  }
  #---------------------------------------------------------------------------
  elsif ($tag =~ m/^env(?:ironment)?(?:_var(?:iable)?)?$/i) {
    ($IF_TEXT, $NAME, $TYPE, $VALUE, $GROUPS) =
      DealWithVariableTagAttributes (
        $file,
        $lineStart,
        $lineEnd,
        $tag,
        $attributes,
        %$data,
        1 ); ## Groups allowed
    if ($IF_TEXT) {
      my %ENV_VAR= (NAME   => $NAME,
                    VALUE  => $VALUE,
                    TYPE   => $TYPE,
                    GROUPS => $GROUPS);
      push @{$data->{ENVIRONMENT}}, \%ENV_VAR;
      print "  Storing " if (1 < $main::verbose);
    }
    else {
      print "  Ignored " if (1 < $main::verbose);
    }
    if (1 < $main::verbose) {
      print "Environment \"$NAME\"";
      print "=\"$VALUE\"" if ($TYPE !~ m/^(?:unset|delete|remove)$/i);
      print " type=\"$TYPE\"";
      print " group=\"", join(',',@$GROUPS), "\"" if (scalar @$GROUPS);
      print "\n";
    }
  }
  #---------------------------------------------------------------------------
  elsif ($tag =~ m/^relative_var?$/i) {
    ShouldBeSelfClosedTag ($file, $lineStart, $lineEnd, $tag, $attributes);
    if ($attributes !~
      m/^name\s*=\s*("[^"]*")\s+base_var\s*=\s*("[^"]*")\s+suffix_var\s*=\s*("[^"]*")(?:\s+join\s*=\s*("[^"]*"))?/i) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Miss-use of DECRECATED <$tag" .
          (("" eq $attributes) ? "" : " $attributes" ) .
          ">" );
    }
    else {
      my ($NAME, $BASE, $SUFF, $JOIN)= ($1, $2, $3, $4);
      $NAME = ParseQuotes ($NAME);
      $BASE = ParseQuotes ($BASE);
      $SUFF = ParseQuotes ($SUFF);
      $JOIN = ParseQuotes ($JOIN) if (defined $JOIN);
      my $PREFIX = $data->{VARS}->{$BASE};
      if (!defined $PREFIX) {
        $PREFIX = "";
        if ($IF_autobuild && $IF_configuration) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Undefined variable used in <$tag base_var=\"$BASE\">" );
        }
      }
      my $SUFFIX = $data->{VARS}->{$SUFF};
      if (!defined $SUFFIX) {
        $SUFFIX = "";
        if ($IF_autobuild && $IF_configuration) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Undefined variable used in <$tag suffix_var=\"$SUFF\">" );
        }
      }
      $VALUE = $PREFIX . (defined $JOIN ? $JOIN : "") . $SUFFIX;
      if ($IF_autobuild && $IF_configuration) {
        $data->{VARS}->{$NAME} = $VALUE;
      }
      if ($main::deprecated) {
        DisplayProblem ($file, $lineStart, $lineEnd, "DEPRECATED",
          "DEPRECATED tag <$tag name=$1 base_var=$2 suffix_var=$3" .
          (defined $JOIN ? " join=$4" : "") . " />" );
        print STDERR "  Should be replaced with <variable name=$1",
                     " variable=$2 join="
                     . (defined $JOIN ? $4 : "")
                     ." variable=$3 />\n";
      } elsif (1 < $main::verbose) {
        if ($IF_autobuild && $IF_configuration) {
          print "  Replaced";
        }
        else {
          print "  Ignoring";
        }
        print " Variable $NAME=\"$VALUE\"\n";
      }
    }
  }
  #---------------------------------------------------------------------------
  elsif ($tag =~ m/^relative_env$/i) {
    ShouldBeSelfClosedTag ($file, $lineStart, $lineEnd, $tag, $attributes);
    if ($attributes !~
      m/^name\s*=\s*("[^"]*")\s+base_var\s*=\s*("[^"]*")\s+suffix_var\s*=\s*("[^"]*")\s+join\s*=\s*("[^"]*")(?:\s+type\s*=\s*("[^"]*"))?/i) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Miss-use of DECRECATED <$tag" .
          (("" eq $attributes) ? "" : " $attributes" ) .
          ">" );
    }
    else {
      my ($NAME, $BASE, $SUFF, $JOIN, $TYPE)= ($1, $2, $3, $4, $5);
      $NAME = ParseQuotes ($NAME);
      $BASE = ParseQuotes ($BASE);
      $SUFF = ParseQuotes ($SUFF);
      $JOIN = ParseQuotes ($JOIN);
      $TYPE = ParseQuotes ($TYPE) if (defined $TYPE);
      my $PREFIX = $data->{VARS}->{$BASE};
      if (!defined $PREFIX) {
        $PREFIX = "";
        if ($IF_autobuild && $IF_configuration) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Undefined variable used in <$tag base_var=\"$BASE\">" );
        }
      }
      my $SUFFIX = $data->{VARS}->{$SUFF};
      if (!defined $SUFFIX) {
        $SUFFIX = "";
        if ($IF_autobuild && $IF_configuration) {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "WARNING",
            "Undefined variable used in <$tag suffix_var=\"$SUFF\">" );
        }
      }
      $VALUE= $PREFIX . $JOIN . $SUFFIX;
      if ($IF_autobuild && $IF_configuration) {
        my %value = (NAME  => $NAME,
                     VALUE => $VALUE,
                     TYPE  => (defined $TYPE ? $TYPE : 'replace'));
        push @{$data->{ENVIRONMENT}}, \%value;
      }
      if ($main::deprecated) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "DEPRECATED",
          "DEPRECATED tag <$tag name=$1 base_var=$2 suffix_var=$3 join=$4" .
            (defined $TYPE ? " type=$5" : "") . " />" );
        print STDERR "  Should be replaced with <environment name=$1",
                     " variable=$2 join=$4 variable=$3",
                     (defined $TYPE ? " type=$5" : ""), " />\n";
      } elsif (1 < $main::verbose) {
        if ($IF_autobuild && $IF_configuration) {
          print "  Storing";
        }
        else {
          print "  Ignored";
        }
        print " Environment $NAME=\"$VALUE\" TYPE=\"",
              (defined $TYPE ? $TYPE : 'replace'), "\"\n";
      }
    }
  }
  else {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Unknown '$state' tag <$tag" .
        (("" eq $attributes) ? "" : " $attributes" ) .
        ">" );
  }
}

###############################################################################
# FindNameIF
# Scans through the attribute string and partitions up the attribute=value
# pairs removing any name and if attribute(s) returning the name/if value and
# the remaining pairs array.
#
sub FindNameIF ($$$$$)
{
  my ($file, $lineStart, $lineEnd, $tag, $attributes) = @_;
  my $NAME= '';
  my $IF_TEXT;
  my @PAIRS= ();

  while ($attributes) {
    my ($thisAttrib, $thisValue) = ParseAttribute ($attributes);
    #-------------------------------------------------------------------------
    if ($thisAttrib =~ m/^if$/i) {
      $IF_TEXT =
        ParseIfAttribute (
          $file,
          $lineStart,
          $lineEnd,
          $tag,
          $thisAttrib,
          $thisValue,
          0, ## if processing is always defered until command execution
          $IF_TEXT );
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib !~ m/^name$/i) {
      my @thisPAIR = ($thisAttrib, $thisValue);
      push @PAIRS, \@thisPAIR;
    }
    #-------------------------------------------------------------------------
    elsif ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Missing attribute value <$tag $thisAttrib=?>" );
    }
    elsif ('' eq $NAME) {
      $NAME = $thisValue;
    }
    else {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Multiple names given <$tag $thisAttrib=\"$thisValue\">," .
          " using the first \"$NAME\"" );
    }
  } # dealt with all attributes

  $IF_TEXT= 1 if (!defined $IF_TEXT);
  return \@PAIRS, $NAME, $IF_TEXT;
}

###############################################################################
# DealWithCommandTag
# Deals with the <autobuild> section <command .. /> tags.
#
sub DealWithCommandTag ($$$$$\%)
{
  my ($file, $lineStart, $lineEnd, $tag, $attributes, $data) = @_;
  
  ShouldBeSelfClosedTag ($file, $lineStart, $lineEnd, $tag, $attributes);
  my ($PAIRS, $NAME, $IF_TEXT) =
    FindNameIF ($file, $lineStart, $lineEnd, $tag, $attributes);
  my $OPTIONS = '';
  my $DIRECTORY = '';
  my $JOIN = ' ';
  my $SUBVARS = 2; ## use default, if 0 don't subsitute, if 1 subsitute.
  my $GROUP;

  while (scalar @$PAIRS) {
    my $thisPAIR = shift (@$PAIRS);
    my ($thisAttrib, $thisValue) = @$thisPAIR;
    #-------------------------------------------------------------------------
    if ($thisAttrib =~ m/^(?:opt(?:ions)?)$/i) {
      if ('' eq $OPTIONS) {
        $OPTIONS = $thisValue;
      }
      else {
        $OPTIONS .= $JOIN . $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^(?:root|path|dir(?:ectory)?|folder)$/i) {
      if ('' eq $DIRECTORY) {
        $DIRECTORY = $thisValue;
      }
      else {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Ignoring the multiple $thisAttrib" .
             (("" eq $thisValue) ? "" : "=\"$thisValue\"" ) );
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^(?:env(?:ironment)?(?:_?))?group$/i) {
      if ($thisValue !~ s/^\s*([^\s]*)\s*/$1/) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "tag <$tag $thisAttrib=?> should give group name" );
      }
      elsif (defined $GROUP) {
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Ignoring the multiple <$tag $thisAttrib=\"$thisValue\">" .
            " using the first \"$GROUP\"" );
      }
      else {
        $thisValue = lc $thisValue;
        if (defined $data->{GROUPS}->{$thisValue}) {
          $GROUP = $thisValue;
          foreach my $entry (0 .. $#{$data->{UNUSED_GROUPS}}) {
            if ($data->{UNUSED_GROUPS}[$entry] eq $thisValue) {
              splice (@{$data->{UNUSED_GROUPS}}, $entry, 1);
              last;
            }
          }
        }
        else {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "IGNORING",
            "Undefined environment group <$tag $thisAttrib=\"$thisValue\">" );
        }
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~ m/^join$/i) {
      if ($thisValue =~ m/^(?:dir(?:ectory)?|folder)$/i) {
        $JOIN = $main::dirsep;
      }
      elsif ($thisValue =~ m/^path$/i) {
        $JOIN = $main::pathsep;
      }
      else {
        $JOIN = $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    elsif ($thisAttrib =~
      m/^(?:(no)?subs(?:itute)?(?:_?var(?:iable)?s)?)$/i) {
      if ($thisValue !~ s/^\s*(.+?)\s*$/$1/) {
        # This is a signal to globally subsitute variables within the whole
        # option string.
        #
        if (2 == $SUBVARS) {
          $SUBVARS = (defined $1) ? 0 : 1;
        }
        else {
          DisplayProblem (
            $file,
            $lineStart,
            $lineEnd,
            "IGNORING",
            "Ignoring the multiple attribute $thisAttrib" );
        }
      }
      elsif (defined $1) { ## nosubsitute_variables="value" doesn't make sense
        DisplayProblem (
          $file,
          $lineStart,
          $lineEnd,
          "IGNORING",
          "Attribute $thisAttrib does not take a value " .
            "<$tag $thisAttrib=\"$thisValue\">" );
      }
      elsif ($IF_autobuild) {
        # Subsitute_variables for just this given bit of the option string
        # We assume we are actually going to execute this command unless
        # the autobuild section tag is disabled.
        #
        $thisValue =
          main::subsituteVars ($thisValue, $file, $lineStart, $lineEnd);
        if ('' eq $OPTIONS) {
          $OPTIONS = $thisValue
        }
        else {
          $OPTIONS .= $JOIN . $thisValue;
        }
      }
    }
    #-------------------------------------------------------------------------
    # We have an unknown attribute and possiable value, treat this as a
    # command name with options, if we have not seen the name yet.
    #
    elsif ("" eq $NAME) {
      if ("" ne $thisAttrib) {
        $NAME = $thisAttrib;
        if ("" ne $thisValue) {
          if ('' eq $OPTIONS) {
            $OPTIONS = $thisValue;
          }
          else {
            $OPTIONS .= $JOIN . $thisValue;
          }
        }
      }
      else {
        $NAME = $thisValue;
      }
    }
    #-------------------------------------------------------------------------
    # Since we have seen the name. Treat any unknown attribute (not values)
    # as options.
    #
    elsif ("" eq $thisAttrib) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Unknown value <$tag =\"$thisValue\">" );
    }
    elsif ("" ne $thisValue) {
      DisplayProblem (
        $file,
        $lineStart,
        $lineEnd,
        "IGNORING",
        "Unknown attribute <$tag $thisAttrib=\"$thisValue\">" );
    }
    elsif ('' eq $OPTIONS) {
      $OPTIONS = $thisAttrib;
    }
    else {
      $OPTIONS .= $JOIN . $thisAttrib;
    }
  } # dealt with all attributes

  # Store any known autobuild section <command...> tag
  #
  if ('' eq $NAME) {
    DisplayProblem (
      $file,
      $lineStart,
      $lineEnd,
      "IGNORING",
      "Missing $tag name" );
  }
  elsif ($IF_autobuild) {
    # NOTE That we only store commands for execution if the autobuild section
    # they are in is active. WE DO NOT CHECK the commands IF attribute here,
    # this is checked at execution time.
    #
    my %value = (NAME      => $NAME,
                 OPTIONS   => $OPTIONS,
                 DIRECTORY => $DIRECTORY,
                 SUBVARS   => $SUBVARS,
                 GROUP     => $GROUP,
                 IF_TEXT   => (defined $IF_TEXT ? $IF_TEXT : 1),
                 FILE      => $file,
                 LINE_FROM => $lineStart,
                 LINE_TO   => $lineEnd
                );
    push @{$data->{COMMANDS}}, \%value;
  }

  # Since no group has been specified, this command will use "default"
  # make sure we mark this special group has having been used.
  #
  if (!defined $GROUP) {
    foreach my $entry (0 .. $#{$data->{UNUSED_GROUPS}}) {
      if ($data->{UNUSED_GROUPS}[$entry] eq "default") {
        splice (@{$data->{UNUSED_GROUPS}}, $entry, 1);
        last;
      }
    }
  }
}

###############################################################################
# Parse
# This attempts to find each of the XML tags within the file and process them.
#
sub Parse ($$\%)
{
  my ($self, $file, $data) = @_;

  my $parsedOK= 1;
  my $nested_spaces = '  'x$nestedLevel;
  print "Parsing: $nested_spaces$file\n" if ($main::verbose);
  $state = 'none';

  my $file_handle = new FileHandle ($file, 'r');
  if (!defined $file_handle) {
    print STDERR "ERROR: Could not open file <$file>: $!\n";
    return 0; ## effectivly $parsedOK= 0;
  }

  # Each file parsed updates the "date_string" variable for the timestamp of
  # the build.
  #
  my $date_string = strftime "%y%m%d", localtime;
  $data->{VARS}->{'date_string'} = $date_string;

  my $inputFromFile  = '';
  my $lineNumberCurrent = 0;    ## Will be incremented after each line is read
  my $lineNumberStartOfTag = 0; ## Line zero indicates not found yet.
  my $lineNumberEndOfTag = 1;   ## Shows where the last processed tag ended

  # This while loop reads each line of the file into $_ one by one until EOF.
  #
  while (<$file_handle>) {
    ++$lineNumberCurrent;

    # Remove leading and trailing spaces from the current line just read in,
    # and if now blank read in another to replace it.
    #
    next if ($_ !~ s/^\s*(.+?)\s*$/$1/);

    # Keep appending each new line to the line(s) we are currently processing;
    # this is kept as a single line seporated by a single space instead of
    # multiple whitespace and new-line marks.
    #
    $inputFromFile .= ' ' . $_;

    # Remove anything up to the start of the first < character as these are to
    # be ignored. (These are just noise within the input stream into which the
    # XML tags are placed.) NOTE that quotes do NOT hide the start of XML tags,
    # as these quotes could be used unballanced within the non-tag text.
    #
    $inputFromFile =~ s/^[^<]+//;
    next if ("" eq $inputFromFile);

    my $moreTagsLeftToProcess;
    do {
      # Deal with all of the tags one by one that are currently already fully
      # complete within $inputFromFile.
      #
      $moreTagsLeftToProcess = 0;  # False, until proven different

      #-----------------------------------------------------------------------
      # Is there a start of comment tag (<!-- -->)?
      #
      if ($inputFromFile =~ m/^<!--/) {
        # Yes, this starts a comment, record where this tag starts.
        #
        if (!$lineNumberStartOfTag) {
          $lineNumberStartOfTag = $lineNumberCurrent;
          $lineNumberEndOfTag   = $lineNumberCurrent;
        }

        # Can we also see the end of this tag? Since comments do not nest, we
        # simply scan forward until we can see the end of comment tag and
        # remove the lot (with any non-tag characters following).
        #
        if ($inputFromFile =~ s/^<!--.*-->[^<]*//) {
          # Yes, but do we have anything left following it to check?
          #
          $lineNumberStartOfTag = 0;
          $lineNumberEndOfTag = $lineNumberCurrent;
          $moreTagsLeftToProcess = ("" ne $inputFromFile);
          if (!$moreTagsLeftToProcess) {
            # Since there is nothing left on the current line, any problems
            # parsing future tags will start from the next line.
            #
            ++$lineNumberEndOfTag;
          }
        } ## End of comment seen.
      }
      #-----------------------------------------------------------------------
      # Is there a start of comment tag (<? ?>)?
      #
      elsif ($inputFromFile =~ m/^<\?/) {
        # Yes, this starts a comment, record where this tag starts.
        #
        if (!$lineNumberStartOfTag) {
          $lineNumberStartOfTag = $lineNumberCurrent;
          $lineNumberEndOfTag   = $lineNumberCurrent;
        }

        # Can we also see the end of this tag? Since comments do not nest, we
        # simply scan forward until we can see the end of comment tag and
        # remove the lot (with any non-tag characters following).
        #
        if ($inputFromFile =~ s/^<\?.*\?>[^<]*//) {
          # Yes, but do we have anything left following it to check?
          #
          $lineNumberStartOfTag = 0;
          $lineNumberEndOfTag = $lineNumberCurrent;
          $moreTagsLeftToProcess = ("" ne $inputFromFile);
          if (!$moreTagsLeftToProcess) {
            # Since there is nothing left on the current line, any problems
            # parsing future tags will start from the next line.
            #
            ++$lineNumberEndOfTag;
          }
        } ## End of comment seen.
      }
      #-----------------------------------------------------------------------
      # Not a comment tag, check for any other start tags.
      #
      elsif ($inputFromFile =~ m/^</) {
        # OK, we have found the start of a non-comment tag, record where this
        # tag starts.
        #
        if (!$lineNumberStartOfTag) {
          $lineNumberStartOfTag = $lineNumberCurrent;
          $lineNumberEndOfTag   = $lineNumberCurrent;
        }

        # Do we have a following closing tag (the >) for this opening tag we
        # have found? This is much more complex forward search, as we have to
        # ignore any quoted > we find along the way as the optional value
        # strings to any attributes for this tag may have this character
        # embedded. Quoted strings may be surrounded by "" pairs and it
        # is also complicated by the possiability that within these there can
        # be escaped quotes.
        #
        my $tag = $inputFromFile;  ## Trimmed down if the end of tag is found.
        if ($inputFromFile =~
            s/^<\s*(?:[^>"]*(?:"(?:[^"\\]*(?:\\(?:0?[xX][[:xdigit:]]{0,2}|0[0-2]?[0-7]{0,2}|.))*)*")*)*>//) {
          # OK, we have found a valid closing tag (the >) character. We need to
          # remove anything following the closing > from tag. (We can't just
          # capture the wanted string from the regular expression due to the
          # complex nesting above, but we know what remains and we saved the
          # original (we also can't use $_ here due to a perl bug/feature.)
          #
          my $lengthToRemove= -length ($inputFromFile);
          if ($lengthToRemove < 0) {
            $tag = substr ($tag, 0, $lengthToRemove);
          }
          $lineNumberEndOfTag = $lineNumberCurrent;

          # Remove the leading < (with any following spaces) and the final >
          # characters (with any leading spaces) from the tag, leaving just the
          # tag name and attributes, then split these up.
          #
          $tag =~ s/^<\s*(.*?)\s*>$/$1/;
          my $attributes = $tag;
          if ($tag =~ m/^"/) { ## Tag is quoted
            $tag = ParseQuotes ($attributes);
          }
          else {
            $attributes =~ s/^([^\s=]*)\s*//;
            $tag = $1;
          }

          # -------------------------------
          # deal with <include> tags
          # -------------------------------
          #
          if ($tag =~ m/^include$/i) {
            ShouldBeSelfClosedTag (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            $parsedOK= 0 if (!DealWithInclude (
              $self,
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $state,
              %$data,
              $attributes ));
          }
          # -------------------------------
          # deal with <configuration> tags
          # -------------------------------
          #
          elsif ($tag =~ m/^configuration$/i) {
            NeverSelfClosedTag (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            $IF_configuration =
              OnlyIfAttributeAllowed (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                $tag,
                $attributes,
                $IF_autobuild );
            if ($state =~ m/^autobuild$/i) {
              $state = $tag;
            }
            elsif ($state =~ m/^configuration$/i) {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing </configuration> tag");
            }
            elsif ($state =~ m/^none$/i) {
              $state = $tag;
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing <autobuild> tag");
            }
            else {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                "WARNING",
                "Unknown INTERNAL state '$state', resetting to 'none'\n" .#
                  "Ignored tag <$tag $attributes>" );
              $state = 'none';
              $IF_configuration = 1;
              $IF_autobuild = 1;
            }
          }
          # -------------------------------
          # deal with </configuration> tags
          # -------------------------------
          #
          elsif ($tag =~ m!^/configuration$!i) {
            NeverSelfClosedTag (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            NoAttributesAllowed (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            $IF_configuration = 1;
            if ($state =~ m/^configuration$/i) {
              $state = 'autobuild';
            }
            elsif ($state =~ m/^autobuild$/i) {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing <configuration> tag");
            }
            elsif ($state =~ m/^none$/i) {
              $state = 'autobuild';
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing <autobuild> and <configuration> tags");
            }
            else {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                "WARNING",
                "Unknown INTERNAL state '$state', resetting to 'none'\n" .
                  "Ignored tag <$tag $attributes>" );
              $state = 'none';
              $IF_autobuild = 1;
            }
          }
          # -------------------------------
          # deal with <autobuild> tags
          # -------------------------------
          #
          elsif ($tag =~ m/^autobuild$/i) {
            NeverSelfClosedTag (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            $IF_autobuild =
              OnlyIfAttributeAllowed (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                $tag,
                $attributes,
                1 );
            if ($state =~ m/^none$/i) {
              $state = $tag;
            }
            elsif ($state =~ m/^autobuild$/i) {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing </autobuild> tag");
            }
            elsif ($state =~ m/^configuration$/i) {
              $state = $tag;
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing </configuration> and </autobuild> tags");
              $IF_configuration = 1;
            }
            else {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                "WARNING",
                "Unknown INTERNAL state '$state', resetting to 'none'\n" .
                  "Ignored tag <$tag $attributes>" );
              $state = 'none';
              $IF_configuration = 1;
              $IF_autobuild = 1;
            }
          }
          # -------------------------------
          # deal with </autobuild> tags
          # -------------------------------
          #
          elsif ($tag =~ m!^/autobuild$!i) {
            NeverSelfClosedTag (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            NoAttributesAllowed (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes );
            $IF_autobuild = 1;
            $IF_configuration = 1;
            if ($state =~ m/^autobuild$/i) {
              $state = 'none';
            }
            elsif ($state =~ m/^configuration$/i) {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing </configuration> tag");
              $state = 'none';
            }
            elsif ($state =~ m/^none$/i) {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberStartOfTag, # missing tag is BEFORE start.
                "WARNING",
                "Missing <autobuild> tag");
              $state = 'none';
            }
            else {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                "WARNING",
                "Unknown INTERNAL state '$state', resetting to 'none'\n" .
                  "Ignored tag <$tag $attributes>" );
              $state = 'none';
            }
          }
          # -------------------------------
          # deal with state dependant tags
          # -------------------------------
          #
          elsif ($state =~ m/^configuration$/i) {
            #
            # --------------------------------------
            # deal with <configuration> section tags
            # --------------------------------------
            #
            DealWithConfigSectionTags (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              $tag,
              $attributes,
              %$data );
          }
          elsif ($state =~ m/^autobuild$/i) {
            #
            # -------------------------------------
            # deal with <autobuild> <command ... />
            # -------------------------------------
            #
            if ($tag =~ m/^command$/i) {
              DealWithCommandTag (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                $tag,
                $attributes,
                %$data );
            }
            else {
              DisplayProblem (
                $file,
                $lineNumberStartOfTag,
                $lineNumberEndOfTag,
                "IGNORING",
                "Unknown '$state' tag <$tag" .
                  (("" eq $attributes) ? "" : " $attributes" ) .
                  ">" );
            }
          }
          elsif ($state =~ m/^none$/i) {
            DisplayProblem (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              "IGNORING",
              "Unknown top-level tag <$tag" .
                (("" eq $attributes) ? "" : " $attributes")
                .">" );
          }
          else {
            DisplayProblem (
              $file,
              $lineNumberStartOfTag,
              $lineNumberEndOfTag,
              "WARNING",
              "Unknown INTERNAL state '$state', resetting to 'none'\n" .
                "Ignored tag <$tag $attributes>" );
            $state = 'none';
            $IF_configuration = 1;
            $IF_autobuild = 1;
            $parsedOK= 0;
          }

          # Update for the next tags starting point; remove anything up to the
          # start of the next < character as these are to be ignored as non-XML
          # tags.
          #
          $lineNumberStartOfTag = 0;
          $inputFromFile =~ s/^[^<]+//;
          $moreTagsLeftToProcess = ("" ne $inputFromFile);
          if (!$moreTagsLeftToProcess) {
            # Since there is nothing left on the current line, any problems
            # parsing future tags will start from the next line.
            #
            ++$lineNumberEndOfTag;
          }
        } # Found closing tag ">"
      } # Found start of tag "<" (not comment)
    } while ($moreTagsLeftToProcess);
  } # while lines left to read from file.

  # We have reached the end of the input file, if we have any XML left to
  # process the file was incomplete or truncated in someway, report the
  # problem.
  #
  if ("" ne $inputFromFile) {
    DisplayProblem (
      $file,
      $lineNumberStartOfTag,
      $lineNumberEndOfTag,
      "WARNING",
      "An XML tag or comment was not closed by the end of the file" );
      print STDERR "  $inputFromFile\n";
  }
  elsif ($state =~ m/^configuration$/i) {
    DisplayProblem (
      $file,
      $lineNumberStartOfTag,
      $lineNumberEndOfTag,
      "WARNING",
      "missing </configuration> </autobuild> tags" );
  }
  elsif ($state =~ m/^autobuild$/i) {
    DisplayProblem (
      $file,
      $lineNumberStartOfTag,
      $lineNumberEndOfTag,
      "WARNING",
      "missing </autobuild> tag" );
  }

  return $parsedOK;
}

1;
