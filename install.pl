#!/usr/bin/perl -w

# TODO: 
#	- make install.pl preserve psad_signatures and psad_auto_ips
#	  with "diff" and "patch" from the old to the new.

use File::Path; # used for the 'rmtree' function for removing directories
use File::Copy; # used for copying/moving files
use Getopt::Long;
use Text::Wrap;
use Sys::Hostname "hostname";

### globals
use vars qw($HOSTNAME $INSTALL_DIR $INSTALL_LOG @LOGR_FILES $INIT_DIR $SUB_TAB);

#============== config ===============
$INIT_DIR = "/etc/rc.d/init.d";
$INSTALL_DIR = "/usr/sbin";	### consistent with FHS (Filesystem Hierarchy Standard)
$INSTALL_LOG = "/var/log/psad/install.log";
@LOGR_FILES = ("STDOUT", $INSTALL_LOG);
$HOSTNAME = hostname;
my $SYSLOG_INIT = "${INIT_DIR}/syslog";

my $psCmd = "/bin/ps";
my $mknodCmd = "/bin/mknod";
my $grepCmd = "/bin/grep";
my $makeCmd = "/usr/bin/make";
my $unameCmd = "/bin/uname";
my $findCmd = "/usr/bin/find";
my $perlCmd = "/usr/bin/perl";
my $ifconfigCmd = "/sbin/ifconfig";
my $ipchainsCmd = "/sbin/ipchains";
my $iptablesCmd = "/usr/local/bin/iptables";
my $psadCmd = "${INSTALL_DIR}/psad";
#============ end config ============

### set the default execution
$SUB_TAB = "       ";
my $fwcheck = 0;
my $execute_psad = 0;
my $nopreserve = 0;
my $uninstall = 0;

&usage_and_exit(1) unless (GetOptions (
	'no_preserve'		=> \$nopreserve,	# don't preserve existing configs
        'firewall_check'	=> \$fwcheck,           # do not check firewall rules
	'exec_psad'		=> \$execute_psad,
	'uninstall'		=> \$uninstall,
	'verbose'		=> \$verbose,
        'help'          	=> \$help               # display help
));
&usage_and_exit(0) if ($help);

my %Cmds = (
	"ps"		=> $psCmd,
	"mknod"         => $mknodCmd,
	"grep"		=> $grepCmd,
	"uname"		=> $unameCmd,
	"find"		=> $findCmd,
	"make"		=> $makeCmd,
	"perl"		=> $perlCmd,
	"ifconfig"	=> $ifconfigCmd,
	"ipchains"      => $ipchainsCmd,
	"iptables"	=> $iptablesCmd,
	"psad"		=> $psadCmd
);

### need to make sure this exists before attempting to write anything to the install log.
&create_varlogpsad();

%Cmds = &check_commands(\%Cmds);

$< == 0 && $> == 0 or die "You need to be root (or equivalent UID 0 account) to install/uninstall psad!\n";

&check_old_psad_installation();  ### check for a pre-0.9.2 installation of psad.

