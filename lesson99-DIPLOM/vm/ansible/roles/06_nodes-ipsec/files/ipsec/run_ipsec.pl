#!/usr/local/bin/perl
#version 2021-02-30-13-40 https
use strict;
use warnings;
use Data::Dumper;
sub fillSett();
sub setRoutes();
sub setIpsec();
sub setRacoon();
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
my $my_name_f = "${conf_dir}my_name\.txt";
mkdir "${conf_dir}tmp" unless (-d "${conf_dir}tmp");
my $sett_f = "${conf_dir}tmp/settings.conf";
die "No file $my_name_f " unless ( -e $my_name_f);



my %sett = ();
my $last_update = "";


if ($run_fetch)
{
	my $fetch = 'fetch ';
	if (`fetch -v 2>&1 | grep no-verify-peer`)
	{
		$fetch.= '--no-verify-peer ';
	}
	$fetch.= "-o ${conf_dir}tmp ".'https://user:user@10.99.1.222/settings.conf';
	print $fetch,"\n";
	runSystem($fetch);
}

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

#fill global hash with settings
fillSett();
checkDisable();
if (!isActualVersion() || $force == 1)
{
	$last_update = localtime;
	$last_update.= "-version:$sett{version}";
	setRoutes();
	setIpsec();
	setRacoon();
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
	print "--fillSett--\n";
	$sett{my_name} = `cat $my_name_f`;
	chomp($sett{my_name});
	$my_name = $sett{my_name};

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
	#$sett{ipsec_nets} = {};
	$sett{int_ip} = $sett{leaves}{$my_name}{int_ip};
	$sett{ext_ip} = $sett{leaves}{$my_name}{ext_ip};
	$sett{my_nets} = $sett{leaves}{$my_name}{routes};
	my $star_name = $sett{star_name};
	if ($sett{leaves}{$star_name}{ext_ip})
	{
		$sett{star_ip} = $sett{leaves}{$star_name}{ext_ip};
	}
	else
	{
		die "No star_name $star_name in settings";
	}

	print Dumper(\%sett);
}


sub setRoutes()
{
print "\n--setRoutes--\n";
my $routes_f = "${conf_dir}routes.sh";
open ROUTES, ">$routes_f" or print "Can't open file $routes_f: $!\n";

print ROUTES "#!/usr/local/bin/bash\n";
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
my  $rc_local= "/etc/rc.local";
my $grp = "grep \'$routes_f\' $rc_local";
if (!(-e $rc_local))
{
	`echo '\#\!/usr/local/bin/bash' >$rc_local`;
	`echo "$routes_f" >>$rc_local`;
}
elsif (!`$grp`) {
		`echo "$routes_f" >>$rc_local`;
}
`chmod +x $rc_local`;
runSystem("$routes_f");
}

sub setIpsec()
{
	print "\n----setIPsec----\n";
	my $ipsec_f = "/etc/ipsec.conf";
	my $str = "flush;\n";
	$str.= "spdflush;\n";

	if ($my_name eq $sett{star_name}) # if Am I the Star?
	{

		my @star_exclude_leaves = ();
		if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
		{
			@star_exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
		}

		foreach my $in_name (sort { $a cmp $b } keys %{ $sett{leaves} } )

		{
			next if ($in_name eq $my_name);

			$str.= "#----STAR -->".uc($in_name)."\n";

			if ($in_name ~~ @star_exclude_leaves)
			{
				$str.= "# --$in_name found in exclude_leaves_star:(". join(',',@star_exclude_leaves).") miss it\n";
				next;
			}


			my @exclude_leaves_in_name = ();
			if ( exists $sett{leaves}{$in_name}{exclude_leaves} )
			{
				@exclude_leaves_in_name = @{$sett{leaves}{$in_name}{exclude_leaves}};
			}

			foreach my $net_in ( sort { $a cmp $b }  @{ $sett{leaves}{$in_name}{routes} })
			{

				foreach my $out_name (sort { $a cmp $b } keys %{ $sett{leaves} } )
				{
					next if ($in_name eq $out_name );

					my $begin_line = "";
					my $fix_out_name = $out_name;
					if ($out_name ~~ @exclude_leaves_in_name)
					{
						$begin_line = "# ";
						$fix_out_name.= " (found in exlude_leaves for leaf: $in_name)";
					}
					if ($out_name ~~ @star_exclude_leaves)
					{
						$begin_line = "# ";
						$fix_out_name.= " (found in exlude_leaves for star: $my_name)";
					}

					my $bn = 0;
					foreach my $net_out ( sort { $a cmp $b } @{ $sett{leaves}{$out_name}{routes} })
					{
						if (!$bn){
							$str.= "\n\# from $fix_out_name \n";
							$bn = 1;
						}
						my $ipsec_ext_ip = $sett{leaves}{$in_name}{ext_ip};
						$str.= $begin_line."spdadd $net_out $net_in any -P out ipsec esp/tunnel/$sett{star_ip}-$ipsec_ext_ip/require;\n";
						$str.= $begin_line."spdadd $net_in $net_out any -P in ipsec esp/tunnel/$ipsec_ext_ip-$sett{star_ip}/require;\n\n";
					}
				}
			}
		}
	}
	else # if not the star
	{
		my @exclude_leaves = ();
		if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
		{
			@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
		}


		foreach my $name (sort { $sett{leaves}{$a}{routes}[0] cmp $sett{leaves}{$b}{routes}[0] } keys %{ $sett{leaves} } )
		{
			next if ($name eq $my_name );

			my $begin_line = "";
			my $fix_name = $name;
			if ($name ~~ @exclude_leaves)
			{
				$begin_line = "# ";
				$fix_name.= " (found in exlude_leaves)";
			}

			$str.= "\n\# $fix_name\n";
			foreach my $ipsec_net ( @{ $sett{leaves}{$name}{routes} })
			{
				foreach my $my_net (@{$sett{my_nets}})
				{
					$str.= $begin_line."spdadd $my_net $ipsec_net any -P out ipsec esp/tunnel/$sett{ext_ip}-$sett{star_ip}/require;\n";
					$str.= $begin_line."spdadd $ipsec_net $my_net any -P in ipsec esp/tunnel/$sett{star_ip}-$sett{ext_ip}/require;\n\n";
				}
			}
		}
	}
	print $str;
	open IPSEC, ">$ipsec_f" or print "Can't open file $ipsec_f: $!\n";
	print IPSEC "#-----$last_update------#\n";
	print IPSEC $str;
	close IPSEC;
	`/etc/rc.d/ipsec stop`;
	runSystem("/etc/rc.d/ipsec start");
}

