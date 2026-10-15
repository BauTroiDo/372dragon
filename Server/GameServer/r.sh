#!/bin/bash
env=$1
processid=$2
svrtype=$3

if  [ ! -n "$svrtype" ] ;then
    svrtype="Game"
fi

# unified paths - single source of truth
script_root=/home/ubuntu/cys-test-20260913/Game_2/Script
scene_config=/home/ubuntu/cys-test-20260913/Game_2/Scene
config_path=/home/ubuntu/cys-test-20260913/configs/%s

port=$((6000 + processid))
TCPListeningnum=`netstat -an | egrep ":${port}" | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' |wc -l`
echo "TCPListeningnum =" $TCPListeningnum
if [ "$svrtype" = "Game" ] && [ $TCPListeningnum -gt 0 ] ;then
    chmod +x nc.sh
    chmod +x stop.exp
    ./stop.exp $port
    if [ "$env" = "debug" ] ;then
        sleep 5s
    else
        sleep 60s
    fi
fi
cd framework && make linux && cd ..
make
exec_target=$svrtype"_tlbb_"$processid
echo "target =" $exec_target
ID=`ps -ef | grep "$exec_target" | grep -v '$0' | grep -v "grep" | awk '{print $2}'`
echo "pid =" $ID
for id in $ID
do
sudo kill $id
echo "killed $id"
done
cp ./framework/skynet ./framework/$exec_target
chmod +x ./framework/$exec_target
sleep 10s
lua config_maker.lua "$env" "$script_root" $processid "$svrtype" "$scene_config" "$config_path" > config
ulimit -c unlimited

./framework/$exec_target config
echo "start server ok in env = $env, processid = $processid"
