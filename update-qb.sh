#!/bin/sh

script=$(readlink -f "$0")
script_dir=$(dirname "$script")

# natmap
public_addr=$1
public_port=$2
ip4p=$3
private_port=$4
protocol=$5

port=$public_port

echo 
echo "External IP - $public_addr:$public_port, bind port $private_port, $protocol"
echo 

# qBittorrent

interface=""
host="192.168.0.74"
web_port="5555"
username="admin"
password="12345"

# Update qBittorrent listen port.

retry_interval=117


rsf="$script_dir/qbs_running"
rs=0
rs_b=0
wait_to_exit=$(( $retry_interval + 15 ))

if [ -f $rsf ]
then
  rs=$(cat $rsf)
  rs=$(( $rs + 1 ))
  echo $rs > $rsf
  sleep $wait_to_exit
  
  if [ ! -f $rsf ]
  then
    exit 100
  fi
  
  rs_b=$(cat $rsf)
  
  if [ $rs -ne $rs_b ]
  then
    exit $rs
  fi
  
  echo 0 > $rsf
else
  echo 0 > $rsf
fi

x=1
qb_cookie=nul

# If app isn't online, try 117 seconds later. 
# ( Loop last 48 hours unless this script is invoked again or app is online. )
while [ $x -le 1440 ]
do
  if [ ! -f $rsf ]
  then
    exit 101
  fi
  
  rs=$(cat $rsf)
  if [ $rs -gt 0 ]
  then
    echo 'Another running script detected, exit.'
    exit 111
  fi
  
  qb_cookie=$(curl -m 3 -s -i --data "username=$username&password=$password" http://$host:$web_port/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
  
  if [[ $(expr match "$qb_cookie" '.\+=') -gt 3 ]]
  then
    echo "Update qBittorrent listen port to $public_port.."
    
    curl -m 5 -s -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$port'"}' "http://$host:$web_port/api/v2/app/setPreferences"
    break
  fi
  x=$(( $x + 1 ))
  sleep $retry_interval
done

# iptables

echo 

tdrsh="$script_dir/qbs_tdr"

if [ -f $tdrsh ]
then
  sh $tdrsh
fi

d_rule=" "

sleep 1
echo "add rule"

if [ -z $interface ]
then
  iptables -t nat -I PREROUTING -p $protocol --dport $private_port -j DNAT --to-destination $host:$port
  d_rule="iptables -t nat -D PREROUTING -p $protocol --dport $private_port -j DNAT --to-destination $host:$port"
else
  iptables -t nat -I PREROUTING -i $interface -p $protocol --dport $private_port -j DNAT --to-destination $host:$port
  d_rule="iptables -t nat -D PREROUTING -i $interface -p $protocol --dport $private_port -j DNAT --to-destination $host:$port"
fi

echo "#! /bin/sh
# External IP - $public_addr:$public_port, bind port $private_port, $protocol
sleep 1
echo 'delete rule'
$d_rule
" > $tdrsh

rm $rsf

echo Fin
exit 0
