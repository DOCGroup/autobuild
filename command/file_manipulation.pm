###############################################################################

package File_Manipulation;

use strict;
use warnings;

use Cwd;
use Cwd 'abs_path';
use File::Find;
use File::Path;
use File::Compare;
use File::Copy;
use File::Spec;
use File::Basename;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'substitute_vars_in_options' => 1};

    bless ($self, $class);
    return $self;
}

##############################################################################
#

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ":\n  Requires \"root\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################
# INTERNAL Function NOT exported
# This ensures that the output is an array reference or is undefined if
# the array is empty.

my $undefIfEmptyArray= sub
{
    my $refArray= shift;
    if (defined( $refArray )) {
        my $refType= ref( $refArray );
        if ($refType eq "ARRAY") {
            ### Its an array ref OK, but if the array has no entries
            ### simply don't provide it
            ########################################################
            if (scalar( @$refArray ) == 0) {
                undef( $refArray );
            }
        }
        else {
            if (defined( $refType )) {
                print( STDERR __FILE__,
                       ":\n  Internal error; reference of \"$refType\"\n" );
            }
            else {
                print( STDERR __FILE__,
                       ":\n  Internal error; non-reference given\n" );
            }
            undef( $refArray );
        }
    }

    return $refArray;
};

##############################################################################
# INTERNAL Function NOT exported
# This checks the scalar for matching one of the array of filters returning
# true if there is a match, or false if there isn't.

my $checkForMatch= sub
{
    my $entry=      shift;
    my $filters=    &$undefIfEmptyArray( shift );
    my $matchFound= 0;

    if (!-e $entry) {
        return 0;
    }

    my $pathname = '';

    my @dirs = ();
    if (-d $entry) {
        @dirs = File::Spec->splitdir( $entry );
        $pathname = pop @dirs;
    } else {
        my ($fn, $dirpath) = fileparse( $entry );
        @dirs = File::Spec->splitdir( $dirpath );
        $pathname = $fn;
    }

    my @tmp_dirs = ();
    foreach my $tmp (@dirs) {
        if ($tmp ne '') {
            push @tmp_dirs, $tmp;
        }
    }
    @dirs = reverse( @tmp_dirs );
    push @dirs, '';

    foreach my $subpath (@dirs) {
        foreach my $filter (@$filters) {
            if ($pathname =~ /$filter/) {
                $matchFound= 1;
                last;
            }
        }
        if ($matchFound) {
            last;
        }
        $pathname = $subpath . '/' . $pathname;
    }

    return $matchFound;
};

##############################################################################
# INTERNAL Function NOT exported
# This updates the supplied path, replacing any windows directory
# seporators with perl/unix ones, it also ensures that it ends with a
# directory seporator.

my $tidyPath= sub
{
    my $path= File::Spec->canonpath( shift );

    $path=~ s|\\|/|g;
    if (substr($path, -1) ne "/") {
        $path.= "/";
    }

    return $path;
};

##############################################################################
# INTERNAL Function NOT exported
# This ensures that the source path is valid, and creates/updates the
# destination directory. It then copies all of the files from the source
# directory into the destination, and recurses any sub-directories it
# encounters so as to copy the whole tree.
# Parameters are:
# 1) source      - String giving the source path.
# 2) destination - String giving the destination path.
# 3) includes    - Optional array of regular expression strings that MUST
#                  match any FILES to be copied; a missing or empty array
#                  [] means match all.
# 4) excludes    - Optional array of regular expression strings that must
#                  NOT match any FILES or or DIRECTORIES to be copied; an
#                  empty array [] means exclude nothing.
# 5) copyFlat    - If a 5th parameter is given, the source tree is not
#                  replicated, and the source files are all copied into the
#                  single destination directory reguardless of which souce
#                  sub-directory contained them. If given as 2, it will also
#                  not traverse down any source sub-directories, therefore
#                  working in the single source directory given.
# returns 0 on success;

