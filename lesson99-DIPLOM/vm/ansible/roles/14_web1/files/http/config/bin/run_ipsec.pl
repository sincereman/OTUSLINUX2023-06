#!/usr/local/bin/perl
#version 2024-02-30-13-40 https
use strict;
use warnings;
use Data::Dumper;
use Sys::Hostname;

sub fillSett();
sub setRoutes();
sub setIpsec();
sub setIpsecConf();
sub isActualVersion;
sub runSystem($);
sub checkDisable();



# change it
my $conf_dir = "/data/config/";
#for tests
#$conf_dir = "/data/node11/";
my $run_fetch=1;
# change it end

my $previous_f = "${conf_dir}tmp/previous_ver.tmp"; #previos version of exchange
#my $my_name_f = "${conf_dir}my_name\.txt";

print "\n ############ ComputerName#######################\n";
my $my_name_f = hostname;
print $my_name_f,"\n";

print "###################################################\n";

mkdir "${conf_dir}tmp" unless (-d "${conf_dir}tmp");
my $sett_f = "${conf_dir}tmp/settings.conf";
#die "No file $my_name_f " unless ( -e $my_name_f);




my %sett = ();
my $last_update = "";


print "\n ############ Download ${conf_dir}tmp/settings\.conf #######################\n";

if ($run_fetch)
{


	my $fetch = 'curl --silent ';
    if (`curl --help all 2>&1 | grep -insecure`)
    {
	$fetch.= '--insecure '; 
    }
	$fetch.= "-o ${conf_dir}tmp/settings\.conf ".'https://user:user@10.99.1.225/config/bin/settings.conf';
	print $fetch,"\n";
	runSystem($fetch);
}


print "#######################End ${conf_dir}tmp/settings\.conf############################\n";

my $force = 0;
my $my_name = '';
while (my $arg = shift @ARGV)
{
	if ($arg eq "-force")
	{
		$force = 1;
	}
}
#print "force = $force\n";

#test2

#fill global hash with settings

fillSett();

checkDisable();

if (!isActualVersion() || $force == 1)
{
	$last_update = localtime;
	$last_update.= "-version:$sett{version}";
	setRoutes();
	setIpsecConf();
	# After it all above done
	`echo $sett{version}>$previous_f`;
}

sub trim ($)
{
	my $str =shift;
	if ($str)
	{
		$str =~ s/^\s+|\s+$//g;
	}
	return $str;
}

