#!/usr/bin/perl -w

#============== config ===============
my $SYSLOG_INIT = "/etc/rc.d/init.d/syslog";

my $killCmd = "/bin/kill";
my $psCmd = "/bin/ps";
my $touchCmd = "/bin/touch";
my $mknodCmd = "/bin/mknod";
my $grepCmd = "/bin/grep";
my $cpCmd = "/bin/cp";
my $idCmd = "/usr/bin/id";
my $mvCmd = "/bin/mv";
my $unameCmd = "/bin/uname";
my $ifconfigCmd = "/sbin/ifconfig";
my $ipchainsCmd = "/sbin/ipchains";
my $iptablesCmd = "/usr/local/bin/iptables";
#============ end config ============

use Getopt::Long;

my $fwcheck = 0;
my $execute_psad = 0;

usage_and_exit(1) unless (GetOptions (
        'help'          => \$help,              # display help
        'firewallcheck' => \$fwcheck,           # do not check firewall rules
	'execpsad'	=> \$execute_psad
));
usage_and_exit(0) if ($help);

my %Cmds = (
	"kill"		=> $killCmd,
	"ps"		=> $psCmd,
	"touch"		=> $touchCmd,
	"mknod"         => $mknodCmd,
	"grep"		=> $grepCmd,
	"cp"		=> $cpCmd,
	"id"		=> $idCmd,
	"mv"		=> $mvCmd,
	"uname"		=> $unameCmd,
	"ifconfig"	=> $ifconfigCmd,
	"ipchains"      => $ipchainsCmd,
	"iptables"	=> $iptablesCmd
);

%Cmds = check_commands(\%Cmds);

my $uid = (split /\s+/, `$Cmds{'id'}`)[0];
($uid) = ($uid =~ /^uid\=(\d+)/);
die "You need to be root (or equivalent UID 0 account) to install psad!\n" if $uid;
unless (-e "/var/log/psadfifo") {
	print "*** Creating named pipe /var/log/psadfifo\n";
	# create the named pipe
	`$Cmds{'mknod'} -m 600 /var/log/psadfifo p`;	# die does not seem to work right here.
}
unless (`$Cmds{'grep'} psadfifo /etc/syslog.conf`) {
	print "*** Modifying /etc/syslog.conf\n";
	open SYSLOG, ">> /etc/syslog.conf";
	print SYSLOG "kern.info  |/var/log/psadfifo\n\n";  #reinstate kernel logging to our named pipe
	close SYSLOG;
	print "*** Restarting syslog\n";
	system("$SYSLOG_INIT") or warn "*** Unable to restart syslog!!!\n";      # restart syslog
}
unless (-e "/var/log/psad") {
	print "*** Creating /var/log/psad/\n";
	mkdir "/var/log/psad",400;
}
unless (-e "/var/log/psad/fwdata") {
	print "*** Creating /var/log/psad/fwdata file\n";
	`$Cmds{'touch'} /var/log/psad/fwdata`;
	chmod 0600, "/var/log/psad/fwdata";
	perms_ownership("/var/log/psad/fwdata", 0600);
}
unless (-e "/usr/local/bin") {
	print "*** Creating /usr/local/bin/\n";
	mkdir "/usr/local/bin",755;
}
if ( -e "/usr/local/bin/psad") {  # need to grab the old config
	print "*** Copying psad -> /usr/local/bin/psad\n";
	print "***	Preserving old config within /usr/local/bin/psad\n";
	preserve_config("psad", "/usr/local/bin/psad", \%Cmds);
	perms_ownership("/usr/local/bin/psad", 0500)
} else {
	print "*** Copying psad -> /usr/local/bin/\n";
	`$Cmds{'cp'} psad /usr/local/bin/psad`;
	perms_ownership("/usr/local/bin/psad", 0500);
}
if (-e "/usr/local/bin/kmsgsd") { 
	print "*** Copying kmsgsd -> /usr/local/bin/kmsgsd\n";
	print "***	Preserving old config within /usr/local/bin/kmsgsd\n";
	preserve_config("kmsgsd", "/usr/local/bin/kmsgsd", \%Cmds);
	perms_ownership("/usr/local/bin/kmsgsd", 0500);
} else {
	print "*** Copying kmsgsd -> /usr/local/bin/kmsgsd\n";
	`$Cmds{'cp'} kmsgsd /usr/local/bin/kmsgsd`;
	perms_ownership("/usr/local/bin/kmsgsd", 0500);
}
if (-e "/usr/local/bin/diskmond") {
	print "*** Copying diskmond -> /usr/local/bin/diskmond\n";
	print "*** 	Preserving old config within /usr/local/bin/diskmond\n";
        preserve_config("diskmond", "/usr/local/bin/diskmond", \%Cmds);
        perms_ownership("/usr/local/bin/diskmond", 0500);
} else {
	print "*** Copying diskmond -> /usr/local/bin/diskmond\n";
	`$Cmds{'cp'} diskmond /usr/local/bin/diskmond`;
	perms_ownership("/usr/local/bin/diskmond", 0500);
}
unless (-e "/etc/psad") {
        print "*** Creating /etc/psad/\n";
        mkdir "/etc/psad",400;
}
if (-e "/etc/psad/psad.conf") {
	print "*** Copying psad_signatures -> /etc/psad/psad_signatures\n";
	print "***	Preserving old signatures file as /etc/psad/psad_signatures.old\n";
	`$Cmds{'mv'} /etc/psad/psad_signatures /etc/psad/psad_signatures.old`;
	`$Cmds{'cp'} psad_signatures /etc/psad/psad_signatures`;
	perms_ownership("/etc/psad/psad_signatures", 0600);
} else {
	print "*** Copying psad_signatures -> /etc/psad/psad_signatures\n";
	`$Cmds{'cp'} psad_signatures /etc/psad/psad_signatures`;
	perms_ownership("/etc/psad/psad_signatures", 0600);
}
if (-e "/etc/psad/psad.conf") {
	print "*** Copying psad.conf -> /etc/psad/psad.conf\n";
	print "***	Preserving old psad.conf file as /etc/psad/psad.conf\n";
	`$Cmds{'mv'} /etc/psad/psad.conf /etc/psad/psad.conf.old`;
	`$Cmds{'cp'} psad.conf /etc/psad/psad.conf`;
	perms_ownership("/etc/psad/psad.conf", 0600);
} else {
	print "*** Copying psad.conf -> /etc/psad/psad.conf\n";
	`$Cmds{'cp'} psad.conf /etc/psad/psad.conf`;
	perms_ownership("/etc/psad/psad.conf", 0600);
}

