#!/usr/bin/env bash

# Use this script to test if a given TCP host/port are available

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage() {
    cat << USAGE >&2
Usage:
    $cmdname host:port:sleep [-s] [-q] [-t timeout] [-- command args]
    host:port:sleep         Host and port of the service to wait for.
                            Sleep after the port is up to ensure application is "ready" (in secs, optional, default 3s).
                            Do not like to sleep? Pass 0.
    -s                      Only execute subcommand if the test succeeds
    -q                      Do not output any status messages
    -t TIMEOUT              Timeout in seconds, zero for no timeout (does not honor sleep time)
    -- COMMAND ARGS         Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for() {
    local wait_host=$1
    local wait_ports=$2
    local sleep_time=$3

    case "${wait_ports}" in
        *-*)
        wait_ports=(${wait_ports//-/ })
        wait_ports=($(seq ${wait_ports[0]} ${wait_ports[1]}))
        ;;
        *,*)
        wait_ports=(${wait_ports//,/ })
        ;;
        *)
        wait_ports=(${wait_ports})
        ;;
    esac

    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $wait_host:${wait_ports[@]}"
    else
        echoerr "$cmdname: waiting for $wait_host:${wait_ports[@]} without a timeout"
    fi

    local start_ts=$(date +%s)
    for wait_port in ${wait_ports[@]}
    do
        while :
        do
            (echo > /dev/tcp/$wait_host/$wait_port) >/dev/null 2>&1
            local result=$?
            if [[ $result -eq 0 ]]; then
                local end_ts=$(date +%s)
                echoerr "$cmdname: $wait_host:$wait_port is available after $((end_ts - start_ts)) seconds"
                break
            fi
            sleep 1
        done
    done

    # Sleep for extra time to make sure that the application is thoroughly started and is "ready" to process requests
    echoerr "$cmdname: sleeping for ${sleep_time}s to ensure service is \"ready\""
    sleep $sleep_time

    return $result
}

wait_for_wrapper() {
    local wait_host=$1
    local wait_port=$2
    local sleep_time=$3

    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [[ $QUIET -eq 1 ]]; then
        timeout $TIMEOUT $0 $wait_host:$wait_port:$sleep_time -q -c -t $TIMEOUT &
    else
        timeout $TIMEOUT $0 $wait_host:$wait_port:$sleep_time -c -t $TIMEOUT &
    fi

    PID=$!
    trap "kill -INT -$PID" INT

    wait $PID
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for $wait_host:$wait_port"
    fi

    return $RESULT
}

parse_arguments() {
    local index=0

    while [[ $# -gt 0 ]]
    do
        case "$1" in
            *:* )
                hostport=(${1//:/ })
                HOST[$index]=${hostport[0]}
                PORT[$index]=${hostport[1]}
                SLEEP[$index]=${hostport[2]:-3}
                shift 1
                ;;
            -c)
                CHILD=1
                shift 1
                ;;
            -q)
                QUIET=1
                shift 1
                ;;
            -s)
                STRICT=1
                shift 1
                ;;
            -t)
                TIMEOUT="$2"
                if [[ $TIMEOUT == "" ]]; then break; fi
                shift 2
                ;;
            --)
                shift
                CLI="$@"
                break
                ;;
            -h)
                usage
                ;;
            *)
                echoerr "Unknown argument: $1"
                usage
                ;;
        esac
        let index+=1
    done

    if [[ ${#HOST[@]} -eq 0 || ${#PORT[@]} -eq 0 ]]; then
        echoerr "Error: you need to provide a host and port to test."
        usage
    fi
}

iterate_hosts() {
    local result=0
    local index=0
    local wait_function=$1

    while [[ $result -eq 0 && $index -lt ${#HOST[@]} ]]; do
        ($wait_function ${HOST[$index]} ${PORT[$index]} ${SLEEP[$index]})
        result=$?
        let index+=1
    done

    echo $result
}

wait_for_services() {
    TIMEOUT=${TIMEOUT:-11}
    STRICT=${STRICT:-0}
    CHILD=${CHILD:-0}
    QUIET=${QUIET:-0}

    if [[ $CHILD -gt 0 ]]; then
        exit $(iterate_hosts wait_for)
    else
        if [[ $TIMEOUT -gt 0 ]]; then
            RESULT=$(iterate_hosts wait_for_wrapper)
        else
            RESULT=$(iterate_hosts wait_for)
        fi
    fi
}

parse_arguments "$@"
wait_for_services

if [[ $CLI != "" ]]; then
    if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec $CLI
else
    exit $RESULT
fi
