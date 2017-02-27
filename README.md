# psad - Intrusion Detection with iptables Logs

## Introduction
The Port Scan Attack Detector `psad` is a lightweight system daemon written in
is designed to work with Linux iptables/ip6tables/firewalld firewalling code to
detect suspicious traffic such as port scans and sweeps, backdoors, botnet
command and control communications, and more. It features a set of highly
configurable danger thresholds (with sensible defaults provided), verbose alert
messages that include the source, destination, scanned port range, begin and
end times, TCP flags and corresponding nmap options, reverse DNS info, email
and syslog alerting, automatic blocking of offending IP addresses via dynamic
configuration of iptables rulesets, passive operating system fingerprinting,
and DShield reporting. In addition, `psad` incorporates many of the TCP, UDP,
and ICMP signatures included in the Snort intrusion detection system.
to detect highly suspect scans for various backdoor programs (e.g. EvilFTP,
GirlFriend, SubSeven), DDoS tools (Mstream, Shaft), and advanced port scans
(SYN, FIN, XMAS) which are easily leveraged against a machine via nmap. `psad`
can also alert on Snort signatures that are logged via
[fwsnort](https://github.com/mrash/fwsnort), which makes use of the iptables
string match extension to detect traffic that matches application layer
signatures. As of the 2.4.4 release, `psad` can also detect the IoT default
credentials scanning phase of the Mirai botnet.

## Visualizing Malicious Traffic
`psad` offers integration with `gnuplot` and `afterglow` to produce graphs of
malicious traffic. The following two graphs are of the Nachi worm from the
Honeynet [Scan30](http://old.honeynet.org/scans/scan30/) challenge. First, a
link graph produced by `afterglow` after analysis of the iptables log data by
`psad`:

![alt text][nachi-worm-link-graph]
[nachi-worm-link-graph]: images/nachi_worm.gif "Nachi Worm Link Graph"

The second shows Nachi worm traffic on an hourly basis from the Scan30 iptables
data:

![alt text][nachi-worm-hourly-graph]
[nachi-worm-hourly-graph]: images/nachi_worm_hourly.png "Nachi Worm Hourly Graph"

## Configuration Information
Information on config keywords referenced by psad may be found both in the
psad(8) man page, and also here:

http://www.cipherdyne.org/psad/docs/config.html

## Methodology
All information psad analyzes is gathered from iptables log messages.
psad by default reads the /var/log/messages file for new iptables messages and
optionally writes them out to a dedicated file (/var/log/psad/fwdata).
psad is then responsible for applying the danger threshold and signature logic
in order to determine whether or not a port scan has taken place, send
appropriate alert emails, and (optionally) block offending ip addresses.  psad
includes a signal handler such that if a USR1 signal is received, psad will
dump the contents of the current scan hash data structure to
/var/log/psad/scan_hash.$$ where "$$" represents the pid of the running psad
daemon.

NOTE:  Since psad relies on iptables to generate appropriate log messages
for unauthorized packets, psad is only as good as the logging rules included
in the iptables ruleset.  Usually the best way setup the firewall is with
default "drop and log" rules at the end of the ruleset, and include rules
above this last rule that only allow traffic that should be allowed through.
Upon execution, the psad daemon will attempt to ascertain whether or not such
a default deny rule exists, and will warn the administrator if it doesn't.
See the FW_EXAMPLE_RULES file for example firewall rulesets that are
compatible with psad.

Additionally, extensive coverage of psad is included in the book "Linux
Firewalls: Attack Detection and Response" published by No Starch Press, and a
supporting script in this book is compatible with psad.  This script can be
found here:

http://www.cipherdyne.org/LinuxFirewalls/ch01/

## Installation
See the INSTALL file in the psad sources directory.

## Firewall Setup
The main requirement for an iptables configuration to be compatible with psad
is simply that iptables logs packets. This is commonly accomplished by adding
rules to the INPUT and FORWARD chains like so:

```bash
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG
```

The rules above should be added at the end of the INPUT and FORWARD chains
after all ACCEPT rules for legitimate traffic and just before a corresponding
DROP rule for traffic that is not to be allowed through the policy. Note that
iptables policies can be quite complex with protocol, network, port, and
interface restrictions, user defined chains, connection tracking rules, and
much more. There are many pieces of software such as Shorewall and Firewall
Builder, that build iptables policies and take advantage of the advanced
filtering and logging capabilities offered by iptables. Generally the policies
built by such pieces of software are compatible with psad since they
specifically add rules that instruct iptables to log packets that are not part
of legitimate traffic. Psad can be configured to only analyze those iptables
messages that contain specific log prefixes (which are added via the
--log-prefix option), but the default as of version 1.3.2 is for psad to
analyze all iptables log messages for port scans, probes for backdoor
programs, and other suspect traffic. See the list of features offered by psad
for more information (http://www.cipherdyne.org/psad/features.html).

## Platforms
psad has been tested on RedHat 6.2 - 9.0, Fedora Core 1 and 2, and
Gentoo Linux systems running various kernels.  The only program that
specifically depends on the RedHat architecture is psad-init, which depends
on /etc/rc.d/init.d/functions.  For non-RedHat systems a more generic init
script is included called "psad-init.generic".  The psad init scripts are
mostly included as a nicety; psad can be run from the command line like any
other program.

## License
`psad` is released as open source software under the terms of
the **GNU General Public License (GPL v2+)**. The latest release can be found
at [https://github.com/mrash/psad/releases](https://github.com/mrash/psad/releases)

psad makes use of many of the TCP, UDP, and ICMP signatures available in
Snort (written by Marty Roesch, see http://www.snort.org).  Snort is a
registered trademark of Sourcefire, Inc.

## Contact
All feature requests and bug fixes are managed through github issues tracking.
However, you can email me (michael.rash_AT_gmail.com), or reach me through
Twitter ([@michaelrash](https://twitter.com/michaelrash)).
