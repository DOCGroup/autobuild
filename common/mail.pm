package Mail;

use strict;

## Find a mailer which supports the "-s" flag

sub find_mailer()
{

   my @MAILERS = ( "/usr/bin/mailx",
                "/bin/mailx",
                "/usr/bin/mail",
                "/bin/mail" );

   my $mailer;

   foreach $mailer ( @MAILERS ) 
   {
      if ( -x $mailer )
      {
         return $mailer;
      }
   }

}

sub send_message($$$)
{
  my ($to, $subject, $message) = @_;

  my $mailer = find_mailer();

  if( ! defined $mailer  )
  {
      print "Cannot find mail program\n";
      return -1;
  }

  open(MAIL, "|$mailer -s \"$subject\" $to" );

  print MAIL $message;
  close(MAIL);

  return 0; 
}

1;

