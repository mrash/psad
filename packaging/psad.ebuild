# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-firewall/psad/psad-1.4.2.ebuild,v 1.3 2005/11/28 12:11:33 mcummings Exp $

inherit eutils perl-app

IUSE=""

DESCRIPTION="Port Scanning Attack Detection daemon"
SRC_URI="http://www.cipherdyne.org/psad/download/${P}.tar.bz2"
HOMEPAGE="http://www.cipherdyne.org/psad"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64 ~ppc ~alpha ~sparc"

DEPEND="${DEPEND}
	dev-lang/perl"

RDEPEND="virtual/logger
	dev-perl/Unix-Syslog
	dev-perl/Date-Calc
	virtual/mailx
	net-firewall/iptables"

src_compile() {
	cd ${S}/Psad
	SRC_PREP="no" perl-module_src_compile
	emake test

	cd ${S}/Net-IPv4Addr
	SRC_PREP="no" perl-module_src_compile
	emake test

	cd ${S}/IPTables-Parse
	SRC_PREP="no" perl-module_src_compile
	emake test

	cd ${S}/IPTables-ChainMgr
	SRC_PREP="no" perl-module_src_compile
	emake test

	cd ${S}
	# We'll use the C binaries
	emake || die "Make failed: daemons"
}

src_install() {
	local myhostname=
	local mydomain=

	doman *.8

	keepdir /var/lib/psad /var/log/psad /var/run/psad /var/lock/subsys/${PN}
	dodir /etc/psad
	cd ${S}/Psad
	emake install DESTDIR=${D} || die "Install failed: Psad.pm"

	cd ${S}/Net-IPv4Addr
	emake install DESTDIR=${D} || die "Install failed: Net-IPv4Addr.pm"

	cd ${S}/IPTables-ChainMgr
	emake install DESTDIR=${D} || die "Install failed: IPTables-Mgr.pm"

	cd ${S}/IPTables-Parse
	emake install DESTDIR=${D} || die "Install failed: IPTables-Parse.pm"

	cd ${S}
	insinto /usr
	dosbin kmsgsd psad psadwatchd
	newsbin fwcheck_psad.pl fwcheck_psad
	dobin pscan

	cd ${S}

	fix_psad_conf

	insinto /etc/psad
	doins *.conf
	doins psad_*
	doins auto_dl icmp_types posf signatures pf.os

	cd ${S}/init-scripts
	exeinto /etc/init.d
	newexe psad-init.gentoo psad

	cd ${S}/snort_rules
	dodir /etc/psad/snort_rules
	insinto /etc/psad/snort_rules
	doins *.rules

	cd ${S}
	dodoc BENCHMARK CREDITS Change* FW_EXAMPLE_RULES README LICENSE SCAN_LOG
}

pkg_postinst() {
	if [ ! -p ${ROOT}/var/lib/psad/psadfifo ]
	then
		ebegin "Creating syslog FIFO for PSAD"
		mknod -m 600 ${ROOT}/var/lib/psad/psadfifo p
		eend $?
	fi

	echo
	einfo "Please be sure to edit /etc/psad/psad.conf to reflect your system's"
	einfo "configuration or it may not work correctly or start up. Specifically, check"
	einfo "the validity of the HOSTNAME setting and replace the EMAIL_ADDRESSES and"
	einfo "HOME_NET settings at the least."
	echo
	if has_version ">=app-admin/syslog-ng-0.0.0"
	then
		ewarn "You appear to have installed syslog-ng. If you are using syslog-ng as your"
		ewarn "default system logger, please change the SYSLOG_DAEMON entry in"
		ewarn "/etc/psad/psad.conf to the following (per examples in psad.conf):"
		ewarn "		SYSLOG_DAEMON	syslog-ng;"
		echo
	fi
	if has_version ">=app-admin/sysklogd-0.0.0"
	then
		einfo "You have sysklogd installed. If this is your default system logger, no"
		einfo "special configuration is needed. If it is not, please set SYSLOG_DAEMON"
		einfo "in /etc/psad/psad.conf accordingly."
		echo
	fi
	if has_version ">=app-admin/metalog-0.0"
	then
		ewarn "You appear to have installed metalog. If you are using metalog as your"
		ewarn "default system logger, please change the SYSLOG_DAEMON entry in"
		ewarn "/etc/psad/psad.conf to the following (per examples in psad.conf):"
		ewarn "		SYSLOG_DAEMON	metalog"
	fi
}

fix_psad_conf() {
	cp psad.conf psad.conf.orig

	# Ditch the _CHANGEME_ for hostname, substituting in our real hostname
	[ -e /etc/hostname ] && myhostname="$(< /etc/hostname)"
	[ "${myhostname}" == "" ] && myhostname="$HOSTNAME"
	mydomain=".$(grep ^domain /etc/resolv.conf | cut -d" " -f2)"
	sed -i "s:HOSTNAME\(.\+\)\_CHANGEME\_;:HOSTNAME\1${myhostname}${mydomain};:" psad.conf || die "fix_psad_conf failed"

	# Fix up paths
	sed -i "s:/sbin/syslogd:/usr/sbin/syslogd:g" psad.conf || die "fix_psad_conf failed"
	sed -i "s:/sbin/syslog-ng:/usr/sbin/syslog-ng:g" psad.conf || die "fix_psad_conf failed"
	sed -i "s:/bin/uname:/usr/bin/uname:g" psad.conf || die "fix_psad_conf failed"
	sed -i "s:/bin/mknod:/usr/bin/mknod:g" psad.conf || die "fix_psad_conf failed"
}
