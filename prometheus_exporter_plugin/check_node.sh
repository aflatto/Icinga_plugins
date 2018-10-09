#!/bin/bash
# A plugin to use Promethues [https://promethues.io] node/statsd exporter as the remote agent for data collection
#
# Written by : Assaf Flatto <assaf@aikilinux.com>
targets="node,statsd"
version="0.1"
w_thresh="0"
c_thresh="0"

help () {
  echo "#####################################"
  echo "The plugin requires the following parameters"
  echo "-t|--target, specify the target exporter ($targets)"
  echo "-h|--host, the FQDN or IP of the target machine,"
  echo "-p|--port, the port used to query the data,"
  echo "-m|--metric, the metric you want to obtain,"
  echo "-w|--warning, the warning threshold."
  echo "-c|--critical, the Criticl threshold."
  echo "-v|--version, show script version"
  echo "--help, show this help "
exit 1
}

if [ $# -eq "0" ]; then
  help
fi

while [[ $# -ge 1 ]]
do
key="$1"

case $key in
    -h|--host)
    host="$2"
    shift
    ;;
    -t|--target)
    target="$2"
    if [ "$target" == "node" ] ; then
      port="9100"
    elif [ "$target" == "statsd" ] ; then
      port="9102"
    elif [ "$target" != "statsd" ] &&  [ "$target" != "node" ] ; then
      echo "UNKNOWN - Incorrect Target, valid options are: $targets"
      exit 3
    fi
    shift
    ;;
    -p|--port)
    port="$2"
    shift
    ;;
    -m|--metric)
    metric="$2"
    shift
    ;;
    -w|--warning)
    w_thresh="$2"
    shift
    ;;
    -c|--critical)
    c_thresh="$2"
    shift
    ;;
    -v|--version)
     echo "$(basename $0) is $version"
     exit 0
    ;;
    *)
    help
    ;;
esac
shift
done

con=$(curl -IsS http://"$host":"$port"/metrics 2>&1)
if  [ $? != "0" ] ; then
    echo "Critical - $con"
    exit 2
fi

result=$(curl -s http://"$host":"$port"/metrics |grep -w "$metric" |grep -v '#' |awk '{print $2}')
if [ -z "$result" ] ; then
      echo "UNKNOWN - $metric in not a valid metric."
      exit 3
elif [ "$result" -gt "$c_thresh" ] ; then
        echo "Critical - $metric value of $result is higher then $c_thresh"
        exit 2
elif  [ "$result" -le "$c_thresh" ] &&  [ "$result" -gt "$w_thresh" ] ; then
        echo "Warning- $metric value of $result is higher then $w_thresh"
        exit 1
elif  [ "$result" -lt "$w_thresh" ] ; then
        echo "OK - $metric value of $result"
        exit 0
fi