my $copyTreeFromTo; ### declare first, as it calls itself, must see the ;
$copyTreeFromTo= sub
{
    my $rootSrc=   shift;
    my $rootDest=  shift;
    my $include=   &$undefIfEmptyArray( shift );
    my $exclude=   &$undefIfEmptyArray( shift );
    my $copyFlat=  shift;

    if ( !defined( $rootSrc ) or ("" eq $rootSrc) or
         ("" ne ref( $rootSrc ))
       ) {
        print( STDERR __FILE__,
               ":\n  INTERNAL error; source and destination paths\n" );
        return 1;
    }
    if ( !defined( $rootDest ) or ("" eq $rootDest) or
         ("" ne ref( $rootDest ))
       ) {
        print( STDERR __FILE__,
               ":\n  INTERNAL error; destination path\n" );
        return 1;
    }

    ### Ensure that the source path is a valid directory.
    #####################################################
    my $srcExists= -e $rootSrc;
    my $srcIsDir=  -d $rootSrc;
    $rootSrc= &$tidyPath( $rootSrc );
    if (!$srcExists) {
        print( STDERR __FILE__, ":\n  Source directory does not exist!\n",
               "  $rootSrc\n" );
        return 1;
    }
    if (!$srcIsDir) {
       print( STDERR __FILE__, ":\n  Source directory is a normal file!\n",
              "  $rootSrc\n" );
        return 1;
    }

    ### Ensure we have a destination directory to receive the files.
    ################################################################
    if (!-e $rootDest) {
        $rootDest= &$tidyPath( $rootDest );
        if ($main::verbose == 1) {
            main::PrintStatus ('Setup', "Creating  $rootDest");
        }
        if (!mkdir( $rootDest )) {
            print(
                STDERR __FILE__,
                "ERROR: Can't create directory\n  $rootDest\n" );
            return 1;
        }
    }
    elsif (!-d $rootDest) {
        ### This destination already exists as a file
        #############################################
        print(
            STDERR __FILE__,
            ":\n  Destination file is required to be a copy of directory\n",
            "  To:   $rootDest\n",
            "  From: $rootSrc\n" );
        return 1;
    }
    else {
        $rootDest= &$tidyPath( $rootDest );
        if (!defined( $copyFlat )) {
            if ($main::verbose == 1) {
                main::PrintStatus ('Setup', "Updating  $rootDest");
            }
        }
    }

    ### Ensure we are not trying to copy ourselves.
    ### (Unfortunatly the abs_path only works if you can chdir to each of
    ###  the path directories, thus we can't check until the above "ensure
    ###  dest is a dir test" has done.)
    ######################################################################
    my $absSrc=  &$tidyPath( abs_path( $rootSrc ) );
    my $absDest= &$tidyPath( abs_path( $rootDest ));
    if (substr( $absDest, 0, length( $absSrc )) eq $absSrc) {
        print(
            STDERR __FILE__,
            ":\n  Destination directory is inside the original source tree\n",
            "  To:   $absDest\n",
            "  From: $absSrc\n" );
        return 1;
    }

    ### Deal with all of the files/sub-directories at this source path
    ##################################################################
    my $dirHandle;
    if (!opendir( $dirHandle, $rootSrc )) {
        print(
            STDERR __FILE__,
            "ERROR: Can't read directory\n  $rootSrc\n" );
        return 1;
    }
    foreach my $entry (readdir( $dirHandle )) {
        if (($entry ne ".") && ($entry ne "..")) {
            my $fullPathSrc=  $rootSrc  . $entry;
            if (&$checkForMatch( $fullPathSrc, $exclude )) {
                if ($main::verbose == 1) {
                    main::PrintStatus ('Setup', "Excluding $fullPathSrc");
                }
                next;
            } ## check for exclude

            my $fullPathDest= $rootDest . $entry;

            ### Deal with any sud-directory entries
            #######################################
            if (-d $fullPathSrc) {
                if ((!defined($copyFlat) || (2 != $copyFlat)) && &$copyTreeFromTo(
                    $fullPathSrc,
                    (defined( $copyFlat ) ? ### If we are copying flat:
                        $rootDest :         ### Don't update destination;
                        $fullPathDest ),    ### Otherwise replicate the tree
                    (defined( $include ) ?  ### We have an include list
                        $include :          ### so use it,
                        [] ),               ### otherwise empty list!
                    (defined( $exclude ) ?  ### We have an exclude list
                        $exclude :          ### so use it,
                        [] ),               ### otherwise empty list!
                    $copyFlat )) {
                    return 1;
                }
            }
            elsif ((-f $fullPathSrc) || (-l $fullPathSrc)) {
                ### We are dealing with a normal file entry or symbolic link
                ############################################################
                if (defined( $include )) {
                    if (!&$checkForMatch( $fullPathSrc, $include )) {
                        if ($main::verbose == 1) {
                            main::PrintStatus( 'Setup',
                                               "Ignoring  $fullPathSrc" );
                        }
                        next;
                    }
                } ## check for include
                if (-e $fullPathDest) {
                    ### Which already exists, it must not be a directory
                    ####################################################
                    if (-d $fullPathDest) {
                        print(
                            STDERR __FILE__,
                            ":\n  Destination directory is required to be a",
                            " copy of file\n",
                            "  To:   $fullPathDest/\n",
                            "  From: $fullPathSrc\n" );
                        return 1;
                    }

                    if ($main::verbose == 1) {
                        main::PrintStatus ('Setup', "Replacing $fullPathDest");
                    }
                }
                else {
                    ### Since it does not already exist, it will be created
                    #######################################################
                    if ($main::verbose == 1) {
                        main::PrintStatus ('Setup', "Creating  $fullPathDest");
                    }
                }

                ### Copy execute permission if successful copy.
                ###############################################
                if (copy( $fullPathSrc, $fullPathDest )) {
                    if (-x $fullPathSrc) {
                        chmod 0777, $fullPathDest;
                    }
                }
                ### Ignore copy errors if symbolic link has failed
                ##################################################
                elsif (! -l $fullPathSrc) {
                    print(
                        STDERR __FILE__,
                        "Failed to copy file\n",
                        "  From: $fullPathSrc\n",
                        "  To:   $fullPathDest\n");
                    return 1;
                }
            } ### was a copiable file
        } ### not . or ..
    } ### foreach entry

    closedir( $dirHandle );
    return 0;
};

