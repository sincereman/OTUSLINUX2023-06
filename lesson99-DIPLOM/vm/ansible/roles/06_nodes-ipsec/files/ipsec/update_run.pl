#!/usr/local/bin/perl
#version 2024-02-30-13-40 https root
use strict;
use warnings;
#use Data::Dumper;
sub runSystem($);

my $conf_dir = "/data/config/";
mkdir "${conf_dir}tmp" unless (-d "${conf_dir}tmp");
my $fetch = 'fetch ';
if (`fetch -v 2>&1 | grep no-verify-peer`)
{
	$fetch.= '--no-verify-peer '; 
}


#check a new version of fetch run_ipsec.pl
my $fetchrun = '';
$fetchrun = $fetch . "-o ${conf_dir}tmp/run_ipsec\.pl ".'https://user:user@10.99.1.222/run_ipsec.pl';
print $fetchrun,"\n";
runSystem($fetchrun);

if (-e "${conf_dir}tmp/run_ipsec\.pl" && -e "${conf_dir}bin/run_ipsec\.pl")
{
	my $diffc = "diff -ruN ${conf_dir}tmp/run_ipsec\.pl ${conf_dir}bin/run_ipsec\.pl";
	my $diff=`$diffc`;
	#print $diff;
	if ($diff)
	{
		`cp -f ${conf_dir}tmp/run_ipsec\.pl ${conf_dir}bin/run_ipsec\.pl` ;
		print "\nUpdated ${conf_dir}bin/run_ipsec\.pl\n";
	}
	else{
	print "\nNot Updated ${conf_dir}bin/run_ipsec\.pl\n";
	}
}
 `chmod +x ${conf_dir}bin/run_ipsec\.pl`;
 `chown root ${conf_dir}bin/run_ipsec\.pl`;


#check a new version of fetch update_run.pl
my $fetchupdate='';
$fetchupdate = $fetch . "-o ${conf_dir}tmp/update_run\.pl ".'https://user:user@10.99.1.222/update_run.pl';
print $fetchupdate,"\n";
runSystem($fetchupdate);

if (-e "${conf_dir}tmp/update_run\.pl" && -e "${conf_dir}bin/update_run\.pl")
{
        my $diffc = "diff -ruN ${conf_dir}tmp/update_run\.pl ${conf_dir}bin/update_run\.pl";
        my $diff=`$diffc`;
        #print $diff;
        if ($diff)
        {
                `cp -f ${conf_dir}tmp/update_run\.pl ${conf_dir}bin/update_run\.pl` ;
                print "\nUpdated ${conf_dir}bin/update_run\.pl\n";
        }
        else{
        print "\nNot Updated ${conf_dir}bin/update_run\.pl\n";
        }
}
 `chmod +x ${conf_dir}bin/update_run\.pl`;
 `chown root ${conf_dir}bin/update_run\.pl`;

sub runSystem($)
{		
	my $run = shift;
	system($run);
	if ( ($? >> 8) != 0 )
	{
		printf "command exited with value %d", $? >> 8;
  		exit 1;
	}
}