if ($uninstall) {
	my $t = localtime();
	my $time = " ----     Uninstalling psad from $HOSTNAME: $t    ----\n";
	&logr("\n", \@LOGR_FILES);
	&logr($time, \@LOGR_FILES);
	&logr("\n", \@LOGR_FILES);

	my $ans = "";
	while ($ans ne "y" && $ans ne "n") {
		print wrap("", $SUB_TAB, " ----  This will completely remove psad from your system.  Are you sure (y/n)? ");
		$ans = <STDIN>;
		chomp $ans;
	}
	exit 0 if ($ans eq "n");
	if (-e "${INIT_DIR}/psad") {
		print " ----  Stopping psad daemons!  ----\n";
#		system("/etc/rc.d/init.d/psad stop") or warn "@@@@@  Could not stop psad daemons!  ----\n";
		system "${INIT_DIR}/psad stop";
		print " ----  Removing ${INIT_DIR}/psad  ----\n";
		unlink "${INIT_DIR}/psad";
	}	
	if (-e "${INSTALL_DIR}/psad") {
		print wrap("", $SUB_TAB, " ----  Removing psad daemons: ${INSTALL_DIR}/(psad, psadwatchd, kmsgsd, diskmond)  ----\n");
		unlink "${INSTALL_DIR}/psad" or warn "@@@@@  Could not remove ${INSTALL_DIR}/psad!!!\n";
		unlink "${INSTALL_DIR}/psadwatchd" or warn "@@@@@  Could not remove ${INSTALL_DIR}/psadwatchd!!!\n";
		unlink "${INSTALL_DIR}/kmsgsd" or warn "@@@@@  Could not remove ${INSTALL_DIR}/kmsgsd!!!\n";
		unlink "${INSTALL_DIR}/diskmond" or warn "@@@@@  Could not remove ${INSTALL_DIR}/diskmond!!!\n";
	}
	if (-e "/etc/psad") {
		print " ----  Removing configuration directory: /etc/psad  ----\n";
		rmtree("/etc/psad", 1, 0);
	}
	if (-e "/var/log/psad") {
		print " ----  Removing logging directory: /var/log/psad  ----\n";
		rmtree("/var/log/psad", 1, 0);
	}
	if (-e "/var/log/psadfifo") {
		print " ----  Removing named pipe: /var/log/psadfifo  ----\n";
		unlink "/var/log/psadfifo";
	}
	if (-e "/usr/bin/whois.psad") {
		print " ----  Removing /usr/bin/whois.psad  ----\n";
		unlink "/usr/bin/whois.psad";
	}
	print " ----  Restoring /etc/syslog.conf.orig -> /etc/syslog.conf  ----\n";
	if (-e "/etc/syslog.conf.orig") {
		move("/etc/syslog.conf.orig", "/etc/syslog.conf");
#		`$Cmds{'mv'} /etc/syslog.conf.orig /etc/syslog.conf`;
	} else {
	 	print wrap("", $SUB_TAB, " ----  /etc/syslog.conf.orig does not exist.  Editing /etc/syslog.conf directly.\n");
		open ESYS, "< /etc/syslog.conf" or die "@@@@@  Unable to open /etc/syslog.conf: $!\n";
		my @sys = <ESYS>;
		close ESYS;
		open CSYS, "> /etc/syslog.conf";
		foreach my $s (@sys) {
			chomp $s;
			print CSYS "$s\n" if ($s !~ /psadfifo/);
		}
		close CSYS;
	}
	print " ----  Restarting syslog...  ----\n";
	system("$SYSLOG_INIT restart");
	print "\n";
	print " ----  Psad has been uninstalled!  ----\n";
	exit 0;
}

### Start the installation code...
### make sure we know where the syslog init script is.

my $t = localtime();
my $time = " ----     Installing psad on $HOSTNAME: $t    ----\n";
&logr("\n", \@LOGR_FILES);
&logr($time, \@LOGR_FILES);
&logr("\n", \@LOGR_FILES);

unless (-e $SYSLOG_INIT) {
        my $s = `$Cmds{'find'} / -name syslog 2> /dev/null |$Cmds{'grep'} init |$Cmds{'grep'} -v grep`;
        chomp $s;
        if ($s) {
                $SYSLOG_INIT = $s;
        } else {
                &logr("@@@@  Could not find the syslog init script!  The current path is: $SYSLOG_INIT.  Edit the config section of install.pl.  Exiting.\n", ["STDERR", $INSTALL_LOG]);
                exit 0;
        }
}