##############################################################################
# INTERNAL Function NOT exported
# This ensures that the source path is valid. It then deletes all of the files
# named by the include (and not named by the exclude) from the source directory
# and recurses any sub-directories it encounters so as to purge the whole tree.
# Parameters are:
# 1) source      - String giving the source path (starting point).
# 2) includes    - Array of regular expression strings that MUST match any FILES
#                  to be removed; a missing or empty array [] is illegal.
# 3) excludes    - Optional array of regular expression strings that must NOT
#                  match any FILES (or DIRECTORIES) to be removed; an  empty
#                  array [] means exclude nothing.
# 4) singleDir   - If a 4th parameter is given, it will not traverse down
#                  any source sub-directories, therefore working in the
#                  single source directory given.
# returns 0 on success;

my $deleteFromTree; ### declare first, as it calls itself, must see the ;
$deleteFromTree= sub
{
    my $rootSrc=   shift;
    my $include=   &$undefIfEmptyArray( shift );
    my $exclude=   &$undefIfEmptyArray( shift );
    my $singleDir= shift;

    if ( !defined( $rootSrc ) or ("" eq $rootSrc) or
         ("" ne ref( $rootSrc ))
       ) {
        print( STDERR __FILE__,
               ":\n  INTERNAL error; source path\n" );
        return 1;
    }
    if ( !defined( $include  )) {
        print( STDERR __FILE__,
               ":\n  INTERNAL error; include must be given\n" );
        return 1;
    }

    ### Ensure that the source path is a valid directory.
    #####################################################
    my $srcExists= -e $rootSrc;
    my $srcIsDir=  -d $rootSrc;
    $rootSrc= &$tidyPath( $rootSrc );
    if (!$srcExists) {
        print( STDERR __FILE__, ":\n  Source directory does not exist!\n",
               "  $rootSrc\n" );
        return 1;
    }
    if (!$srcIsDir) {
       print( STDERR __FILE__, ":\n  Source directory is a normal file!\n",
              "  $rootSrc\n" );
        return 1;
    }

    ### Deal with all of the files/sub-directories at this source path
    ##################################################################
    my $dirHandle;
    if (!opendir( $dirHandle, $rootSrc )) {
        print(
            STDERR __FILE__,
            "ERROR: Can't read directory\n  $rootSrc\n" );
        return 1;
    }
    foreach my $entry (readdir( $dirHandle )) {
        if (($entry ne ".") && ($entry ne "..")) {
            my $fullPathSrc=  $rootSrc  . $entry;
            if (&$checkForMatch( $fullPathSrc, $exclude )) {
                if ($main::verbose == 1) {
                    main::PrintStatus ('Setup', "Excluding $fullPathSrc");
                }
                next;
            } ## check for exclude

            ### Deal with any sud-directory entries
            #######################################
            if (-d $fullPathSrc) {
                if (!defined( $singleDir ) && &$deleteFromTree(
                    $fullPathSrc,
                    $include,
                    (defined( $exclude ) ?  ### We have an exclude list
                        $exclude :          ### so use it,
                        [] )                ### otherwise empty list!
                   )) {
                    return 1;
                }
            }
            elsif ((-f $fullPathSrc) || (-l $fullPathSrc)) {
                ### We are dealing with a normal file entry or symbolic link
                ############################################################
                if (!&$checkForMatch( $fullPathSrc, $include )) {
                    if ($main::verbose == 1) {
                        main::PrintStatus( 'Setup',
                                           "Ignoring  $fullPathSrc" );
                    }
                    next;
                }

                if ($main::verbose == 1) {
                    main::PrintStatus( 'Setup',
                                       "Deleting  $fullPathSrc" );
                }
                unlink( $fullPathSrc );
            } ### was a normal file
        } ### not . or ..
    } ### foreach entry

    closedir( $dirHandle );
    return 0;
};

