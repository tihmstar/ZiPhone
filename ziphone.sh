#!/bin/bash

function banner() {
  echo "  ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
  echo "  ZZZZZZZZ                ZZZZZZZZZZZZ"
  echo "  ZZZZZZ                ZZZZZZZZZZZZ"
  echo "  ZZ                  ZZZZZZZZZZZZ"
  echo "  ZZ               ZZZZZZZZZZZZZ"
  echo " 	     ZZZZZZZZZZZZ "
  echo "  	  ZZZZZZZZZZZZ              ZZ"
  echo "       ZZZZZZZZZZZZ               ZZZZ"
  echo "    ZZZZZZZZZZZZ                ZZZZZZ"
  echo "  ZZZZZZZZZZZ                 ZZZZZZZZ"
  echo "ZZZZZZZZZZZZ              ZZZZZZZZZZZZ"
  echo "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
  echo "ZiPhone v3.6 by Zibri. https://ziphone.zibri.org"
  echo "Source code available at: http://lexploit.com"
  echo ""
}

function basic_usage() {
  echo "Usage: ziphone -Z [PnP Mode]"
  echo
  echo "       -Z Y: Zibri! Do Everything for me!"
  echo
  echo "       -Z N: Do Everything BUT do not Unlock!"
  echo
  echo "       -Z A: Show me advanced commands!"
  echo
}

function advanced_usage() {
  echo "Usage: ziphone [-b] [-e] [-u] [-a] [-j] [-r] [-sc] [-D] [-v] [-i imei] [-m MAC]"
  echo
  echo "       -b: Downgrade iPhone bootloader 4.6 to 3.9 and unlock 1.1.3-1.1.4."
  echo "       -u: Unlock iPhone 1.1.2 BL4.6 or 1.1.3-1.1.4 BL4.6 and BL3.9."
  echo "       -j: Jailbreak iPhone/iPod Touch 1.0-1.1.5 or 2.0 beta 2-3."
  echo "       -i: Change imei."
  echo "       -m: Change iPhone WiFi MAC address."
  echo "       -r: Reset iPhone WiFi MAC address to default."
  echo "       -e: Downgrade iPhone bootloader to 3.9, erase baseband, and enter Recovery (for a perfect restore)."
  echo "       -N: Exit Recovery Mode (normal boot)."
  echo "       -C: Make coffee. (and relax!)."
  echo "       -v: Debug boot (verbose)."
  echo
}

function connected() {
	killall -SIGSTOP AMPDevicesAgent > /dev/null 2>&1
	echo "Searching for iPhone or iPod Touch..."
	if ! irecovery -q 2>/dev/null | grep -q "CPID: 0x8900"; then
		echo  "ZiPhone can not connect to your iPhone or iPod Touch. Please make sure that:" 
		echo "The iPhone or iPod Touch is in Recovery Mode and connected with a USB Dock cable to the computer."
		echo "If your iPhone/iPod Touch is connected, enter it into Recovery Mode now. To do so, unplug the device, hold the power button"
		echo "for a few seconds and then 'slide to power off'.  "
		echo "With the device still powered off, hold the home button down "
		echo "and connect to the dock or cable.  The Apple logo will appear for a few "
		echo "seconds, and finally the 'connect to iTunes' graphic will appear."
		echo "Do not release the home button until the 'connect' graphic is visible." 
		echo "Try running ZiPhone again at that point." 
		exit 1
	else
		echo "Connected."
	fi
}

function disconnected() {
	echo "Disconnected."
}

function original_args() {
	irecovery -c 'setenv boot-partition 0' 
	irecovery -c 'setenv boot-args ""' 
}

function reset_wifi_mac_address() {
	irecovery -c 'setenv wifiaddr'
}

function save() {
	irecovery -c 'saveenv'
}

function exit_recovery() {
	echo "Booting normal mode..."
	original_args;
	save;
	irecovery -c 'fsboot'
	echo "Please wait..."
}

function verbose_args() {
	irecovery -c 'setenv boot-partition 0'
	irecovery -c 'setenv boot-args "-v"'
	save;
	irecovery -c 'fsboot'
	echo "Please wait..."
}

function ramdisk_hack() {
	echo "Working..."
	LIBIRECOVERY_IOS1_OVERWRITE_LOADADDR=0x09CC2000 irecovery -f zibri.dat
	irecovery -f igor.dat
    irecovery -c 'setenv boot-args "rd=md0 -s -x pmd0=0x09CC2000.0x0133D000"'
	irecovery -c 'saveenv'
	irecovery -c 'bootx'
	sleep 5;
	irecovery -f igor.dat
	irecovery -c 'bootx'
	echo "Waiting for the device to re-enter recovery mode..."
	while ! irecovery -q 2>/dev/null | grep -q "CPID: 0x8900"; do
		sleep 1;
	done
	irecovery -c 'fsboot'
	echo "Please wait..."
}