unless (-e "/var/log/psadfifo") {
	&logr(" ----  Creating named pipe /var/log/psadfifo  ----\n", \@LOGR_FILES);
	# create the named pipe
	`$Cmds{'mknod'} -m 600 /var/log/psadfifo p`;	#  die does not seem to work right here.
}
unless (`$Cmds{'grep'} psadfifo /etc/syslog.conf`) {
	&logr(" ----  Modifying /etc/syslog.conf  ----\n", \@LOGR_FILES);
	copy("/etc/syslog.conf", "/etc/syslog.conf.orig") unless (-e "/etc/syslog.conf.orig");
	open SYSLOG, ">> /etc/syslog.conf" or die "@@@@@  Unable to open /etc/syslog.conf: $!\n";
	print SYSLOG "kern.info  |/var/log/psadfifo\n\n";  #reinstate kernel logging to our named pipe
	close SYSLOG;
	print " ----  Restarting syslog  ----\n";
	system("$SYSLOG_INIT restart");
}
unless (-e "/var/log/psad") {
	&logr(" ----  Creating /var/log/psad/  ----\n", \@LOGR_FILES);
	mkdir "/var/log/psad",400;
}
unless (-e "/var/log/psad/fwdata") {
	&logr(" ----  Creating /var/log/psad/fwdata file  ----\n", \@LOGR_FILES);
	open F, ">> /var/log/psad/fwdata";
	close F;
	chmod 0600, "/var/log/psad/fwdata";
	&perms_ownership("/var/log/psad/fwdata", 0600);
}
unless (-e $INSTALL_DIR) {
	&logr(" ----  Creating $INSTALL_DIR  ----\n", \@LOGR_FILES);
	mkdir $INSTALL_DIR,755;
}
unless (-e "/usr/bin/whois.psad") {
	if (-e "whois-4.5.6") {
		&logr(" ----  Compiling Marco d'Itri's whois client  ----\n", \@LOGR_FILES);
		if (! system("$Cmds{'make'} -C whois-4.5.6")) {  # remember unix return value...
			&logr(" ----  Copying whois binary to /usr/bin/whois.psad  ----\n", \@LOGR_FILES);
			copy("whois-4.5.6/whois", "/usr/bin/whois.psad");
			&perms_ownership("/usr/bin/whois.psad", 0755);
		}
	}
} else {
	&perms_ownership("/usr/bin/whois.psad", 0755);  # make absolutely certain we can execute whois.psad
}
if ( -e "${INSTALL_DIR}/psad" && (! $nopreserve)) {  # need to grab the old config
	&logr(" ----  Copying psad -> ${INSTALL_DIR}/psad  ----\n", \@LOGR_FILES);
	&logr("       Preserving old config within ${INSTALL_DIR}/psad\n", \@LOGR_FILES);
	&preserve_config("psad", "${INSTALL_DIR}/psad", \%Cmds);
	### we don't need to run with -w for production code, and they are daemons so nothing would see warnings anyway if there are any.
	&rm_perl_options("${INSTALL_DIR}/psad", \%Cmds);
	&perms_ownership("${INSTALL_DIR}/psad", 0500)
} else {
	&logr(" ----  Copying psad -> ${INSTALL_DIR}/  ----\n", \@LOGR_FILES);
	copy("psad", "${INSTALL_DIR}/psad");
	&rm_perl_options("${INSTALL_DIR}/psad", \%Cmds);
	&perms_ownership("${INSTALL_DIR}/psad", 0500);
}
if ( -e "${INSTALL_DIR}/psadwatchd" && (! $nopreserve)) {  # need to grab the old config
        &logr(" ----  Copying psadwatchd -> ${INSTALL_DIR}/psadwatchd  ----\n", \@LOGR_FILES);
        &logr("       Preserving old config within ${INSTALL_DIR}/psadwatchd\n", \@LOGR_FILES);
        &preserve_config("psadwatchd", "${INSTALL_DIR}/psadwatchd", \%Cmds);
	&rm_perl_options("${INSTALL_DIR}/psadwatchd", \%Cmds);
        &perms_ownership("${INSTALL_DIR}/psadwatchd", 0500);
} else {
        &logr(" ----  Copying psadwatchd -> ${INSTALL_DIR}/  ----\n", \@LOGR_FILES);
	copy("psadwatchd", "${INSTALL_DIR}/psadwatchd");
	&rm_perl_options("${INSTALL_DIR}/psadwatchd", \%Cmds);
        &perms_ownership("${INSTALL_DIR}/psadwatchd", 0500);
}
if (-e "${INSTALL_DIR}/kmsgsd" && (! $nopreserve)) { 
	&logr(" ----  Copying kmsgsd -> ${INSTALL_DIR}/kmsgsd\n", \@LOGR_FILES);
	&logr("       Preserving old config within ${INSTALL_DIR}/kmsgsd  ----\n", \@LOGR_FILES);
	&preserve_config("kmsgsd", "${INSTALL_DIR}/kmsgsd", \%Cmds);
	&rm_perl_options("${INSTALL_DIR}/kmsgsd", \%Cmds);
	&perms_ownership("${INSTALL_DIR}/kmsgsd", 0500);
} else {
	&logr(" ----  Copying kmsgsd -> ${INSTALL_DIR}/kmsgsd  ----\n", \@LOGR_FILES);
	copy("kmsgsd", "${INSTALL_DIR}/kmsgsd");
	&rm_perl_options("${INSTALL_DIR}/kmsgsd", \%Cmds);
	&perms_ownership("${INSTALL_DIR}/kmsgsd", 0500);
}
if (-e "${INSTALL_DIR}/diskmond" && (! $nopreserve)) {
	&logr(" ----  Copying diskmond -> ${INSTALL_DIR}/diskmond  ----\n", \@LOGR_FILES);
	&logr("       Preserving old config within ${INSTALL_DIR}/diskmond\n", \@LOGR_FILES);
        &preserve_config("diskmond", "${INSTALL_DIR}/diskmond", \%Cmds);
	&rm_perl_options("${INSTALL_DIR}/diskmond", \%Cmds);
        &perms_ownership("${INSTALL_DIR}/diskmond", 0500);
} else {
	&logr(" ----  Copying diskmond -> ${INSTALL_DIR}/diskmond  ----\n", \@LOGR_FILES);
	copy("diskmond", "${INSTALL_DIR}/diskmond");
	&rm_perl_options("${INSTALL_DIR}/diskmond", \%Cmds);
	&perms_ownership("${INSTALL_DIR}/diskmond", 0500);
}
unless (-e "/etc/psad") {
        &logr(" ----  Creating /etc/psad/  ----\n", \@LOGR_FILES);
        mkdir "/etc/psad",400;
}
if (-e "/etc/psad/psad_signatures") {
	&logr(" ----  Copying psad_signatures -> /etc/psad/psad_signatures  ----\n", \@LOGR_FILES);
	&logr("       Preserving old signatures file as /etc/psad/psad_signatures.old\n", \@LOGR_FILES);
	move("/etc/psad/psad_signatures", "/etc/psad/psad_signatures.old");
	copy("psad_signatures", "/etc/psad/psad_signatures");
	&perms_ownership("/etc/psad/psad_signatures", 0600);
} else {
	&logr(" ----  Copying psad_signatures -> /etc/psad/psad_signatures  ----\n", \@LOGR_FILES);
	copy("psad_signatures", "/etc/psad/psad_signatures");
	&perms_ownership("/etc/psad/psad_signatures", 0600);
}
if (-e "/etc/psad/psad_auto_ips") {
	&logr(" ----  Copying psad_auto_ips -> /etc/psad/psad_auto_ips  ----\n", \@LOGR_FILES);
	&logr("       Preserving old auto_ips file as /etc/psad/psad_auto_ips.old\n", \@LOGR_FILES);
	move("/etc/psad/psad_auto_ips", "/etc/psad/psad_auto_ips.old");
	copy("psad_auto_ips", "/etc/psad/psad_auto_ips");
	&perms_ownership("/etc/psad/psad_auto_ips", 0600);
} else {
	&logr(" ----  Copying psad_auto_ips -> /etc/psad/psad_auto_ips  ----\n", \@LOGR_FILES);
	copy("psad_auto_ips", "/etc/psad/psad_auto_ips");
	&perms_ownership("/etc/psad/psad_auto_ips", 0600);
}
if (-e "/etc/psad/psad.conf") {
	&logr(" ----  Copying psad.conf -> /etc/psad/psad.conf  ----\n", \@LOGR_FILES);
	&logr("       Preserving old psad.conf file as /etc/psad/psad.conf\n", \@LOGR_FILES);
	move("/etc/psad/psad.conf", "/etc/psad/psad.conf.old");
	copy("psad.conf", "/etc/psad/psad.conf");
	&perms_ownership("/etc/psad/psad.conf", 0600);
} else {
	&logr(" ----  Copying psad.conf -> /etc/psad/psad.conf  ----\n", \@LOGR_FILES);
	copy("psad.conf", "/etc/psad/psad.conf");
	&perms_ownership("/etc/psad/psad.conf", 0600);
}
&logr(" ----  Installing psad(8) man page  ----\n", \@LOGR_FILES);
if (-e "/etc/man.config") {
	# prefer to install psad.8 in /usr/local/man/man8 if this directory is configured in /etc/man.config
	if (open MPATH, "< /etc/man.config" and grep /MANPATH\s+\/usr\/local\/man/, <MPATH> and close MPATH) {
		copy("psad.8", "/usr/local/man/man8/psad.8");
		&perms_ownership("/usr/local/man/man8/psad.8", 0644);
	} else {
		my $mpath;
		open MPATH, "< /etc/man.config";
		while(<MPATH>) {
			my $line = $_;
			chomp $line;
			if ($line =~ /^MANPATH\s+(\S+)/) {
				$mpath = $1;
				last;
			}
		}
		close MPATH;
		if ($mpath) {
			my $path = $mpath . "/man8/psad.8";
			copy("psad.8", $path);
			&perms_ownership($path, 0644);
		} else {
			copy("psad.8", "/usr/man/man8/psad.8");
			&perms_ownership("/usr/man/man8/psad.8", 0644);
		}
	}
} else {
	copy("psad.8", "/usr/man/man8/psad.8");
	&perms_ownership("/usr/man/man8/psad.8", 0644);
}