sub fillSett()
{

	print "########################Sub FilSett###########################\n";
	print "--fillSett--\n";
	$sett{my_name} = $my_name_f;
	chomp($sett{my_name});
	$my_name = $sett{my_name};

print "############################Open settings.conf#######################\n";
	open SETT, "<$sett_f" or die "Can't open file $sett_f: $!\n";
	while (my $line =<SETT>)
	{
		next if ( ($line =~/^\#/) || ($line =~/^$/));
		print $line;
		$line = trim($line);
		chomp($line);
		my @ar = split "=",$line;
		$ar[0]=trim($ar[0]);
		if ($ar[0] =~/^route_(\S+)/)
		{
			my $name =$1;
			if (! exists $sett{leaves}{$name} )
			{
				$sett{leaves}{$name}{routes} = [];
			}
			#route_node11=192.168.11.0/24,10.4.5.0/24
			my @nets = split(',',$ar[1]);
			foreach  (@nets){
				push @{$sett{leaves}{$name}{routes}}, $_;
			}
			next;
		}
		elsif ($ar[0] =~/^ext_ip_(\S+)/)
		{
			my $name =$1;
			if (! exists $sett{leaves}{$name} )
			{
				$sett{leaves}{$name}{routes} = [];
			}
			$sett{leaves}{$name}{ext_ip} = $ar[1];
			next;
		}
		elsif ($ar[0] =~/^int_ip_(\S+)/)
		{
			my $name =$1;
			if (! exists $sett{leaves}{$name} )
			{
				$sett{leaves}{$name}{routes} = [];
			}
			$sett{leaves}{$name}{int_ip} = $ar[1];
			next;
		}
		elsif ($ar[0] =~/^exclude_leaves_(\S+)/)
		{
			my $name = $1;
			if (! exists $sett{leaves}{$name} )
			{
				$sett{leaves}{$name}{exclude_leaves} = [];
			}
			#exclude_leaves_node11=node14,node15
			my @leaves = split(',',$ar[1]);
			foreach  (@leaves)
			{
				push @{$sett{leaves}{$name}{exclude_leaves}}, trim($_);
			}
			next;
		}
		$sett{$ar[0]} = trim($ar[1]);
	}
	close SETT;

print "\n ########################Close settings.conf###########################\n";
	#$sett{ipsec_nets} = {};
	$sett{int_ip} = $sett{leaves}{$my_name}{int_ip};
	$sett{ext_ip} = $sett{leaves}{$my_name}{ext_ip};
	$sett{my_nets} = $sett{leaves}{$my_name}{routes};
	#my $star_name = $sett{star_name};
	my $star_name = hostname;
	if ($sett{leaves}{$star_name}{ext_ip})
	{
		#$sett{star_ip} = $sett{leaves}{$star_name}{ext_ip};
		$sett{star_ip} = $sett{leaves}{$star_name}{ext_ip};
	}
	else
	{
		die "No star_name $star_name in settings";
	}

	print Dumper(\%sett);
print "\n ########################EndSubFillSett###########################\n";

}

sub setRoutes()
{
print "\n--setRoutes--\n";
my $routes_f = "${conf_dir}routes.sh";
open ROUTES, ">$routes_f" or print "Can't open file $routes_f: $!\n";

print ROUTES "#!/usr/bin/bash\n";
print ROUTES "#-----$last_update------#\n\n";

my @exclude_leaves = ();
if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
{
	@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
}

print ("\nmy_name:$my_name,exclude_leaves:",join(',',@exclude_leaves),"\n");
foreach my $name (keys %{$sett{leaves}})
{
	next if ($name eq $my_name );
	#print $key, "\n";


	foreach my $net ( @{$sett{leaves}{$name}{routes} } )
	{
		my $r0 = "route delete $net\n";
		my $r1 = "route add -net $net $sett{int_ip}\n";
		my $begin_line = "";
		my $fix_name = "# $name";
		if ($name ~~ @exclude_leaves)
		{
			$begin_line = "# ";
			$fix_name.= " (found in exlude_leaves)";
		}

		print ROUTES $fix_name."\n";
		print ROUTES $begin_line.$r0;
		print ROUTES $begin_line.$r1;

	}
	print ROUTES "\n";
}
close ROUTES;
`chmod +x $routes_f`;
#`$routes_f`;

#runSystem("$routes_f");
}


sub setIpsecConf()

{
	print "\n----SetIpsecConf----\n\n";
	 	my $ipsec_f = "/etc/ipsec.conf";

		my $ipsec_config = "";

 		my $ipsec_header =
<<"END_IPSEC_HEADER";

# #-----$last_update------#

config setup

        charondebug="all"
        uniqueids=yes

#############################

END_IPSEC_HEADER


 		my $ipsec_templ ="";


$ipsec_config.="$ipsec_header \n\n";

my @exclude_leaves = ();
if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
{
	@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
}


if ($my_name eq hostname) # if Am I the Star?
{
	foreach my $name (sort { $a cmp $b } keys %{ $sett{leaves} } )
	{
		next if ($name eq $my_name );

		my $begin_line = "";
		if ($name ~~ @exclude_leaves)
		{
			$begin_line = "# ";
		}

		if ($begin_line)
		{
			$ipsec_templ.="# $name in exclude_leaves miss it\n\n";
		}
		else {
			$ipsec_templ.="conn $my_name-$name\n";

			foreach my $net ( @{$sett{leaves}{$name}{routes} } )
	{
			$ipsec_templ.=
<<"END_IPSEC";
	type=tunnel
	auto=start
	keyexchange=ikev2
	authby=secret
	#$my_name
	left=$sett{leaves}{$my_name}{ext_ip}
	leftsubnet=@{$sett{leaves}{$my_name}{routes}}
	#$name
	right=$sett{leaves}{$name}{ext_ip}
	rightsubnet=@{$sett{leaves}{$name}{routes}}
	#cipher
	ike=aes256-sha1-modp1024!
	esp=aes256-sha1!
	aggressive=no
	keyingtries=%forever
	ikelifetime=28800s
	lifetime=3600s
	dpddelay=30s
	dpdtimeout=120s
	dpdaction=restart

END_IPSEC

		}
	}
}
}

$ipsec_config.="$ipsec_templ \n\n";

	open IPSECCONF, ">$ipsec_f" or print "Can't open file $ipsec_f: $!\n";
	print IPSECCONF $ipsec_config;
	close IPSECCONF;
	print $ipsec_config;
	setPsk();
	#`systemctl restart ipsec`;
	runSystem("systemctl start ipsec");


}





sub setPsk()
{
	print "\n----setPsk----\n";
	my $psk_f = "/etc/ipsec.secrets";
	my $psk_config;
	my $psk_header =
<<"END_PSK_HEADER";

# #-----$last_update------#
#############################

#PRESHARED KEY LEAVES

#############################

END_PSK_HEADER


 	my $psk_templ ="";


    $psk_config.="$psk_header \n\n";

my @exclude_leaves = ();
if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
{
	@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
}


if ($my_name eq hostname) # ?
{
	foreach my $name (sort { $a cmp $b } keys %{ $sett{leaves} } )
	{
		next if ($name eq $my_name );

		my $begin_line = "";
		if ($name ~~ @exclude_leaves)
		{
			$begin_line = "# ";
		}

		if ($begin_line)
		{
			$psk_templ.="# $name in exclude_leaves miss it\n\n";
		}
		else {


			foreach my $net ( @{$sett{leaves}{$name}{routes} } )
	{
			$psk_templ.=
<<"END_PSK";
####  $my_name-$name  ####

$sett{leaves}{$my_name}{ext_ip} $sett{leaves}{$name}{ext_ip} : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="
    
####  $name-$my_name  ####

$sett{leaves}{$name}{ext_ip} $sett{leaves}{$my_name}{ext_ip} : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="	
	

END_PSK

		}
	}
}
}

$psk_config.="$psk_templ \n\n";
	print $psk_config;

	open PSK, ">$psk_f" or print "Can't open file $psk_f: $!\n";
	print PSK "#-----$last_update------#\n\n";
	print PSK $psk_config;
	close PSK;
	`chmod 600 $psk_f`;

}



sub isActualVersion
{
	print "\n----isActualVersion----\n";
	my $previous_ver = `cat $previous_f`;
	chomp($previous_ver);
	return 0 if (!$previous_ver);

	my $new_ver =$sett{version}+0.0;
	$previous_ver =$previous_ver+0.0;
	print "new_ver=$new_ver\n";
	print "prev_ver=$previous_ver\n";
	if (($new_ver - $previous_ver)>0.001){
		return 0;
	}
	else {
		return 1;
	}
}



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

sub checkDisable()
{
	print "-----checkDisable-----\n";
	foreach my $name (split(',',$sett{star_disable}))
	{
		print $name,"\n";
		$name = trim($name);
		chomp($name);
		if (($name eq $my_name) || ($name eq 'all'))
		{
			print "my_name $name is disabled, exit\n";
			if(1)
			{
				`systemctl ipsec stop`;
				`echo "" > /etc/ipsec.conf`;
				`echo "" > /etc/ipsec/ipsec.secrets`;
				`rm -f /data/config/tmp/previous_ver.tmp`;
				exit 1;

			}
		}
	}
}
