#

package PrintACEConfig;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');
    my $config_file = main::GetVariable ('CVS_CONFIG_FILE');
    my $opendds_url = 'https://github.com/OpenDDS/OpenDDS';
    my $atcd_url = 'https://github.com/DOCGroup/ACE_TAO';
    my $ciao_url = 'https://github.com/DOCGroup/CIAO';
    my $dance_url = 'https://github.com/DOCGroup/DAnCE';
    my $mpc_url = 'https://github.com/DOCGroup/MPC';
    my $autobuild_url = 'https://github.com/DOCGroup/autobuild';
    my %information = ('XML'       => ['', '',
                                       "$autobuild_url/blob/master/<file>"],
                       'AUTOBUILD' => ['ChangeLog', '',
                                       "$autobuild_url/commits/master"],
                       'MPC'       => ['ChangeLog', 'MPC/',
                                       "$mpc_url/commits/master/"],
                       'ACE'       => ['ChangeLog', '',
                                       "$atcd_url/commits/master/ACE"],
                       'TAO'       => ['ChangeLog', 'TAO/',
                                       "$atcd_url/commits/master/TAO"],
                       'CIAO'      => ['ChangeLog', 'TAO/CIAO/',
                                       "$ciao_url/commits/master"],
                       'DANCE'     => ['ChangeLog', 'TAO/DAnCE/',
                                       "$dance_url/commits/master"],
                       'DDS'       => ['ChangeLog', 'DDS/',
                                       "$opendds_url/commits/master"],
                      );
    my @cl_order = ('MPC', 'ACE', 'TAO', 'CIAO', 'DANCE', 'DDS');

    foreach my $option (split(/\s+/, $options)) {
      if ($option =~ /([^=]+)=(.*)/) {
        my($name)  = uc($1);
        my($value) = $2;
        ## First, check for a ChangeLog setting
        if (defined $information{$name}) {
          $information{$name}->[0] = $value;
        }
        ## Next, check for a URL setting
        elsif ($name =~ s/_URL$// && defined $information{$name}) {
          $value .= '/<file>' if ($value !~ /\/<file>/);
          $information{$name}->[2] = $value;
        }
        ## We did not recognize this setting
        else {
          print "WARNING: $name not recognized.\n";
        }
      }
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    my $url = undef;
    main::PrintStatus ('Config', 'PrintACEConfig');

    $url = $information{XML}->[2];
    $url =~ s/<file>/$config_file/;
    print "XML Config file: <a href=\"$url\">${config_file}</a>\n";

    my $configs = main::GetVariable ('configs');
    print "Test config: $configs\n" if defined $configs;

    my $cl = $information{AUTOBUILD}->[0];
    $url = $information{AUTOBUILD}->[2];
    $url =~ s/<file>/$cl/;
    print "================ <a href=\"$url\">Autobuild $cl</a> ================\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
          print STDERR __FILE__, ": Cannot change to $root or $ENV{'ROOT'}\n";
          return 0;
    }

    if (!defined $project_root) {
        $project_root = $ENV{ACE_ROOT};
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (exists $ENV{ACE_ROOT}) {
      if (!chdir $ENV{'ACE_ROOT'} )
      {
          if (!chdir $project_root) {
              print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
              return 0;
          }
      }
    }

    foreach my $cle (@cl_order) {
      my($prroot) = $ENV{$cle . '_ROOT'};
      my($prpath) = (defined $prroot ? "$prroot/" : $information{$cle}->[1]);

      if (-r "$prpath$information{$cle}->[0]") {
          my $cl = $information{$cle}->[0];
          my $url = $information{$cle}->[2];
          $url =~ s/<file>/$cl/;
          print "================ <a href=\"$url\">$cle $cl</a> ================\n";
          print_file ("$prpath$information{$cle}->[0]", 0);
      }
    }

    if (exists $ENV{ACE_ROOT}) {
      #
      # config.h, if it exists
      #
      if (-r "$ENV{ACE_ROOT}/ace/config.h") {
          print "================ config.h ================\n";
          print_file ("$ENV{ACE_ROOT}/ace/config.h", 1);
      }
    }

    if (exists $ENV{ACE_ROOT}) {
      #
      # default.features, if it exists
      #
      if (-r "$ENV{ACE_ROOT}/bin/MakeProjectCreator/config/default.features") {
          print "================ default.features ================\n";
          print_file ("$ENV{ACE_ROOT}/bin/MakeProjectCreator/config/default.features", 1);
      }
    }

    my $local_features = main::GetVariable ('local_features');
    if (defined $local_features) {
      # local features was set, so print it
      if (-r "$local_features") {
          print "================ local.features ($local_features) =============\n";
          print_file ("$local_features", 1);
      }
    }

    #
    # platform_macros.GNU, if it exists
    #
    my @dirs = ();

    if (exists $ENV{ACE_ROOT}) {
      if (-r "$ENV{ACE_ROOT}/include/makeinclude/platform_macros.GNU") {
          print "================ platform_macros.GNU ================\n";
          print_file ("$ENV{ACE_ROOT}/include/makeinclude/platform_macros.GNU", 1);
      }

      if ( -r "$ENV{ACE_ROOT}/VERSION.txt" ) {
          print "================ ACE VERSION ================\n";

          print_file ("$ENV{ACE_ROOT}/VERSION.txt", 0);
      }
    }

    @dirs = ();
    if (exists $ENV{TAO_ROOT}) {
      push (@dirs, $ENV{TAO_ROOT});
    }
    push (@dirs, 'TAO');
    foreach my $dir (@dirs) {
      if (defined $dir && -r "$dir/VERSION.txt") {
        print "================ TAO VERSION ================\n";

        print_file ("$dir/VERSION.txt", 0);
        last;
      }
    }

    @dirs = ();
    if (exists $ENV{CIAO_ROOT}) {
      push (@dirs, $ENV{CIAO_ROOT});
    }
    push (@dirs, 'TAO/CIAO');
    foreach my $dir (@dirs) {
      if (defined $dir && -r "$dir/VERSION") {
        print "================ CIAO VERSION ================\n";

        print_file ("$dir/VERSION", 0);
        last;
      }
    }

    @dirs = ();
    if (exists $ENV{DANCE_ROOT}) {
      push (@dirs, $ENV{DANCE_ROOT});
    }
    push (@dirs, 'TAO/DAnCE');
    foreach my $dir (@dirs) {
      if (defined $dir && -r "$dir/VERSION") {
        print "================ DAnCE VERSION ================\n";

        print_file ("$dir/VERSION", 0);
        last;
      }
    }

    @dirs = ();
    if (exists $ENV{DDS_ROOT}) {
      push (@dirs, $ENV{DDS_ROOT});
    }
    push (@dirs, 'TAO/DDS');
    foreach my $dir (@dirs) {
      if (defined $dir && -r "$dir/VERSION.txt") {
        print "================ DDS VERSION ================\n";

        print_file ("$dir/VERSION.txt", 0);
        last;
      }
      if (defined $dir && -r "$dir/dds/OpenDDSConfig.h") {
        print "================ OpenDDSConfig.h ================\n";

        print_file ("$dir/dds/OpenDDSConfig.h", 0);
        last;
      }
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

sub print_file ($$)
{
    my $filename = shift;
    my $printall = shift;

    my $filehandle = new FileHandle ($filename, "r");

    while (<$filehandle>) {
        print $_;

        last if ($printall == 0);
    }
}

##############################################################################

main::RegisterCommand ("print_ace_config", new PrintACEConfig ());