my $distro = &get_distro();

if ($distro eq "redhat61" || "redhat62" || "redhat70" || "redhat71") {
	if (-e $INIT_DIR) {
		&logr(" ----  Copying psad-init -> ${INIT_DIR}/psad  ----\n", \@LOGR_FILES);
		copy("psad-init", "${INIT_DIR}/psad");
		&perms_ownership("${INIT_DIR}/psad", 0744);
		# remove signature checking from psad process if we are not running an iptables-enabled kernel
#		system "$Cmds{'perl'} -p -i -e 's|\\-s\\s/etc/psad/psad_signatures||' ${INIT_DIR}/psad" if ($kernel !~ /^2.3/ && $kernel !~ /^2.4/);
	} else {
		&logr("@@@@@  The init script directory, \"${INIT_DIR}\" does not exist!.  Edit the \$INIT_DIR variable in the config section.\n", \@LOGR_FILES);
	}
}
# need to put checks in here for redhat vs. other systems.
unless($fwcheck) {
	if(&check_firewall_rules(\%Cmds)) {
		my $running;
		my $pid;
		if (-e "/var/log/psad/pid.psad") {
			open PID, "< /var/log/psad/pid.psad";
			$pid = <PID>;
			close PID;
			chomp $pid;
			$running = kill 0, $pid;
		} else {
			$running = 0;
		}
		if ($execute_psad) {
			if ($distro eq "redhat61" || "redhat62" || "redhat70" || "redhat71") {
				if ($running) {
					&logr(" ----  Restarting the psad daemons...  ----\n", \@LOGR_FILES);
					system "${INIT_DIR}/psad restart";
				} else {
					&logr(" ----  Starting the psad daemons...  ----\n", \@LOGR_FILES);
					system "${INIT_DIR} -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips";
				}
			} else {
				if ($running) {
					&logr(" ----  Restarting the psad daemons...  ----\n", \@LOGR_FILES);
					system "$Cmds{'psad'} --Restart";
				} else {
					&logr(" ----  Starting the psad daemons...  ----\n", \@LOGR_FILES);
                                      	system "$Cmds{'psad'} -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips";
				}
			}
		} else {
			if ($distro eq "redhat61" || "redhat62" || "redhat70" || "redhat71") {
				if ($running) {
					&logr(" ----  An older version of psad is already running.  To execute, run \"${INIT_DIR}/psad restart\"  ----\n", \@LOGR_FILES);
				} else {
					&logr(" ----  To execute psad, run \"${INIT_DIR}/psad start\"  ----\n", \@LOGR_FILES);
				}
			} else {
				if ($running) {
					&logr(" ----  An older version of psad is already running.  kill pid $pid, and then execute:\n", \@LOGR_FILES);
					&logr("${INSTALL_DIR}/psad -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips\n", \@LOGR_FILES);
				} else {
					&logr("To start psad, execute: ${INSTALL_DIR}/psad -s /etc/psad/psad_signatures -a /etc/psad/psad_auto_ips\n", \@LOGR_FILES);
				}
			}	
		}
	}
}

