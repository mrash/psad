#!/usr/bin/perl -w

# TODO:  - clean up preserve_config() to take variable type changes into
#          account.  Recall the 'if (defined $hash{one}{two})' test will 
#	   automatically define $hash{one} if it did not exist before the
#	   test.
#	 - clean up check_firewall_rules() to support tcp and/or udp 

#============== config ===============
my $SYSLOG_INIT = "/etc/rc.d/init.d/syslog";

my $killCmd = "/bin/kill";
my $psCmd = "/bin/ps";
my $touchCmd = "/bin/touch";
my $mknodCmd = "/bin/mknod";
my $grepCmd = "/bin/grep";
my $makeCmd = "/usr/bin/make";
my $cpCmd = "/bin/cp";
my $mvCmd = "/bin/mv";
my $rmCmd = "/bin/rm";
my $unameCmd = "/bin/uname";
my $ifconfigCmd = "/sbin/ifconfig";
my $ipchainsCmd = "/sbin/ipchains";
my $iptablesCmd = "/usr/local/bin/iptables";
#============ end config ============

use Getopt::Long;

my $fwcheck = 0;
my $execute_psad = 0;
my $nopreserve = 0;
my $uninstall = 0;

usage_and_exit(1) unless (GetOptions (
	'no_preserve'		=> \$nopreserve,	# don't preserve existing configs
        'firewall_check'	=> \$fwcheck,           # do not check firewall rules
	'exec_psad'		=> \$execute_psad,
	'uninstall'		=> \$uninstall,
	'verbose'		=> \$verbose,
        'help'          	=> \$help,              # display help
));
usage_and_exit(0) if ($help);

my %Cmds = (
	"kill"		=> $killCmd,
	"ps"		=> $psCmd,
	"touch"		=> $touchCmd,
	"mknod"         => $mknodCmd,
	"grep"		=> $grepCmd,
	"cp"		=> $cpCmd,
	"mv"		=> $mvCmd,
	"rm" 		=> $rmCmd,
	"uname"		=> $unameCmd,
	"make"		=> $makeCmd,
	"ifconfig"	=> $ifconfigCmd,
	"ipchains"      => $ipchainsCmd,
	"iptables"	=> $iptablesCmd
);

%Cmds = check_commands(\%Cmds);

$< == 0 && $> == 0 or die "You need to be root (or equivalent UID 0 account) to install psad!\n";

