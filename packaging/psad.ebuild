# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header$

inherit eutils
inherit perl-module

IUSE=""

S=${WORKDIR}/${P}
DESCRIPTION="Port Scannning Attack Detection daemon"
SRC_URI="http://www.cipherdyne.org/psad/download/psad-${PV}.tar.bz2"
HOMEPAGE="http://www.cipherdyne.org/psad"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64 ~ia64 ~ppc ~alpha ~sparc ~hppa ~mips ~arm"

DEPEND="${DEPEND}
        dev-lang/perl"

RDEPEND="virtual/logger
        dev-perl/Unix-Syslog
        dev-perl/Date-Calc
        net-mail/mailx
        net-firewall/iptables"

src_compile() {
        cd ${S}/Psad
        SRC_PREP="no" perl-module_src_compile
        emake test

        cd ${S}/Net-IPv4Addr
        SRC_PREP="no" perl-module_src_compile
        emake test

        cd ${S}/IPTables/Parse
        SRC_PREP="no" perl-module_src_compile
        emake test

        cd ${S}/whois
        emake || die

        cd ${S}
        # We'll use the C binaries until we see them break
        emake || die
}

src_install() {
        keepdir /var/lib/psad /var/log/psad /var/run/psad /var/lock/subsys/${PN}
        dodir /etc/psad
        cd ${S}/Psad
        insinto /usr/lib/psad
        doins Psad.pm

        cd ${S}/Net-IPv4Addr
        insinto /usr/lib/psad/Net
        doins IPv4Addr.pm

        cd ${S}/IPTables/Parse
        insinto /usr/lib/psad/IPTables
        doins Parse.pm

        cd ${S}/whois
        # Makefile seems borken, do install by hand...
        insinto /usr
        newbin whois whois_psad
        newman whois.1 whois_psad.1

        cd ${S}
        insinto /usr
        dosbin kmsgsd psad psadwatchd
        dobin pscan

        cd ${S}
        insinto /etc/psad
        mv psad.conf psad.conf.sample
        doins psad.conf.sample
        doins *.conf
        doins psad_*

        cd ${S}/snort_rules
        dodir /etc/psad/snort_rules
        insinto /etc/psad/snort_rules
        doins *.rules

        insinto /etc/init.d
        newins ${FILESDIR}/psad-${PV}-init psad

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
        einfo "Several programs in the PSAD package are in the process of being converted to"
        einfo "compiled C from PERL. If you have any problems, please notify the PSAD"
        einfo "maintainers. Please do not take PSAD issues to the Bastille-Linux team."
        echo
        ewarn "Please be sure to edit /etc/psad/psad.conf to reflect your system's configuration"
        ewarn "or it may not work correctly or start up."
        echo
        ewarn "If you're using metalog as your system logger, please be aware that PSAD does"
        ewarn "not officially support it, and it probably won't work. Syslog-ng and sysklogd"
        ewarn "do seem to be working fine, though."
}