##############################################################################
# INTERNAL Function NOT exported
# This traverses from the source path and removes any empty directories it
# finds.
# Parameters are:
# 1) source      - String giving the source path.
# Returns:
# 1) True if this immediate directory was NOT deleted (still contains files)

my $deleteEmptyDirs; ### declare first, as it calls itself, must see the ;
$deleteEmptyDirs= sub
{
    my $rootSrc=   shift;

    if ( !defined( $rootSrc ) or ("" eq $rootSrc) or
         ("" ne ref( $rootSrc ))
       ) {
        print( STDERR __FILE__,
               ":\n  INTERNAL error; source path\n" );
        return 1;
    }

    ### Ensure that the source path is a valid directory.
    #####################################################
    my $srcExists= -e $rootSrc;
    my $srcIsDir=  -d $rootSrc;
    $rootSrc= &$tidyPath( $rootSrc );
    if (!$srcExists) {
        print( STDERR __FILE__, ":\n  Source directory does not exist!\n",
               "  $rootSrc\n" );
        return 1;
    }
    if (!$srcIsDir) {
       print( STDERR __FILE__, ":\n  Source directory is a normal file!\n",
              "  $rootSrc\n" );
        return 1;
    }

    ### Deal with all of the files/sub-directories at this source path
    ##################################################################
    my $empty= 1;  ### any file/dir found resets.
    my $dirHandle;
    if (!opendir( $dirHandle, $rootSrc )) {
        print( STDERR __FILE__, "ERROR: Can't read directory\n  $rootSrc\n");
        return 1;
    }

    foreach my $entry (readdir( $dirHandle )) {
        if (($entry ne ".") && ($entry ne "..")) {
            my $fullPathSrc=  $rootSrc  . $entry;

            ### Deal with any sud-directory entries
            #######################################
            if (-d $fullPathSrc) {
                if (&$deleteEmptyDirs( $fullPathSrc )) {
                    $empty= 0; ### dir was not removed.
                }
            }
            else {
               $empty= 0; ### Found a file.
            } ### was a file
        } ### not . or ..
    } ### foreach entry

    closedir( $dirHandle );
    if ($empty) {
        if ($main::verbose == 1) {
            main::PrintStatus ('Setup', "Removing empty directory $rootSrc");
        }
        return !rmdir $rootSrc;
    }
    return 1;
};