if ($uninstall) {
	my $ans = "";
	while ($ans ne "y" && $ans ne "n") {
		print "=-=-=  This will completely psad from your system.  Are you sure (y/n)?  ";
		$ans = <STDIN>;
		chomp $ans;
	}
	exit 0 if ($ans eq "n");
	if (-e "/etc/rc.d/init.d/psad-init") {
		print "=-=-=  Stopping psad daemons\n";
		system("/etc/rc.d/init.d/psad-init stop") or warn "=-=-=  Could not stop psad daemons!\n";
		print "=-=-=  Removing /etc/rc.d/init.d/psad-init\n";
		unlink "/etc/rc.d/init.d/psad-init";
	}	
	if (-e "/usr/local/bin/psad") {
		print "=-=-=  Removing psad daemons: /usr/local/bin/(psad, psadwatchd, kmsgsd, diskmond)\n";
		unlink "/usr/local/bin/psad" or warn "=-=-=  Could not remove /usr/local/bin/psad!!!\n";
		unlink "/usr/local/bin/psadwatchd" or warn "=-=-=  Could not remove /usr/local/bin/psadwatchd!!!\n";
		unlink "/usr/local/bin/kmsgsd" or warn "=-=-=  Could not remove /usr/local/bin/kmsgsd!!!\n";
		unlink "/usr/local/bin/diskmond" or warn "=-=-=  Could not remove /usr/local/bin/diskmond!!!\n";
	}
	if (-e "/etc/psad") {
		print "=-=-=  Removing configuration directory: /etc/psad\n";
		# "rm -rf" is easier than checking to make sure the directory is empty and then using perl's rmdir
		`$Cmds{'rm'} -rf /etc/psad`;
	}
	if (-e "/var/log/psad") {
		print "=-=-=  Removing logging directory: /var/log/psad\n";
		`$Cmds{'rm'} -rf /var/log/psad`;
	}
	if (-e "/var/log/psadfifo") {
		print "=-=-=  Removing named pipe: /var/log/psadfifo\n";
		unlink "/var/log/psadfifo";
	}
	if (-e "/usr/local/bin/whois.psad") {
		print "=-=-=  Removing /usr/local/bin/whois.psad\n";
		unlink "/usr/local/bin/whois.psad";
	}
	print "=-=-=  Restoring /etc/syslog.conf.orig -> /etc/syslog.conf\n";
	if (-e "/etc/syslog.conf.orig") {
		`$Cmds{'mv'} /etc/syslog.conf.orig /etc/syslog.conf`;
	} else {
		print "=-=-= /etc/syslog.conf.orig does not exist.  Editing /etc/syslog.conf directly\n";
		open ESYS, "< /etc/syslog.conf" or die "=-=-= Unable to open /etc/syslog.conf: $!\n";
		my @sys = <ESYS>;
		close ESYS;
		open CSYS, "> /etc/syslog.conf";
		foreach my $s (@sys) {
			chomp $s;
			print CSYS "$s\n" if ($s !~ /psadfifo/);
		}
		close CSYS;
	}
	print "=-=-=  Restarting syslog...\n";
	system("$SYSLOG_INIT restart");
	print "\n";
	print "=-=-=  Psad has been uninstalled =-=-=\n";
	exit 0;
}
### Start the install code...
unless (-e "/var/log/psadfifo") {
	print "=-=-=  Creating named pipe /var/log/psadfifo\n";
	# create the named pipe
	`$Cmds{'mknod'} -m 600 /var/log/psadfifo p`;	#  die does not seem to work right here.
}
unless (`$Cmds{'grep'} psadfifo /etc/syslog.conf`) {
	print "=-=-=  Modifying /etc/syslog.conf\n";
	`$Cmds{'cp'} /etc/syslog.conf /etc/syslog.conf.orig` unless (-e "/etc/syslog.conf.orig");	
	open SYSLOG, ">> /etc/syslog.conf" or die "=-=-=  Unable to open /etc/syslog.conf: $!\n";
	print SYSLOG "kern.info  |/var/log/psadfifo\n\n";  #reinstate kernel logging to our named pipe
	close SYSLOG;
	print "=-=-=  Restarting syslog\n";
	system("$SYSLOG_INIT restart");
}
unless (-e "/var/log/psad") {
	print "=-=-=  Creating /var/log/psad/\n";
	mkdir "/var/log/psad",400;
}
unless (-e "/var/log/psad/fwdata") {
	print "=-=-=  Creating /var/log/psad/fwdata file\n";
	`$Cmds{'touch'} /var/log/psad/fwdata`;
	chmod 0600, "/var/log/psad/fwdata";
	perms_ownership("/var/log/psad/fwdata", 0600);
}
unless (-e "/usr/local/bin") {
	print "=-=-=  Creating /usr/local/bin/\n";
	mkdir "/usr/local/bin",755;
}
unless (-e "/usr/local/bin/whois.psad") {
	if (-e "whois-4.5.6") {
		print "=-=-=  Compiling Marco d'Itri's whois client\n";
		if (! system("$Cmds{'make'} -C whois-4.5.6")) {  # remember unix return value...
			print "=-=-=  Copying whois binary to /usr/local/bin/whois.psad\n";
			`$Cmds{'cp'} whois-4.5.6/whois /usr/local/bin/whois.psad`;
		}
	}
}
if ( -e "/usr/local/bin/psad" && (! $nopreserve)) {  # need to grab the old config
	print "=-=-=  Copying psad -> /usr/local/bin/psad\n";
	print "       Preserving old config within /usr/local/bin/psad\n";
	preserve_config("psad", "/usr/local/bin/psad", \%Cmds);
	perms_ownership("/usr/local/bin/psad", 0500)
} else {
	print "=-=-=  Copying psad -> /usr/local/bin/\n";
	`$Cmds{'cp'} psad /usr/local/bin/psad`;
	perms_ownership("/usr/local/bin/psad", 0500);
}
if ( -e "/usr/local/bin/psadwatchd" && (! $nopreserve)) {  # need to grab the old config
        print "=-=-=  Copying psadwatchd -> /usr/local/bin/psadwatchd\n";
        print "       Preserving old config within /usr/local/bin/psadwatchd\n";
        preserve_config("psadwatchd", "/usr/local/bin/psadwatchd", \%Cmds);
        perms_ownership("/usr/local/bin/psadwatchd", 0500)
} else {
        print "=-=-=  Copying psadwatchd -> /usr/local/bin/\n";
        `$Cmds{'cp'} psadwatchd /usr/local/bin/psadwatchd`;
        perms_ownership("/usr/local/bin/psadwatchd", 0500);
}
if (-e "/usr/local/bin/kmsgsd" && (! $nopreserve)) { 
	print "=-=-=  Copying kmsgsd -> /usr/local/bin/kmsgsd\n";
	print "       Preserving old config within /usr/local/bin/kmsgsd\n";
	preserve_config("kmsgsd", "/usr/local/bin/kmsgsd", \%Cmds);
	perms_ownership("/usr/local/bin/kmsgsd", 0500);
} else {
	print "=-=-=  Copying kmsgsd -> /usr/local/bin/kmsgsd\n";
	`$Cmds{'cp'} kmsgsd /usr/local/bin/kmsgsd`;
	perms_ownership("/usr/local/bin/kmsgsd", 0500);
}
if (-e "/usr/local/bin/diskmond" && (! $nopreserve)) {
	print "=-=-=  Copying diskmond -> /usr/local/bin/diskmond\n";
	print "       Preserving old config within /usr/local/bin/diskmond\n";
        preserve_config("diskmond", "/usr/local/bin/diskmond", \%Cmds);
        perms_ownership("/usr/local/bin/diskmond", 0500);
} else {
	print "=-=-=  Copying diskmond -> /usr/local/bin/diskmond\n";
	`$Cmds{'cp'} diskmond /usr/local/bin/diskmond`;
	perms_ownership("/usr/local/bin/diskmond", 0500);
}
unless (-e "/etc/psad") {
        print "=-=-=  Creating /etc/psad/\n";
        mkdir "/etc/psad",400;
}
if (-e "/etc/psad/psad_signatures") {
	print "=-=-=  Copying psad_signatures -> /etc/psad/psad_signatures\n";
	print "       Preserving old signatures file as /etc/psad/psad_signatures.old\n";
	`$Cmds{'mv'} /etc/psad/psad_signatures /etc/psad/psad_signatures.old`;
	`$Cmds{'cp'} psad_signatures /etc/psad/psad_signatures`;
	perms_ownership("/etc/psad/psad_signatures", 0600);
} else {
	print "=-=-=  Copying psad_signatures -> /etc/psad/psad_signatures\n";
	`$Cmds{'cp'} psad_signatures /etc/psad/psad_signatures`;
	perms_ownership("/etc/psad/psad_signatures", 0600);
}
if (-e "/etc/psad/psad_auto_ips") {
	print "=-=-=  Copying psad_auto_ips -> /etc/psad/psad_auto_ips\n";
	print "       Preserving old auto_ips file as /etc/psad/psad_auto_ips.old\n";
	`$Cmds{'mv'} /etc/psad/psad_auto_ips /etc/psad/psad_auto_ips.old`;
	`$Cmds{'cp'} psad_auto_ips /etc/psad/psad_auto_ips`;
	perms_ownership("/etc/psad/psad_auto_ips", 0600);
} else {
	print "=-=-=  Copying psad_auto_ips -> /etc/psad/psad_auto_ips\n";
	`$Cmds{'cp'} psad_auto_ips /etc/psad/psad_auto_ips`;
	perms_ownership("/etc/psad/psad_auto_ips", 0600);
}
if (-e "/etc/psad/psad.conf") {
	print "=-=-=  Copying psad.conf -> /etc/psad/psad.conf\n";
	print "       Preserving old psad.conf file as /etc/psad/psad.conf\n";
	`$Cmds{'mv'} /etc/psad/psad.conf /etc/psad/psad.conf.old`;
	`$Cmds{'cp'} psad.conf /etc/psad/psad.conf`;
	perms_ownership("/etc/psad/psad.conf", 0600);
} else {
	print "=-=-=  Copying psad.conf -> /etc/psad/psad.conf\n";
	`$Cmds{'cp'} psad.conf /etc/psad/psad.conf`;
	perms_ownership("/etc/psad/psad.conf", 0600);
}