exit 0;
#==================== end main =====================
sub check_old_psad_installation() {
	my $old_install_dir = "/usr/local/bin";
	move("${old_install_dir}/psad", "${INSTALL_DIR}/psad") if (-e "${old_install_dir}/psad");
	move("${old_install_dir}/psadwatchd", "${INSTALL_DIR}/psadwatchd") if (-e "${old_install_dir}/psadwatchd");
	move("${old_install_dir}/diskmond", "${INSTALL_DIR}/diskmond") if (-e "${old_install_dir}/diskmond");
	move("${old_install_dir}/kmsgsd", "${INSTALL_DIR}/kmsgsd") if (-e "${old_install_dir}/kmsgsd");
	return;
}
sub check_firewall_rules() {
	my $Cmds_href = shift;
	my @localips;
	### see which of the two firewall commands we are able to execute
	my $ipchains_rv = system "$Cmds_href->{'ipchains'} -nL > /dev/null 2>&1";
	$ipchains_rv >>= 8;	# return value from system call is a 16 bit number, the high byte is the real return value
	my $iptables_rv = system "$Cmds_href->{'iptables'} -nL > /dev/null 2>&1";
	$iptables_rv >>= 8;
	
        my @localips_tmp = `$Cmds_href->{'ifconfig'} -a |$Cmds_href->{'grep'} inet |$Cmds{'grep'} -v grep`;
        push @localips, (split /:/, (split /\s+/, $_)[2])[1] foreach (@localips_tmp);

	### prefer iptables so check it first
	if (! $iptables_rv && $ipchains_rv) {  ### iptables works if the return value is 0
		if (&check_iptables_rules(\@localips, $Cmds_href)) {
			return 1;
		} else {
			return 0;
		}
	} elsif (! $ipchains_rv && $iptables_rv) {
		if (&check_ipchains_rules(\@localips, $Cmds_href)) {
			return 1;
		} else {
			return 0;
		}
	} elsif ($iptables_rv && $ipchains_rv) {
		print "could not run either firewall\n";
	} elsif (! $iptables_rv && ! $ipchains_rv) {  ### this should _never_ happen (means the kernel is compatible with _both_ firewalls at the same time).
		print "kernel bad\n";
	}
	return;
}
sub check_iptables_rules() {
	my ($localips_aref, $Cmds_href) = @_;
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
				if (&check_destination($dst, $localips_aref)) {
					&logr(" ----  Your firewall setup looks good.  Unauthorized tcp and/or udp packets will be logged.\n", \@LOGR_FILES);
					return 1;
				}
			} elsif ($target eq "LOG" && $proto =~ /tcp/ && $prefix =~ /drop|reject|deny/i) {
				$drop_tcp = 1 if (&check_destination($dst, $localips_aref));
			} elsif ($target eq "LOG" && $proto =~ /udp/ && $prefix =~ /drop|reject|deny/i) {
				$drop_udp = 1 if (&check_destination($dst, $localips_aref));
			}
		}
	}
	if ($drop_tcp && $drop_udp) {
		&logr(" ----  Your firewall setup looks good.  Unauthorized tcp and/or udp packets will be logged.\n", \@LOGR_FILES);
		return 1;
	} elsif ($drop_tcp) {
		&logr(" ----  Your firewall will log unauthorized tcp packets, but not all udp packets.\n", \@LOGR_FILES);
		&logr("       Hence psad will be able to detect tcp scans, but not udp ones.\n", \@LOGR_FILES);
		&logr("       Suggestion: After making sure you accept any udp traffic that you need to (such as udp/53\n", \@LOGR_FILES);
		&logr("       for nameservice) add a rule to log and drop all other udp traffic with the following two commands:\n", \@LOGR_FILES);
		&logr("          # iptables -A INPUT -p udp -j LOG --log-prefix \"DENY \"\n", \@LOGR_FILES);
		&logr("          # iptables -A INPUT -p udp -j DROP\n", \@LOGR_FILES);
		return 1;
	} elsif ($drop_tcp) {
                &logr(" ----  Your firewall will log unauthorized udp packets, but not all tcp packets.\n", \@LOGR_FILES);
                &logr("       Hence psad will be able to detect udp scans, but not tcp ones.\n", \@LOGR_FILES);
                &logr("       Suggestion: After making sure you accept any tcp traffic that you need to (such as tcp/80\n", \@LOGR_FILES);
                &logr("       etc.) add a rule to log and drop all other tcp traffic with the following two commands:\n", \@LOGR_FILES);
                &logr("          # iptables -A INPUT -p tcp -j LOG --log-prefix \"DENY \"\n", \@LOGR_FILES);
                &logr("          # iptables -A INPUT -p tcp -j DROP\n", \@LOGR_FILES);
		return 1;
	}
	&logr(" ----  Your firewall does not include rules that will log dropped/rejected packets.\n", \@LOGR_FILES);
	&logr("       You need to include a default rule that logs packets that have not been accepted\n", \@LOGR_FILES);
	&logr("       by previous rules, and this rule should have a logging prefix of \"drop\", \"deny\"\n", \@LOGR_FILES);
	&logr("       or \"reject\".\n", \@LOGR_FILES);
	&logr("\n", \@LOGR_FILES);
	&logr("       FOR EXAMPLE:   Suppose that you are running a webserver to which you\n", \@LOGR_FILES);
	&logr("       also need ssh access.  Then a iptables ruleset that is compatible with psad\n", \@LOGR_FILES);
	&logr("       could be built with the following commands:\n", \@LOGR_FILES);
	&logr("\n", \@LOGR_FILES);
	&logr("              iptables -A INPUT -s 0/0 -d <webserver_ip> 80 -j ACCEPT\n", \@LOGR_FILES);
	&logr("              iptables -A INPUT -s 0/0 -d <webserver_ip> 22 -j ACCEPT\n", \@LOGR_FILES);
	&logr("              iptables -A INPUT -j LOG --log-prefix \" DROP\"\n", \@LOGR_FILES);
	&logr("              iptables -A INPUT -j DENY\n", \@LOGR_FILES);
	&logr("\n", \@LOGR_FILES);	
	&logr("@@@@@  Psad will not run without an iptables ruleset that includes rules similar to the\n", \@LOGR_FILES);
	&logr("@@@@@  last two rules above.\n", \@LOGR_FILES);
	return 0;
} 
sub check_ipchains_rules() {
	my ($localips_aref, $Cmds_href) = @_;
	#  target     prot opt     source                destination           ports
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
				if (&check_destination($dst, $localips_aref)) {
					&logr(" ----  Your firewall setup looks good.  Unauthorized tcp packets will be dropped and logged.\n", \@LOGR_FILES); 
                               		return 1;
				}
			}
		} elsif ($rule =~ /^(\w+)\s+(\w+)\s+(\S+)\s+\S+\s+(\S+)\s+(n\/a)/) {  # kernel 2.2.14 (and others) show "n/a" instead of "*"
			my ($target, $proto, $opt, $dst, $ports) = ($1, $2, $3, $4, $5);
			if ($target =~ /drop|reject|deny/i && $proto =~ /all|tcp/ && $opt =~ /....l./) {
				if (&check_destination($dst, $localips_aref)) {
					&logr(" ----  Your firewall setup looks good.  Unauthorized tcp packets will be dropped and logged.\n", \@LOGR_FILES);
					return 1;
				}
			}
		}
        }
	&logr(" ----  Your firewall does not include rules that will log dropped/rejected packets.  Psad will not work with such a firewall setup.\n", \@LOGR_FILES);
	return 0;
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
			return "redhat70" if ($l =~ /Red\sHat.*?7\.0/);
			return "redhat71" if ($l =~ /Red\sHat.*?7\.1/);
		}
		close ISSUE;
		return "NA";
	} else {
		return "NA";
	}
}
sub check_commands() {
	my $Cmds_href = shift;
	CMD: foreach my $cmd (keys %$Cmds_href) {
		### the daemons may not yet be installed, so skip check_commands() for each of them
		next CMD if ($cmd eq "psad" || $cmd eq "psadwatchd" || $cmd eq "kmsgsd" || $cmd eq "diskmond");
		unless (-e $Cmds_href->{$cmd}) {
			$real_location = `which $cmd 2> /dev/null`;
			chomp $real_location;
			if ($real_location) {
				&logr("@@@@@  $cmd is not located at $Cmds_href->{$cmd}.  Using $real_location\n", \@LOGR_FILES);
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
                if ($defc =~ /(\S+)\s+=\s+(.*?)\;/) {  # found a variable _assignment_ (does not include "my %var;")
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
								&logr("-----  Removing depreciated email format.  Preserving email address in production installation.\n", \@LOGR_FILES);
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
							&logr("*****  Using configuration value from production installation of psad for $type variable: $varname\n", \@LOGR_FILES);
						}
						print TMP "$defc\n";
					} else {
						$prodvars{$type}{$varname}{'FOUND'} = "Y";
						&logr("+++++  Adding new configuration $type variable \"$varname\" introduced in this version of psad.\n", \@LOGR_FILES);
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
						&logr("-----  Removing depreciated $type variable: \"$varname\" not needed in this version of psad.\n", \@LOGR_FILES);
					}
				}
			}	
			$print = 0;
		}
		$start = 0 if ($l =~ /\=\=\=\=\=\s+end\s+config\s+\=\=\=\=\=/);
	}
	close SRC;
	close TMP;
	move($prod_tmp, $productionfile);