##############################################################################
# INTERNAL Function NOT exported
# This read a file and returns a list of the lines read, excluding comments
# introduced by # and blank lines.
# Parameters are:
# 1) filename
# Returns:
# 1) list of lines read (without \n) or undef in no lines read.

my $readFile; ### declare first, as it calls itself, must see the ;
$readFile= sub
{
   my @linesRead;
   my $filename= shift;

   if (-e $filename) {
       my $openfile;
       open( $openfile, $filename );
       my @allLines= <$openfile>;
       foreach my $line (@allLines) {
           $line =~ m/^\s*([^#\s]*)/;
           if ($1 ne "") {
               my $entry = $1;
               if ($entry =~ m/^\!(.*)$/) {
                   my $subfile = $1;
                   my $oldcurdir = cwd;
                   chdir dirname( $filename );  ### We can always chdir to this dir
                   ### since we read a file from there before.
                   my @entrylist = &$readFile( $subfile );
                   foreach my $se (@entrylist) {
                       push @linesRead, dirname( $subfile ) . '/' . $se;
                   }
                   chdir $oldcurdir;
               } else {
                   push @linesRead, $entry;
               }
           }
       }
       close( $openfile );
   }
   return @linesRead;
};

##############################################################################
#

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    my $root = main::GetVariable ('root');

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    ### chop off trailing slash
    ###########################
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    if ($main::verbose == 1) {
        main::PrintStatus ('Setup', 'File_Manipulation');
    }

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ":\n  Cannot change to $root\n";
        return 0;
    }

    #########################################################
    ######## Tidy-up and separate the options string ########
    #########################################################

    my @splitOptions;
    my $numOfOptions= 0;
    my @theBits= split /\'/, $options;   ### alternates unquoted, quoted strings
    undef $options; ### safety, now using $splitOptions

    while (scalar( @theBits) ) {
        ### for each unquoted option, space/comma separated options
        ###########################################################
        foreach my $option (split( /[, ]/, shift( @theBits ))) {
            if ($option =~ m/^\=/) {
                ### command option starts with an =
                ### (must be part of the previous option)
                #########################################
                if ($numOfOptions) {
                    $splitOptions[ $numOfOptions - 1 ].= $option;
                }
                else {
                    ### No previuous option, probably illegal will report later
                    ###########################################################
                    ++$numOfOptions;
                    @splitOptions= ($option);
                }
            }
            elsif ($numOfOptions &&
                   ($splitOptions[ $numOfOptions - 1 ] =~/\=$/)
                  ) {
                ### Previous option ended with an '='; append this option as
                ### it's value, this allows for space separated "option =
                ### value" strings.
                ############################################################
                $splitOptions[ $numOfOptions - 1 ].= $option;
            }
            elsif (defined( $option ) && ($option ne "")) {
                ++$numOfOptions;
                push @splitOptions, $option;
            }
        }
        ### Append the dequoted value string if given to the last option
        ### as it is acutaully a part of that command option.
        ################################################################
        if (scalar( @theBits )) {
            if ($numOfOptions) {
                $splitOptions[ $numOfOptions - 1 ].= shift @theBits;
            }
            else {
                ++$numOfOptions;
                @splitOptions= (shift @theBits);
            }
        }
    }

    #################################################
    ######## Collect the given option values ########
    #################################################

    my $type;
    my $filename;      ### (the source filename/path)
    my $target;        ### (the destination filename/path)
    my $output;
    my $include= [];   ### Copytree Default include everything
    my $exclude= [];   ### Copytree Default exclude nothing

    foreach my $option (@splitOptions) {

        ### option   from=
        ### option   file=
        ### option  source=
        ###################
        if ($option =~ m/^(file|source|from)=(.*)/) {
            my $optionName= $1;
            if (defined( $filename )) {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  Multiple \"$optionName\" path/filename specified in options\n",
                      "  ($filename & $2)\n";
                return 0;
            }
            $filename= $2;
        }
        ### option  output=
        ###################
        elsif ($option =~ m/^output=(.*)/) {
            $output.= $1;  ### Multiple outputs concatenate
        }
        ### option      to=
        ### option    target=
        ### option  destination=
        ########################
        elsif ($option =~ m/^(target|destination|to)=(.*)/) {
            my $optionName= $1;
            if (defined( $target )) {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  Multiple \"$optionName\" path/filename specified in options\n",
                      "  ($target & $2)\n";
                return 0;
            }
            $target= $2;
        }
        ### option  libfile=
        ####################
        elsif ($option =~ m/^libfile=(.*)/) {
            my @libs= &$readFile( $1 );
            if (@libs) {
                push( @$include,
                      '^(lib)?(' .
                          join( '|', @libs ) .
                          ')(d)?\.(lib|exp|pdb|so\.\d+\.\d+\.\d+|sl|a)$'
                    );
            }
            else {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  libfile=$1 is missing or contains no libraries\n";
                return 0;
            }
        }
        ### option  dllfile=
        ####################
        elsif ($option =~ m/^dllfile=(.*)/) {
            my @dlls= &$readFile( $1 );
            if (@dlls) {
                push( @$include,
                      '^(lib)?(' . join( '|', @dlls ) . ')(d)?\.dll$'
                    );
            }
            else {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  dllfile=$1 is missing or contains no dlls\n";
                return 0;
            }
        }
        ### option  binfile=
        ####################
        elsif ($option =~ m/^binfile=(.*)/) {
            my @bins= &$readFile( $1 );
            if (@bins) {
                push( @$include,
                      '^(' . join( '|', @bins ) . ')(|\.exe|\.pdb)$'
                    );
            }
            else {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  binfile=$1 is missing or contains no binaries\n";
                return 0;
            }
        }
        ### option  idlfile=
        ####################
        elsif ($option =~ m/^idlfile=(.*)/) {
            my @idlfiles= &$readFile( $1 );
            if (@idlfiles) {
                push( @$include,
                      '^(' . join( '|', @idlfiles ) . ')\.idl$'
                    );
            }
            else {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  idlfile=$1 is missing or contains no libraries\n";
                return 0;
            }
        }
        ### option  plainfile=
        ####################
        elsif ($option =~ m/^plainfile=(.*)/) {
            my @plainfiles= &$readFile( $1 );
            if (@plainfiles) {
                push ( @$include, '^(' . join( '|', @plainfiles ) . ')$' );
            }
            else {
                print STDERR __FILE__, ":\n",
                      "  In file_manipulation $type\n",
                      "  plainfile=$1 is missing or contains no files\n";
                return 0;
            }
        }
        ### option  include= ### separate "include" regular expression
        ### option   only=   ### items with commas (spaces if quoted)
        ####################
        elsif ($option =~ m/^(include|only)=(.*)/) {
            my @list= split /[ ,]/,$2;
            foreach my $entry (@list) {
                push @$include, $entry;
            }
        }
        ### option  exclude= ###   separate exclude regular expression items with
        ### option  ignore=  ###   commas (or spaces if quoted)
        ####################
        elsif ($option =~ m/^(exclude|ignore)=(.*)/) {
            my @list= split /[ ,]/,$2;
            foreach my $entry (@list) {
                push @$exclude, $entry;
            }
        }
        ### Unknown option given, assume it is actually a type
        ### NOTE: Ensure that any new options are placed ABOVE this
        ### default entry otherwise they will not be matched.
        ###########################################################
        else {
            ### old style option type=
            ##########################
            if ($option =~ m/^type=(.*)/) {
                $option = $1;  ### Remove the "type="
            }
            if (defined( $type )) {
                print STDERR __FILE__, ":\n",
                      "  Multiple \"type\" specified in options\n",
                      "  \"$type\" and \"$option\"\n",
                      "  (This may be caused by unquoted value containing a , or space)\n";
                return 0;
            }
            $type= lc $option; ### type given can be in any case, force lower.
        }
    } ### end of foreach option

    ### Sanity checks
    #################

    if (!defined( $type ) || ($type eq "")) {
        print STDERR __FILE__, ":\n  No type specified in command options\n";
        return 0;
    }
    if (!defined ($filename) || ($filename eq "")) {
        print STDERR __FILE__, ":\n",
              "  In file_manipulation $type\n",
              "  No source file specified in command options\n";
        return 0;
    }

    ### Now act on the type (always check for lowercase match)
    ##########################################################

    ### type=  append
    #################
    if ($type eq "append") {
        if (!defined $output) {
            print STDERR __FILE__, ":\n",
                  "  No output specified for \"append\" type\n";
            return 0;
        }

        if (-e $filename) {
            # Expand some codes
            $output =~ s/\\n/\n/g;
            $output =~ s/\\x27/'/g;

            my $file_handle = new FileHandle ($filename, 'a');

            if (!defined $file_handle) {
                print STDERR __FILE__, ":\n",
                      "  Error opening file ($root/)$filename: $!\n";
                return 0;
            }

            print $file_handle $output;
        }
        else {
            print STDERR __FILE__, ":\n",
                  "  ($root/) \"$filename\" does not exist!\n";
            return 0;
        }
    }
    ### type=  create
    #################
    elsif ($type eq "create") {

        if (!defined $output) {
            print STDERR __FILE__, ":\n",
                  "  No output specified for \"create\" type\n";
            return 0;
        }

        # Expand some codes

        $output =~ s/\\n/\n/g;
        $output =~ s/\\x27/'/g;

        my $file_handle = new FileHandle ($filename, 'w');

        if (!defined $file_handle) {
            print STDERR __FILE__, ":\n",
                  "  Error creating file ($root/)$filename: $!\n";
            return 0;
        }

        print $file_handle $output;
    }
    ### type=  update
    #################
    elsif ($type eq "update") {
        if (!defined $output) {
            print STDERR __FILE__, ":\n",
                  "  No output specified for \"update\" type\n";
            return 0;
        }

        # Expand some codes

        $output =~ s/\\n/\n/g;
        $output =~ s/\\x27/'/g;

        my $full_path = $root . '/' . $filename;
        my $tmp_path  = $full_path . ".$$";
        my $file_handle = new FileHandle ($tmp_path, 'w');

        if (!defined $file_handle) {
            print STDERR __FILE__, ":\n",
                  "  Error creating file ($tmp_path): $!\n";
            return 0;
        }

        print $file_handle $output;
        close($file_handle);

        my $different = 1;
        if (-r $full_path &&
            -s $tmp_path == -s $full_path &&
            compare($tmp_path, $full_path) == 0
           ) {
            $different = 0;
        }

        if ($different) {
            unlink($full_path);
            if (!rename($tmp_path, $full_path)) {
                print STDERR __FILE__, ":\n",
                      "  Error renaming file\n  from $tmp_path\n  to $full_path\n  $!\n";
                return 0;
            }
        }
        else {
            unlink($tmp_path);
        }
    }
    ### type=  delete
    #################
    elsif ($type eq "delete") {
        unlink $filename;
    }
    ### type=   move
    ### type=  rename
    #################
    elsif (($type eq "move") || ($type eq "rename")) {
        if (!defined $target) {
            print STDERR __FILE__, ":\n",
                  "  No target specified for \"$type\" type\n";
            return 0;
        }

        rename $filename, $target;
    }
    ### type=  rmtree
    #################
    elsif ($type eq "rmtree") {
        rmtree ($filename, 0, 0);
    }
    ### type=  mustnotexist
    #######################
    elsif ($type eq "mustnotexist") {
        if (-e $filename) {
            print STDERR __FILE__, ":\n",
                  "  File \"($root/)$filename\" exists!\n";
            return 0;
        }
    }
    ### type=  mustnotexist
    #######################
    elsif ($type eq "mustexist") {
        if (!-e $filename) {
            print STDERR __FILE__, ":\n",
                  "  File \"($root/)$filename\" does NOT exist!\n";
            return 0;
        }
    }
    ### type=  copy
    ###############
    elsif ($type eq "copy") {
        if (!defined $target) {
            print STDERR __FILE__, ":\n",
                  "  No target specified for \"copy\" type\n";
            return 0;
        }

        if (copy($filename, $target)) {
            ### Successfully copied the file, now replicate execute permission
            ##################################################################
            if (-x $filename) {
                chmod 0777, $target;
            }
        }
        elsif (! -l $filename) {
            ### A real file could not be copied!
            ####################################
            print STDERR __FILE__, ":\n",
                  "  Error copying file\n  from $filename\n  to $target)\n";
            return 0;
        }
    }
    ### type=  copytree
    ###################
    elsif ($type eq "copytree") {
        if (!defined $target) {
            print STDERR __FILE__, ":\n",
                  "  No target path specified for \"copytree\" type\n";
            return 0;
        }

        if (&$copyTreeFromTo(
            $filename,
            $target,
            $include,
            $exclude )) {
            return 0;
        }
    }
    ### type=  copyflat
    ###################
    elsif ($type eq "copyflat") {
        if (!defined $target) {
            print STDERR __FILE__, ":\n",
                  "  No target path specified for \"copyflat\" type\n";
            return 0;
        }

        if (&$copyTreeFromTo(
            $filename,
            $target,
            $include,
            $exclude,
            1 )) { ### Flat mode, all into same destination directory.
            return 0;
        }
    }
    ### type=  copynotree
    #####################
    elsif ($type eq "copynotree") {
        if (!defined $target) {
            print STDERR __FILE__, ":\n",
                  "  No target path specified for \"copyflat\" type\n";
            return 0;
        }

        if (&$copyTreeFromTo(
            $filename,
            $target,
            $include,
            $exclude,
            2 )) { ### Do not recurse down tree (i.e. single source directory).
            return 0;
        }
    }
    ### type=  deletefromtree
    #########################
    elsif ($type eq "deletefromtree") {
        if (&$deleteFromTree(
            $filename,
            $include,
            $exclude
           )) {
            return 0;
        }
    }
    ### type=  deletefromsingledir
    ##############################
    elsif ($type eq "deletefromsingledir") {
        if (&$deleteFromTree(
            $filename,
            $include,
            $exclude,
            1 )) { ### Do not recurse down tree (i.e. single directory).
            return 0;
        }
    }
    ### type=  deleteemptydirs
    ##########################
    elsif ($type eq "deleteemptydirs") {
        &$deleteEmptyDirs( $filename );
    }
    ### type=  mkdir
    ################
    elsif ($type eq "mkdir") {
        if (!-e $filename ) {
            mkdir( $filename );
        }
    }
    ### type=  chdir
    ################
    elsif ($type eq "chdir") {
        if (defined $filename) {
            if (-d $filename ) {
                $current_dir = $filename;
            } else {
                print STDERR __FILE__, ":\n",
                    "  Could not chdir into $filename, it is not a directory!\n";
                return 0;
            }
        } else {
            $current_dir = main::GetVariable ('root');
        }
    }
    ### type not found
    ##################
    else {
        print STDERR __FILE__, ":\n",
              "  Unrecognized option/type \"$type\"\n",
              "  (This may be caused by unquoted value containing a , or space)\n";
        return 0;
    }

    chdir $current_dir;
    return 1;
}

##############################################################################
#

main::RegisterCommand ("file_manipulation", new File_Manipulation ());

