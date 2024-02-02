#!/usr/local/bin/perl
#version 2024-02-30-13-40 https root
use strict;
use warnings;
#use Data::Dumper;
sub runSystem($);


print "\n ####################START################## \n";


my $conf_dir = "/data/config/";
mkdir "${conf_dir}tmp" unless (-d "${conf_dir}tmp");
my $fetch = 'curl -f --silent ';
if (`curl --help all 2>&1 | grep -insecure`)
{
	$fetch.= '--insecure '; 
}


print "\n ####################run_ipsec.pl################## \n";

#check a new version of fetch run_ipsec.pl to bin
my $fetchrunbin = '';
if (-e "${conf_dir}bin/run_ipsec\.pl"){
print "File ${conf_dir}bin/run_ipsec\.pl already exist\n";
}
else{
$fetchrunbin = $fetch . "-o ${conf_dir}bin/run_ipsec\.pl ".'https://user:user@10.99.1.225/config/bin/run_ipsec.pl';
print $fetchrunbin,"\n";
runSystem($fetchrunbin);
}

#check a new version of fetch run_ipsec.pl to tmp
my $fetchruntmp = '';
$fetchruntmp = $fetch . "-o ${conf_dir}tmp/run_ipsec\.pl ".'https://user:user@10.99.1.225/config/bin/run_ipsec.pl';
print $fetchruntmp,"\n";
runSystem($fetchruntmp);


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




print "\n ####################update_run.pl################## \n";


#check a new version of fetch update_run.pl to bin
my $fetchupdatebin = '';
if (-e "${conf_dir}bin/update_run\.pl"){
print "File ${conf_dir}bin/update_run\.pl already exist\n";
}
else{
$fetchupdatebin = $fetch . "-o ${conf_dir}bin/update_run\.pl ".'https://user:user@10.99.1.225/config/bin/update_run.pl';
print $fetchupdatebin,"\n";
runSystem($fetchupdatebin);
}


#check a new version of fetch update_run.pl
my $fetchupdatetmp='';
$fetchupdatetmp = $fetch . "-o ${conf_dir}tmp/update_run\.pl ".'https://user:user@10.99.1.225/config/bin/update_run.pl';
print $fetchupdatetmp,"\n";
runSystem($fetchupdatetmp);


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


print "\n ####################END################## \n";