my $distro = get_distro();
my $kernel = get_kernel(\%Cmds);

if ($distro eq "redhat61" || $distro eq "redhat62") {
	# remove signature checking from psad process if we are not running an iptables-enabled kernel
	system "perl -p -i -e 's|\\-s\\s/etc/psad/psad_signatures||' psad-init" if ($kernel !~ /^2.3/ && $kernel !~ /^2.4/);
	print "*** Copying psad-init -> /etc/rc.d/init.d/psad-init\n";
	`$Cmds{'cp'} psad-init /etc/rc.d/init.d/psad-init`;
} 
# need to put checks in here for redhat vs. other systems.
unless($fwcheck) {
	if(check_firewall_rules(\%Cmds)) {
		my $pidstatement = `$Cmds{'ps'} -auxw |$Cmds{'grep'} psad |$Cmds{'grep'} -v grep`;
		if ($execute_psad) {
			if ($distro eq "redhat61" || $distro eq "redhat62") {
				if ($pidstatement) {
					print "*** Restarting the psad daemons...\n";
					system "/etc/rc.d/init.d/psad-init restart";
				} else {
					print "*** Starting the psad daemons...\n";
					system "/etc/rc.d/init.d/psad-init start";
				}
			} else {
				if ($pidstatement) {
					print "*** Restarting the psad daemons...\n";
					my $pid = (split /\s+/, $pidstatement)[1];
					system "$Cmds{'kill'} $pid";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
                                                system "/usr/local/bin/psad -s /etc/psad/psad_signatures";
                                        } elsif ($kernel =~ /^2.2/) {
                                                system "/usr/local/bin/psad";
                                        } else {
                                                print "*** You are running kernel $kernel.  Assuming ipchains support.\n";
                                                system "/usr/local/bin/psad";
                                        }
				} else {
					print "*** Starting the psad daemons...\n";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {	
                                        	system "/usr/local/bin/psad -s /etc/psad/psad_signatures";
					} elsif ($kernel =~ /^2.2/) {
						system "/usr/local/bin/psad";
					} else {
						print "*** You are running kernel $kernel.  Assuming ipchains support.\n";
						system "/usr/local/bin/psad";
					}
				}
			}
		} else {
			if ($distro eq "redhat61" || $distro eq "redhat62") {
				if ($pidstatement) {
					print "*** An older version of psad is already running.  To execute, run \"/etc/rc.d/init.d/psad-init restart\"\n";
				} else {
					print "*** To execute psad, run \"/etc/rc.d/init.d/psad-init start\"\n";
				}
			} else {
				if ($pidstatement) {
					my $pid = (split /\s+/, $pidstatement)[1];
					print "*** An older version of psad is already running.  kill pid $pid, and then execute:\n";
					if ($kernel =~ /^2.3/ || $kernel =~ /^2.4/) {
                                       		print "/usr/local/bin/psad -s /etc/psad/psad_signatures, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n"; 
                                        } elsif ($kernel =~ /^2.2/) {
						print "/usr/local/bin/psad, /usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
                                        } else {
						print "/usr/local/bin/psad (you are running kernel $kernel... assuming ipchains support),\n";
						print "/usr/local/bin/diskmond, and /usr/local/bin/kmsgsd\n";
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
		print "*** After setting up your firewall per the above note, execute \"/etc/rc.d/init.d/psad-init start\" to start psad\n";
	}
}
exit 0;
#==================== end main =====================
sub check_firewall_rules() {
	my $Cmds_href = shift;
	my @localips;
	my $kernel = get_kernel($Cmds_href);
#	my $kernel = (split /\s/, `$Cmds_href->{'uname'} -a`)[2];
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
		FWPARSE: foreach my $rule (@rules) {
			next FWPARSE if ($rule =~ /^Chain/ || $rule =~ /^target/);
			if ($rule =~ /^(LOG)\s+(\w+)\s+\S+\s+\S+\s+(\S+)\s.+prefix\s\`(.+)\'/) {
				($target, $proto, $dst, $prefix) = ($1, $2, $3, $4);
				if ($target eq "LOG" && $proto =~ /all|tcp/ && $prefix =~ /drop|reject|deny/i) { # only tcp supported right now...
				# this needs work... see above _two_ rules.
					if (check_destination($dst, \@localips)) {
						print STDOUT "*** Your firewall setup looks good.  Unauthorized tcp packets will be logged.\n";
						return 1;
					}
				}
			}
		}
		print STDOUT "*** Your firewall does not include rules that will log dropped/rejected packets.  Psad will not work with such a firewall setup.\n";
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
						print STDOUT "*** Your firewall setup looks good.  Unauthorized tcp packets will be dropped and logged.\n"; 
                                		return 1;
					}
				}
                        }
                }
		print STDOUT "*** Your firewall does not include rules that will log dropped/rejected packets.  Psad will not work with such a firewall setup.\n";
                return 0;
	} else {
		die "*** The linux kernel version you are currently running (v $kernel) does not seem to support ipchains or iptables.  psad will not run!\n";
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
				print "*** $cmd is not located at $Cmds_href->{$cmd}.  Using $real_location\n";
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
							die "*** You appear to be running kernel $kernel so you should be running iptables but iptables is not\nlocated at $Cmds_href->{'iptables'}.  Please edit the config section to include the path to iptables.\n";	
						}
					}      
  					if ($kernel =~ /^2.2/) { # and also 2.0.x ?
						if ($cmd eq "iptables") {
							next CMD;
						} else {
							die "*** You appear to be running kernel $kernel so you should be running ipchains but ipchains is not\nlocated at $Cmds_href->{'ipchains'}.  Please edit the config section to include the path to ipchains.\n";
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
	open PROD, "< $productionfile" or die "Could not open production file: $!\n";
	my $start = 0;
	my @config;
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
	die "Could not get config info from $productionfile!!!\n" unless (defined @config);
	close PROD;
	open SRC, "< $srcfile" or die "Could not open source file: $!\n";
	$start = 0;
	my $print = 1;
	my $prod_tmp = $productionfile . "_tmp";
	open TMP, "> $prod_tmp";
	while(<SRC>) {
		my $l = $_;
		chomp $l;
		$start = 1 if ($l =~ /\=\=\=\=\=\s+config\s+\=\=\=\=\=/);
		print TMP "$l\n" unless $start;
		if ($start && $print) {
			foreach my $c (@config) {
				print TMP "$c\n";
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
sub perms_ownership() {
	my ($file, $perm_value) = @_;
	chmod $perm_value, $file;
	chown 0, 0, $file;	# chown uid, gid, $file
	return;
}
sub usage_and_exit() {
        my $exitcode = shift;
        print <<_HELP_;

Usage: psad [-f] [-h]
	
	-execpsad		- execute psad after installing.
        -firewallcheck          - disable firewall rules verification.
        -h                      - prints this help message.

_HELP_
        exit $exitcode;
}