function jailbreak() {
	irecovery -c 'setenv jailbreak "1"'
}

function activate() {
	irecovery -c 'setenv activate "1"'
}

function downgrade_baseband_bootloader() {
	irecovery -c 'setenv bl39 "1"'
}

function unlock() {
	irecovery -c 'setenv unlock "1"'
}

function erase_baseband() {
	irecovery -c 'setenv ierase "1"'
}

function change_wifi_mac_address() {
	irecovery -c "setenv wifiaddr $1"
}


function change_imei() {
	unlock;
	irecovery -c "setenv imei $1"
}
      
function main(){
	argv=$@
	argc=$#
	if ! [ -f zibri.dat ]; then 
		echo "Cannot find zibri.dat!"
		exit 1
	fi

	if ! [ -f igor.dat ]; then 
		echo "Cannot find igor.dat!"
		exit 1
	fi

	if ! [ -f victor.dat ]; then 
		echo "Cannot find victor.dat!"
		exit 1
	fi

	banner;

	if [ "$argc" -lt 1 ]; then
		basic_usage;
		return 0;
	fi

	doExitRecovery="no";
	doResetWifiMacAddr="no";
	doVerboseArgs="no";
	doJailbreak="no";
	doActivate="no";
	doDowngradeBasebandBootloader="no";
	doUnlock="no";
	doEraseBaseband="no";
	changeMacAddr="";
	changeIMEI="";

	OPTIND=1         # Reset in case getopts has been used previously in the shell.
	while getopts "NZ:rvjabuem:i:" opt; do
		case "$opt" in
			Z)
				if [ "x$OPTARG" == "xY" ]; then
					jailbreak;
					activate;
					unlock;
				elif [ "x$OPTARG" == "xN" ]; then
					jailbreak;
					activate;
				elif [ "x$OPTARG" == "xA" ]; then
					advanced_usage;
					return 0;
				else
					echo "Unrecognised opt \"$OPTARG\""
				fi
				;;
			N)
				exit_recovery="yes";
				;;
			r)
				doResetWifiMacAddr="yes";
				;;
			v)
				doVerboseArgs="yes";
				;;
			j)
				doJailbreak="yes";
				;;
			a)
				doActivate="yes";
				;;
			b)
				doDowngradeBasebandBootloader="yes";
				;;
			u)
				doUnlock="yes";
				;;
			e)
				doEraseBaseband="yes";
				;;
			m)
				changeMacAddr="${OPTARG}";
				;;
			i)
				changeIMEI="${OPTARG}";
				;;

			*)
				echo "Unrecognised opt \"$opt\""
				exit 1;
			;;
		esac
	done
	
	irecovery -c 'setpicture 0'
	irecovery -c 'bgcolor 0 0 64'
	irecovery -c 'setenv auto-boot true'

	if [ "x${doExitRecovery}" == "xyes" ]; then
		exit_recovery;
		disconnected;
		return 0;
	fi

	if [ "x${doResetWifiMacAddr}" == "xyes" ]; then
		reset_wifi_mac_address;
	fi

	if [ "x${doVerboseArgs}" == "xyes" ]; then
		verbose_args;
	fi

	if [ "x${doJailbreak}" == "xyes" ]; then
		jailbreak;
	fi

	if [ "x${doActivate}" == "xyes" ]; then
		activate;
	fi

	if [ "x${doDowngradeBasebandBootloader}" == "xyes" ]; then
		downgrade_baseband_bootloader;
	fi

	if [ "x${doUnlock}" == "xyes" ]; then
		unlock;
	fi

	if [ "x${doEraseBaseband}" == "xyes" ]; then
		erase_baseband;
	fi

	if [ "x${changeMacAddr}" != "x" ]; then
		rex='([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}'
		if ! [[ "${changeMacAddr}" =~ $rex ]]; then 
			echo "The WiFi MAC address you have given is not valid. Enter a valid WiFi MAC address."
			exit 2
		fi
		change_wifi_mac_address ${changeMacAddr};
	fi

		if [ "x${changeIMEI}" != "x" ]; then
		rex='[0-9]{15,16}'
		if ! [[ "${changeIMEI}" =~ $rex ]]; then 
			echo "The IMEI you have given is not 15 or 16 characters. Enter a valid IMEI."
			exit 2
		fi
		change_imei ${changeIMEI};
	fi

    ramdisk_hack;
    disconnected;
}

main $@