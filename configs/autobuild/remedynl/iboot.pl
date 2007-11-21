#!/usr/local/bin/perl -w
# Author Brian P. Barnes 7-17-2002
# Copyright 2002 Polycom, Inc.
# USAGE: sabre.iboot.pl [IP_Address_of_Iboot_device] <enter>
use IO::Socket;
$ibootip = "10.2.0.130"; # Default IP address of iBoot power strip.
$ibootip = $ARGV[0] if(defined($ARGV[0])); # Override default?
#$ibootport = 80; # Port to address for TCP connection.
#$pw = "PASS"; # Password to control iBoot.
#$CYCLE = "c"; # Command to cycle power.
$s = IO::Socket::INET->new("$ibootip:80");
die "Failed to connect - $!\n" unless $s;
$s->send ("\ePASS\ef\r");
$s->recv($text,128);
#print($text);
close $s;
$s = IO::Socket::INET->new("10.2.0.130:80");
$s->send ("\ePASS\en\r");
$s->recv($text,128);
#print($text);
close $s;
#$s = IO::Socket::INET->new("10.2.0.130:80");
#$s->send ("\ePASS\eq\r");
#$s->recv($text,128);
#print($text);
#close $s;
