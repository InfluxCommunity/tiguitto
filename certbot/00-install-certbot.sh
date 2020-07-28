#!/bin/bash
#============================================================================
#       FILE: 00-install-certbot.sh
#       USAGE: sudo ./00-install-certbot.sh
#   DESCRIPTION: POSIX (hopefully) compatible script to install certbot and
#               enabling the HTTP Port for certbot via firewall
#============================================================================
ROOT_UID=0
E_NOTROOT=87

ENVFILE="certbot.env"


#===  FUNCTION  ================================================================
#          NAME:  determine_distro
#   DESCRIPTION:  determine which type of Linux Distribution the machine is
#    PARAMETERS:  none
#       RETURNS:  distribution name
#===============================================================================
function determine_distro ()
{
	if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
		DISTRO="CentOS"
	
	elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release ; then
		DISTRO="RHEL"
	
	elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release ; then
		DISTRO="Fedora"

	elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release ; then
		DISTRO="Debian"

	elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release ; then
		DISTRO="Ubuntu"

	else
		DISTRO=$(uname -s)

	fi
}    # ----------  end of function determine_distro  ----------


#===  FUNCTION  ================================================================
#          NAME:  install_certbot
#   DESCRIPTION:  install certbot binary on machine based on machine's distribution
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

function install_certbot ()
{
	
	echo "#-------------------------------------------------------------------------------"
	echo "#  Installing certbot on the machine "
	echo "#-------------------------------------------------------------------------------"
	
	
	determine_distro

	case $DISTRO in

	"CentOS"|"RHEL")
		echo -e "Using yum to install certbot on ${DISTRO} \n"
		echo -e "Enabling Extra Packages for Enterprise Linux (EPEL)\n"
		
		yum --enablerepo=extras install epel-release
		yum install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine \n"
			exit $retval
		fi
	;;

	"Fedora")
		echo -e "Using dnf to install certbot on ${DISTRO}\n"
		dnf install certbot
	;;

	"Debian")
		echo -e "Using apt-get to install certbot on ${DISTRO} \n"

		apt-get install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine \n"
			exit $retval
		fi
	;;

	"Ubuntu")

		source /etc/*-release

		echo -e "Distribution Version: $DISTRIB_RELEASE\n"

		case $DISTRIB_RELEASE in
			"19.04"|"20.04")
				apt-get update
				apt-get install -y software-properties-common
				add-apt-repository universe
				apt-get update
			;;

			"18.04"|"16.04")
				apt-get update
				apt-get install -y software-properties-common
				add-apt-repository universe
				add-apt-repository ppa:certbot/certbot
				apt-get update
			;;

			*)
				echo -e "Check Certbot official docs for manual installation on this version.\n"
			;;
		esac

		echo -e "Installing Certbot\n"
		apt-get install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine\n"
			exit $retval
		fi
	;;
	
	*)
		echo -e "Unknown Distribution. Please install certbot manually\n"
		exit 1
	;;

	esac    # --- end of case ---

}    # ----------  end of function install_certbot  ----------

#-------------------------------------------------------------------------------
#   Check if Script is running with Root Privileges
#-------------------------------------------------------------------------------


if [ "$UID" -ne "$ROOT_UID" ]; then
	echo -e "Must be Root to run this script\n"
	exit $E_NOTROOT
fi

echo "#-------------------------------------------------------------------------------"
echo "#   Checking if certbot exists on machine"
echo "#-------------------------------------------------------------------------------"

if ! command -v certbot &> /dev/null; then
	echo -e "certbot not installed on machine\n"
	install_certbot
else
	echo -e "certbot already exists on machine\n"
fi

echo "#-------------------------------------------------------------------------------"
echo "#   Enabling HTTP Port (80) via Firewall "
echo "#-------------------------------------------------------------------------------"

determine_distro
echo "DISTRO=$DISTRO" >> $ENVFILE
echo "Enabling HTTP port for certbot on ${DISTRO}"


case $DISTRO in
	"Raspbian"|"Debian"|"Ubuntu")
		if ! command -v ufw &> /dev/null; then
			echo -e "no ufw installed on machine\n"
			echo -e "installing ufw\n"
			apt install ufw
		fi

		echo -e "enabling HTTP port on Machine\n"
		ufw allow 80
	;;
		

	"CentOS"|"RHEL"|"Fedora")
		if ! command -v firewall-cmd &> /dev/null; then
			echo -e "no firewall-cmd installed on machine\n"
			echo -e "installing firewall-cmd\n"
			yum install firewall-cmd
		fi
		
		echo -e "enabling HTTP port on machine\n"
		firewall-cmd --add-service=http
		firewall-cmd --runtime-to-permanent
	;;

	*)
		echo -e "Unknown Distribution. Please enable HTTP Port manually\n"
		exit 2
	;;

esac    # --- end of case ---

exit 0
