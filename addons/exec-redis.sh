#!/bin/bash
 
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -f`}"
INTERVAL="${COLLECTD_INTERVAL:-10}"
PORTS=6380,6379
 
while sleep "$INTERVAL"
do

    for PORT in $(echo $PORTS | tr , ' ' ); do 
        info=$(echo info|redis-cli -p $PORT)
        connected_clients=$(echo "$info"|awk -F : '$1 == "connected_clients" {print $2}')
        connected_slaves=$(echo "$info"|awk -F : '$1 == "connected_slaves" {print $2}')
        uptime=$(echo "$info"|awk -F : '$1 == "uptime_in_seconds" {print $2}')
        expired_keys=$(echo "$info"|awk -F : '$1 == "expired_keys" {print $2}')
        evicted_keys=$(echo "$info"|awk -F : '$1 == "evicted_keys" {print $2}')
        used_memory=$(echo "$info"|awk -F ":" '$1 == "used_memory_rss" {print $2}'|sed -e 's/\r//')
        changes_since_last_save=$(echo "$info"|awk -F : '$1 == "rdb_changes_since_last_save" {print $2}')
        total_commands_processed=$(echo "$info"|awk -F : '$1 == "total_commands_processed" {print $2}')
        keys=$(echo "$info"|egrep -e "^db0"|sed -e 's/^.\+:keys=//'|sed -e 's/,.\+//')
         
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_connected-clients interval=$INTERVAL N:$connected_clients"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_connected-slaves interval=$INTERVAL N:$connected_slaves"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_uptime interval=$INTERVAL N:$uptime"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_memory_rss interval=$INTERVAL N:$used_memory:U"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_changes_since_last_save interval=$INTERVAL N:$changes_since_last_save"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_commands_processed interval=$INTERVAL N:$total_commands_processed"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_keys interval=$INTERVAL N:$keys"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_expired_keys interval=$INTERVAL N:$expired_keys"
        echo "PUTVAL $HOSTNAME/redis-$PORT/redis_evicted_keys interval=$INTERVAL N:$evicted_keys"

        if (( $PORT == 6380 )); then 
            llen_queue_general=$(echo llen Queue:general |redis-cli -p $PORT)
            llen_queue_pfdhcplistener=$(echo llen Queue:pfdhcplistener |redis-cli -p $PORT)
            llen_queue_pfdetect=$(echo llen Queue:pfdetect |redis-cli -p $PORT)
            echo "PUTVAL $HOSTNAME/redis-$PORT/pf_redis_queue_general_llen interval=$INTERVAL N:$llen_queue_general"
            echo "PUTVAL $HOSTNAME/redis-$PORT/pf_redis_queue_pfdhcplistener_llen interval=$INTERVAL N:$llen_queue_pfdhcplistener"
            echo "PUTVAL $HOSTNAME/redis-$PORT/pf_redis_queue_pfdetect_llen interval=$INTERVAL N:$llen_queue_pfdetect"
        fi
    done
 
done