sub setRacoon()
{
	print "\n----setRacoon----\n";
	my $racoon_f = "/usr/local/etc/racoon/racoon.conf";
	my $racoon_templ =
<<"END_RACOON";
#-----$last_update------#
path include "/usr/local/etc/racoon" ;
path pre_shared_key "/usr/local/etc/racoon/psk.txt" ;
#log error ;
log warning ;
padding {
        maximum_length 20 ;
        randomize off ;
        strict_check off ;
        exclusive_tail off ;
}

listen {
        isakmp $sett{ext_ip} [500] ;
}

timer {
        counter 5 ;
        interval 20 sec ;
        persend 1 ;
        phase1 30 sec ;
        phase2 15 sec ;
}

END_RACOON
my $racoon_peer =
<<"END_RACOON";
{
        exchange_mode main,aggressive;
        lifetime time 24 hour;
        doi ipsec_doi;
        situation identity_only;
        nonce_size 16;
        initial_contact on;
        proposal_check obey;

        proposal {
                encryption_algorithm aes 256;
                hash_algorithm sha1;
                authentication_method pre_shared_key;
                dh_group 2;
        }
}
END_RACOON

my @exclude_leaves = ();
if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
{
	@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
}


if ($my_name eq $sett{star_name}) # if Am I the Star?
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
			$racoon_templ.="# $name in exclude_leaves miss it\n\n";
		}
		else {
			$racoon_templ.="# $name\n remote $sett{leaves}{$name}{ext_ip}\n";
			$racoon_templ.=$racoon_peer;
		}
	}
}
else
{

		my $star_name = $sett{star_name};

		if ($star_name ~~ @exclude_leaves)
		{
			$racoon_templ.="# $sett{star_name}\n # remote $sett{star_ip} found in exclude_leaves for $my_name miss it \n\n";
		}
		else
		{
			$racoon_templ.="# $sett{star_name}\nremote $sett{star_ip}\n";
			$racoon_templ.=$racoon_peer;
		}

}

$racoon_templ .=
<<"END_RACOON";
sainfo anonymous
{
        pfs_group 2;
        lifetime time 60 sec;
        encryption_algorithm aes 256 ;
        authentication_algorithm hmac_sha1 ;
        compression_algorithm deflate ;
}
END_RACOON


	open RACOON, ">$racoon_f" or print "Can't open file $racoon_f: $!\n";
	print RACOON $racoon_templ;
	close RACOON;
	print $racoon_templ;
	setPsk();
	`/usr/local/etc/rc.d/racoon stop`;
	runSystem("/usr/local/etc/rc.d/racoon start");

}


sub setPsk()
{
	print "\n----setPsk----\n";
	my $psk_f = "/usr/local/etc/racoon/psk.txt";
	my $fix = `cat ${conf_dir}fixpsk.txt`;
	#print $fix;
	my $str;

	my @exclude_leaves = ();
	if ( exists $sett{leaves}{$my_name}{exclude_leaves} )
	{
		@exclude_leaves = @{$sett{leaves}{$my_name}{exclude_leaves}};
	}


  	if ($my_name eq $sett{star_name}) # if Am I the Star?
	{
		foreach my $name (sort { $a cmp $b } keys %{ $sett{leaves} } )
		{
			next if ($name eq $my_name );
			my $begin_line = "";

			if ($name ~~ @exclude_leaves)
			{
				$begin_line = "# found in exlude_leaves for $my_name ";
			}



			my $hsh = crypt($sett{star_name}.$name, $fix);
			if (length($hsh)>7)
			{
				$hsh = substr($hsh,2,5);
			}
				$str.= $begin_line."$sett{leaves}{$name}{ext_ip} $sett{star_name}"."_".$name."_".$hsh."\n";
		}
	}
	else
	{
		my $hsh = crypt($sett{star_name}.$sett{my_name}, $fix);
		if (length($hsh)>7){
			$hsh = substr($hsh,2,5);
		}
		$str = "$sett{star_ip} $sett{star_name}"."_".$sett{my_name}."_".$hsh."\n";
	}
	print $str;

	open PSK, ">$psk_f" or print "Can't open file $psk_f: $!\n";
	print PSK "#-----$last_update------#\n\n";
	print PSK $str;
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
				`/usr/local/etc/rc.d/racoon stop`;
				`/etc/rc.d/ipsec stop`;
				`echo "" > /usr/local/etc/racoon/ipsec.conf`;
				`echo "" > /usr/local/etc/racoon/racoon.conf`;
				`rm -f /data/config/tmp/previous_ver.tmp`;
				exit 1;

			}
		}
	}
}