#	`$Cmds_href->{'mv'} $prod_tmp $productionfile`;
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
sub create_varlogpsad() {
	unless (-e "/var/log/psad") {
		mkdir "/var/log/psad", 400;
	}
	return;
}
sub rm_perl_options() {
	my ($file, $Cmds_href) = @_;
	my $tmp = $file . ".tmp";
	move($file, $tmp);
	open TMP, "< $tmp";
	my @lines = <TMP>;
	close TMP;
	unlink $tmp;
	shift @lines;  ### get rid of the "#!/usr/bin/perl -w" line
	open F, "> $file";
	print F "#!$Cmds_href->{'perl'}\n";  ### put "#!/path/to/perl" line in with no perl options.
	print F $_ for (@lines);
	close F;
	return;
}
sub logr() {
        my ($msg, $files_aref) = @_;
        for my $f (@$files_aref) {
                if ($f eq "STDOUT" || $f eq "STDERR") {
                        if (length($msg) > 72) {
                                print $f  wrap("", $SUB_TAB, $msg);
                        } else {
                                print $f $msg;
                        }
                } else {
                        open F, ">> $f";
                        if (length($msg) > 72) {
                                print F wrap("", $SUB_TAB, $msg);
                        } else {
                                print F $msg;
                        }
                        close F;
                }
        }
        return;
}
sub usage_and_exit() {
        my $exitcode = shift;
        print <<_HELP_;

Usage: install.pl [-f] [-n] [-e] [-u] [-v] [-h]
	
	-n  --no_preserve	- disable preservation of old configs.
	-e  --exec_psad		- execute psad after installing.
        -f  --firewall_check    - disable firewall rules verification.
	-u  --uninstall		- uninstall psad.
	-v  --verbose		- verbose mode.
        -h  --help              - prints this help message.

_HELP_
        exit $exitcode;
}