my $distro = get_distro();
my $kernel = get_kernel(\%Cmds);

if ($distro eq "redhat61" || $distro eq "redhat62") {
	# remove signature checking from psad process if we are not running an iptables-enabled kernel
	print "=-=-=  Copying psad-init -> /etc/rc.d/init.d/psad-init\n";
	`$Cmds{'cp'} psad-init /etc/rc.d/init.d/psad-init`;
	system "perl -p -i -e 's|\\-s\\s/etc/psad/psad_signatures||' /etc/rc.d/init.d/psad-init" if ($kernel !~ /^2.3/ && $kernel !~ /^2.4/);
} 
# need to put checks in here for redhat vs. other systems.
unless($fwcheck) {
	if(check_firewall_rules(\%Cmds)) {
		my $pidstatement = `$Cmds{'ps'} -auxw |$Cmds{'grep'} psad |$Cmds{'grep'} -v grep`;
		if ($execute_psad) {
			if ($distro eq "redhat61" || $distro eq "redhat62") {
				if ($pidstatement) {
					print "=-=-=  Restarting the psad daemons...\n";
					system "/etc/rc.d/init.d/psad-init restart";
				} else {
					print "=-=-=  Starting the psad daemons...\n";
					system "/etc/rc.d/init.d/psad-init start";
				}
			} else {
				if ($pidstatement) {
					print "=-=-=  Restarting the psad daemons...\n";
					my $pid = (split /\s+/, $pidstatement)[1];
					system "$Cmds{'kill'} $pid";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
						system "/usr/local/bin/kmsgsd";
                                                system "/usr/local/bin/psad -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips";
						system "/usr/local/bin/diskmond";
						system "/usr/local/bin/psadwatchd";
                                        } elsif ($kernel =~ /^2.2/) {
						system "/usr/local/bin/kmsgsd";
                                                system "/usr/local/bin/psad -a /etc/psad/psad_auto_ips";
						system "/usr/local/bin/diskmond";
						system "/usr/local/bin/psadwatchd";
                                        } else {
                                                print "=-=-=  You are running kernel $kernel.  Assuming ipchains support.\n";
						system "/usr/local/bin/kmsgsd";
                                                system "/usr/local/bin/psad -a /etc/psad/psad_auto_ips";
						system "/usr/local/bin/diskmond";
						system "/usr/local/bin/psadwatchd";
                                        }
				} else {
					print "=-=-=  Starting the psad daemons...\n";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {	
                                        	system "/usr/local/bin/psad -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips";
					} elsif ($kernel =~ /^2.2/) {
						system "/usr/local/bin/psad -a /etc/psad/psad_auto_ips";
					} else {
						print "=-=-=  You are running kernel $kernel.  Assuming ipchains support.\n";
						system "/usr/local/bin/psad -a /etc/psad/psad_auto_ips";
					}
				}
			}
		} else {
			if ($distro eq "redhat61" || $distro eq "redhat62") {
				if ($pidstatement) {
					print "=-=-=  An older version of psad is already running.  To execute, run \"/etc/rc.d/init.d/psad-init restart\"\n";
				} else {
					print "=-=-=  To execute psad, run \"/etc/rc.d/init.d/psad-init start\"\n";
				}
			} else {
				if ($pidstatement) {
					my $pid = (split /\s+/, $pidstatement)[1];
					print "=-=-=  An older version of psad is already running.  kill pid $pid, and then execute:\n";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
                                       		print "/usr/local/bin/psad -s /etc/psad/psad_signatures, /usr/local/bin/psadwatchd,\n";
						print "/usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n"; 
                                        } elsif ($kernel =~ /^2.2/) {
						print "/usr/local/bin/psad, /usr/local/bin/psadwatchd, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
                                        } else {
						print "/usr/local/bin/psad (you are running kernel $kernel... assuming ipchains support),\n";
						print "/usr/local/bin/psadwatchd, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
                                        }
				} else {
                                	if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
                                                print "/usr/local/bin/psad -s /etc/psad/psad_signatures, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
                                        } elsif ($kernel =~ /^2.2/) {
                                                print "/usr/local/bin/psad, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
                                        } else {
                                                print "/usr/local/bin/psad (you are running kernel $kernel... assuming ipchains support),\n";
                                                print "/usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
					}
				}
			}	
		}
	} else {
		print "=-=-=  After setting up your firewall per the above note, execute \"/etc/rc.d/init.d/psad-init start\" to start psad\n";
	}
}
exit 0;
#==================== end main =====================
sub check_firewall_rules() {
	my $Cmds_href = shift;
	my @localips;
	my $kernel = get_kernel($Cmds_href);
        my $iptables = 1 if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/);
        my $ipchains = 1 if ($kernel =~ /^2.2/); # and also 2.0.x ?
	my @localips_tmp = `$Cmds_href->{'ifconfig'} -a |$Cmds_href->{'grep'} inet`;
 	push @localips, (split /:/, (split /\s+/, $_)[2])[1] foreach (@localips_tmp);
	if ($iptables) {
# target     prot opt source               destination
# LOG        tcp  --  anywhere             anywhere           tcp flags:SYN,RST,ACK/SYN LOG level warning prefix `DENY '
# DROP       tcp  --  anywhere             anywhere           tcp flags:SYN,RST,ACK/SYN

# ACCEPT     tcp  --  0.0.0.0/0            64.44.21.15        tcp dpt:80 flags:0x0216/0x022
# LOG        tcp  --  0.0.0.0/0            0.0.0.0/0          tcp flags:0x0216/0x022 LOG flags 0 level 4 prefix `DENY '
# DROP       tcp  --  0.0.0.0/0            0.0.0.0/0          tcp flags:0x0216/0x022
		my @rules = `$Cmds_href->{'iptables'} -nL`;
		my $drop_rule = 0;
		my $drop_tcp = 0;
		my $drop_udp = 0;
		FWPARSE: foreach my $rule (@rules) {
			next FWPARSE if ($rule =~ /^Chain/ || $rule =~ /^target/);
			if ($rule =~ /^(LOG)\s+(\w+)\s+\S+\s+\S+\s+(\S+)\s.+prefix\s\`(.+)\'/) {
				($target, $proto, $dst, $prefix) = ($1, $2, $3, $4);
				if ($target eq "LOG" && $proto =~ /all/ && $prefix =~ /drop|reject|deny/i) {
				# this needs work... see above _two_ rules.
					if (check_destination($dst, \@localips)) {
						print STDOUT "=-=-=  Your firewall setup looks good.  Unauthorized tcp and/or udp packets will be logged.\n";
						return 1;
					}
				} elsif ($target eq "LOG" && $proto =~ /tcp/ && $prefix =~ /drop|reject|deny/i) {
					$drop_tcp = 1 if (check_destination($dst, \@localips));
				} elsif ($target eq "LOG" && $proto =~ /udp/ && $prefix =~ /drop|reject|deny/i) {
					$drop_udp = 1 if (check_destination($dst, \@localips));
				}
			}
		}
		if ($drop_tcp && $drop_udp) {
			print STDOUT "=-=-=  Your firewall setup looks good.  Unauthorized tcp and/or udp packets will be logged.\n";
			return 1;
		} elsif ($drop_tcp) {
			print STDOUT "=-=-=  Your firewall will log unauthorized tcp packets, but not all udp packets.\n";
			print STDOUT "=-=-=  Hence psad will be able to detect tcp scans, but not udp ones.\n";
			print STDOUT "=-=-=  Suggestion: After making sure you accept any udp traffic that you need to (such as udp/53\n";
			print STDOUT "=-=-=  for nameservice) add a rule to log and drop all other udp traffic with the following two commands:\n";
			print STDOUT "=-=-=     # /usr/local/bin/iptables -A INPUT -p udp -j LOG --log-prefix \"DENY \"\n";
			print STDOUT "=-=-=     # /usr/local/bin/iptables -A INPUT -p udp -j DROP\n";
			return 1;
		} elsif ($drop_tcp) {
                        print STDOUT "=-=-=  Your firewall will log unauthorized udp packets, but not all tcp packets.\n";
                        print STDOUT "=-=-=  Hence psad will be able to detect udp scans, but not tcp ones.\n";
                        print STDOUT "=-=-=  Suggestion: After making sure you accept any tcp traffic that you need to (such as tcp/80\n";  
                        print STDOUT "=-=-=  etc.) add a rule to log and drop all other tcp traffic with the following two commands:\n";
                        print STDOUT "=-=-=     # /usr/local/bin/iptables -A INPUT -p tcp -j LOG --log-prefix \"DENY \"\n";
                        print STDOUT "=-=-=     # /usr/local/bin/iptables -A INPUT -p tcp -j DROP\n";
			return 1;
                }
		print STDOUT "=-=-=  Your firewall does not include rules that will log dropped/rejected packets.\n";
		print STDOUT "    You need to include a default rule that logs packets that have not been accepted\n";
		print STDOUT "    by previous rules, and this rule should have a logging prefix of \"drop\", \"deny\"\n";
		print STDOUT "    or \"reject\".  For example suppose that you are running a webserver to which you\n";
		print STDOUT "    also need ssh access.  Then a iptables ruleset that is compatible with psad\n";
		print STDOUT "    could be built with the following commands:\n";
		print STDOUT "\n";
		print STDOUT "    iptables -A INPUT -s 0/0 -d <webserver_ip> 80 -j ACCEPT\n";
		print STDOUT "    iptables -A INPUT -s 0/0 -d <webserver_ip> 22 -j ACCEPT\n";
		print STDOUT "    iptables -A INPUT -j LOG --log-prefix \" DROP\"\n";
		print STDOUT "    iptables -A INPUT -j DENY\n";
		print STDOUT "\n";	
		print STDOUT "    Psad will not run without an iptables ruleset that includes rules similar to the\n";
		print STDOUT "    last two rules above.\n";
		return 0;
	} elsif ($ipchains) {
# target     prot opt     source                destination           ports
# DENY       tcp  ----l-  anywhere             anywhere              any ->   telnet

#Chain input (policy ACCEPT):
#target     prot opt     source                destination           ports
#ACCEPT     tcp  ------  0.0.0.0/0            0.0.0.0/0             * ->   22
#DENY       tcp  ----l-  0.0.0.0/0            0.0.0.0/0             * ->   *
		my @rules = `$Cmds_href->{'ipchains'} -nL`;
		FWPARSE: foreach my $rule (@rules) {
			chomp $rule;
                        next FWPARSE if ($rule =~ /^Chain/ || $rule =~ /^target/);
			if ($rule =~ /^(\w+)\s+(\w+)\s+(\S+)\s+\S+\s+(\S+)\s+(\*)\s+\-\>\s+(\*)/) {
				my ($target, $proto, $opt, $dst, $srcpt, $dstpt) = ($1, $2, $3, $4, $5, $6);
                        	if ($target =~ /drop|reject|deny/i && $proto =~ /all|tcp/ && $opt =~ /....l./) {
					if (check_destination($dst, \@localips)) {
						print STDOUT "=-=-=  Your firewall setup looks good.  Unauthorized tcp packets will be dropped and logged.\n"; 
                                		return 1;
					}
				}
			} elsif ($rule =~ /^(\w+)\s+(\w+)\s+(\S+)\s+\S+\s+(\S+)\s+(n\/a)/) {  # kernel 2.2.14 (and others) show "n/a" instead of "*"
				my ($target, $proto, $opt, $dst, $ports) = ($1, $2, $3, $4, $5);
				if ($target =~ /drop|reject|deny/i && $proto =~ /all|tcp/ && $opt =~ /....l./) {
					if (check_destination($dst, \@localips)) {
						print STDOUT "=-=-=  Your firewall setup looks good.  Unauthorized tcp packets will be dropped and logged.\n";
						return 1;
					}
				}
			}
                }
		print STDOUT "=-=-=  Your firewall does not include rules that will log dropped/rejected packets.  Psad will not work with such a firewall setup.\n";
                return 0;
	} else {
		die "=-=-=  The linux kernel version you are currently running (v $kernel) does not seem to support ipchains or iptables.  psad will not run!\n";
	}
} 
sub check_destination() {
	my ($dst, $localips_aref) = @_;
	return 1 if ($dst =~ /0\.0\.0\.0\/0/);
	foreach my $ip (@$localips_aref) {
		my ($oct) = ($ip =~ /^(\d{1,3}\.\d{1,3})/);
		return 1 if ($dst =~ /^$oct/);
	}
	return 0;
}
sub get_distro() {
	if (-e "/etc/issue") {
		# Red Hat Linux release 6.2 (Zoot)
		open ISSUE, "< /etc/issue";
		while(<ISSUE>) {
			my $l = $_;
			chomp $l;
			return "redhat61" if ($l =~ /Red\sHat.*?6\.2/);
			return "redhat62" if ($l =~ /Red\sHat.*?6\.1/);
		}
		close ISSUE;
		return "NA";
	} else {
		return "NA";
	}
}
sub get_kernel() {
	my $Cmds_href = shift;
	my $kernel = (split /\s/, `$Cmds_href->{'uname'} -a`)[2];
	return $kernel;
}
sub check_commands() {
	my $Cmds_href = shift;
	CMD: foreach my $cmd (keys %$Cmds_href) {
		unless (-e $Cmds_href->{$cmd}) {
			$real_location = `which $cmd 2> /dev/null`;
			chomp $real_location;
			if ($real_location) {
				print "=-=-=  $cmd is not located at $Cmds_href->{$cmd}.  Using $real_location\n";
				$Cmds_href->{$cmd} = $real_location;
			} else {
				if ($cmd ne "ipchains" && $cmd ne "iptables") {
					die "Could not find $cmd anywhere!!!  Please edit the config section to include the path to $cmd.\n";
				} elsif (defined $Cmds_href->{'uname'}) {
        				my $kernel = (split /\s+/, `$Cmds_href->{'uname'} -a`)[2];
        				if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
						if ($cmd eq "ipchains") {
							next CMD;
						} else {
							die "=-=-=  You appear to be running kernel $kernel so you should be running iptables but iptables is not\nlocated at $Cmds_href->{'iptables'}.  Please edit the config section to include the path to iptables.\n";	
						}
					}      
  					if ($kernel =~ /^2.2/) { # and also 2.0.x ?
						if ($cmd eq "iptables") {
							next CMD;
						} else {
							die "=-=-=  You appear to be running kernel $kernel so you should be running ipchains but ipchains is not\nlocated at $Cmds_href->{'ipchains'}.  Please edit the config section to include the path to ipchains.\n";
						}
					}
				}
			}
		}
	}
	return %$Cmds_href;
}
sub preserve_config() {
	my ($srcfile, $productionfile, $Cmds_href) = @_;
	my $start = 0;
	my @config = (), @defconfig = ();
#	$#config = 0; $#defconfig = 0;
	open PROD, "< $productionfile" or die "Could not open production file: $!\n";
	GETCONFIG: while(<PROD>) {
		my $l = $_;
		chomp $l;
		if ($l =~ /\=\=\=\=\=\s+config\s+\=\=\=\=\=/) {
			$start = 1;
		}
		push @config, $l if ($start);
		if ($l =~ /\=\=\=\=\=\s+end\s+config\s+\=\=\=\=\=/) {
			last GETCONFIG;
		}
	}
	close PROD;
	if ($config[0] !~ /\=\=\=\=\=\s+config\s+\=\=\=\=\=/ || $config[$#config] !~ /\=\=\=\=\=\s+end\s+config\s+\=\=\=\=\=/) {
		die "Could not get config info from $productionfile!!!  Try running \"install.pl -n\" and\nedit the configuration sections of $productionfile directly.\n"
	}
	$start = 0;
	open DEFCONFIG, "< $srcfile" or die "Could not open source file: $!\n";
	GETDEFCONFIG: while(<DEFCONFIG>) {
		my $l = $_;
		chomp $l;
               	if ($l =~ /\=\=\=\=\=\s+config\s+\=\=\=\=\=/) {
                        $start = 1;
                }
		push @defconfig, $l if ($start);
		if ($l =~ /\=\=\=\=\=\s+end\s+config\s+\=\=\=\=\=/) {
                        last GETDEFCONFIG;
                }
	}
	close DEFCONFIG;
	# We only want to preserve the variables from the $productionfile.  Any commented lines will be discarded
	# and replaced with the commented lines from the $srcfile.	
	#
	# First get the variables into a hash from the $productionfile
	my %prodvars;
	my %srcvars;
	undef %prodvars;
	undef %srcvars;
	foreach my $p (@config) {
		if ($p =~ /(\S+)\s+=\s+(.*?)\;/) {  # found a variable _assignment_ (does not include "my %var;"
			my ($varname, $value) = ($1, $2);
			my $type;
			($varname, $type) = assign_var_type($varname);
			$prodvars{$type}{$varname}{'VALUE'} = $value;
			$prodvars{$type}{$varname}{'LINE'} = $p;
			$prodvars{$type}{$varname}{'FOUND'} = "N";
		}
	}
        foreach my $defc (@defconfig) {
                if ($defc =~ /(\S+)\s+=\s+(.*?)\;/) {  # found a variable _assignment_ (does not include "my %var;"
                        my ($varname, $value) = ($1, $2);
                        my $type;
			($varname, $type) = assign_var_type($varname);
                        $srcvars{$type}{$varname}{'VALUE'} = $value;
                        $srcvars{$type}{$varname}{'LINE'} = $defc;
		}
        }
	open SRC, "< $srcfile" or die "Could not open source file: $!\n";
	$start = 0;
	my $print = 1;
	my $prod_tmp = $productionfile . "_tmp";
	open TMP, "> $prod_tmp";
	while(<SRC>) {
		my $l = $_;
		chomp $l;
		$start = 1 if ($l =~ /\=\=\=\=\=\s+config\s+\=\=\=\=\=/);
		print TMP "$l\n" unless $start;   # print the "======= config =======" line
		if ($start && $print) {
			PDEF: foreach my $defc (@defconfig) {
				if ($defc =~ /(\S+)\s+=\s+(.*?)\;/) {  # found a variable
					my ($varname, $value) = ($1, $2);
					my $type;
					($varname, $type) = assign_var_type($varname);
					if ($varname eq "EMAIL_ADDRESSES" && defined $prodvars{'STRING'}{'EMAIL_ADDRESS'}{'VALUE'}) {  # old email format in production psad
						if ($prodvars{'STRING'}{'EMAIL_ADDRESS'}{'VALUE'} =~ /\"(\S+).\@(\S+)\"/) {
							my $mailbox = $1;
							my $host = $2;
							if ($mailbox ne "root" && $host ne "localhost") {
								$defc =~ s/root/$mailbox/;
								$defc =~ s/localhost/$host/;
								print "-----  Removing depreciated email format.  Preserving email address in production installation.\n";
								$prodvars{'STRING'}{'EMAIL_ADDRESS'}{'FOUND'} = "Y";
								print TMP "$defc\n";
								next PDEF;
							}
						}
					}
					if (defined $prodvars{$type}{$varname}{'VALUE'}) {
						$defc = $prodvars{$type}{$varname}{'LINE'};
						$prodvars{$type}{$varname}{'FOUND'} = "Y";
						if ($verbose) {
							print "*****  Using configuration value from production installation of psad for $type variable: $varname\n";
						}
						print TMP "$defc\n";
					} else {
						$prodvars{$type}{$varname}{'FOUND'} = "Y";
						print "+++++  Adding new configuration $type variable \"$varname\" introduced in this version of psad.\n";
						print TMP "$defc\n";
					}
				} else {
					print TMP "$defc\n";  # it is some other non-variable-assignment line so print it from the $srcfile
				}
			}
			foreach my $type (keys %prodvars) {
				foreach my $varname (keys %{$prodvars{$type}}) {
					next if ($varname =~ /EMAIL_ADDRESS/);
					unless ($prodvars{$type}{$varname}{'FOUND'} eq "Y") {
						print "-----  Removing depreciated $type variable: \"$varname\" not needed in this version of psad.\n";
					}
				}
			}	
			$print = 0;
		}
		$start = 0 if ($l =~ /\=\=\=\=\=\s+end\s+config\s+\=\=\=\=\=/);
	}
	close SRC;
	close TMP;
	`$Cmds_href->{'mv'} $prod_tmp $productionfile`;
	return;
}
sub striphashsyntax() {
	my $varname = shift;
	$varname =~ s/\{//;
	$varname =~ s/\}//;
	$varname =~ s/\'//g;
	return $varname;
}
sub assign_var_type() {
	my $varname = shift;;
	my $type;
	if ($varname =~ /\$/ && $varname =~ /\{/) {
		$type = "HSH_ELEM";
		$varname = &striphashsyntax($varname);   # $DANGER_LEVELS{'1'}, etc...
	} elsif ($varname =~ /\$/) { 
		$type = "STRING";
	} elsif ($varname =~ /\@/) {
		$type = "ARRAY";
	} elsif ($varname =~ /\%/) {  # this will probably never get used since psad will just scope a hash in the config section with "my"
		$type = "HASH";
	}
	$varname =~ s/^.//;  # get rid of variable type since we have it in $type
	return $varname, $type;
}
sub perms_ownership() {
	my ($file, $perm_value) = @_;
	chmod $perm_value, $file;
	chown 0, 0, $file;	# chown uid, gid, $file
	return;
}
sub usage_and_exit() {
        my $exitcode = shift;
        print <<_HELP_;

Usage: psad [-f] [-n] [-e] [-u] [-v] [-h]
	
	-n  --no_preserve	- disable preservation of old configs.
	-e  --exec_psad		- execute psad after installing.
        -f  --firewall_check    - disable firewall rules verification.
	-u  --uninstall		- uninstall psad.
	-v  --verbose		- verbose mode.
        -h  --help              - prints this help message.

_HELP_
        exit $exitcode;
}
