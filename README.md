`wait-for-it.sh` is a pure bash script that will wait on the availability of a host and TCP port.  It is useful for synchronizing the spin-up of interdependent services, such as linked docker containers.  Since it is a pure bash script, it does not have any external dependencies.

## Setup

```
wget https://raw.githubusercontent.com/piyush-kansal/wait-for-it/master/wait-for-it.sh
chmod 755 wait-for-it.sh
```

## Usage

```
wait-for-it.sh host1:port1:sleep1 host2:port2:sleep2 [-s] [-q] [-t timeout] [-- command args]
host:port:sleep         Host and port of the service to wait for. Once the port is available, may want to sleep to 
                        ensure the application is "ready" (in secs, optional, default 3s). Do not like to sleep? Pass 0.
                        To wait for multiple hosts, pass more hosts separated by space eg. h1:p1:s1 h2:p2:s2
                        To wait for multiple ports on the same host, pass ports separated by comma eg. h1:p1,p2,p3:s1
                        To wait for a port range on the same host, pass ports separated by hypen eg. h1:p1-pN:s1
-s                      Only execute subcommand if the test succeeds
-q                      Do not output any status messages
-t TIMEOUT              Timeout in seconds, zero for no timeout (honours sleep time when t > 0)
-- COMMAND ARGS         Execute command with args after the test finishes
```

## Examples

To see if we can access port 80 on www.google.com and echo the message `google is up`.

```
$ ./wait-for-it.sh www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting 14 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
wait-for-it.sh: sleeping for 3s to ensure service is "ready"
google is up
```

To see if we can access port 5432 on postgres and wait for 10s for postgres table initialization to complete and start the app server.

```
$ ./wait-for-it.sh postgres:5432:10 -- appServer.py start
wait-for-it.sh: waiting 21 seconds for postgres:5432
wait-for-it.sh: postgres:5432 is available after 0 seconds
wait-for-it.sh: sleeping for 10s to ensure service is "ready"
appServer started.
```

To see if we can access ports 2181, 2888, 3888 on zookeeper, do not sleep after the port check is complete and do no execute a subcommand. Useful when you want to refer to your containers with names instead of ip and have multiple ports to check on that container. So, instead of writing `zookeeper:2181 zookeeper:2888 zookeeper:3888`, you can keep it clean via `zookeeper:2181,2888,3888`.

```
$ ./wait-for-it.sh zookeeper:2181,2888,3888:0
wait-for-it.sh: waiting 11 seconds for zookeeper:2181
wait-for-it.sh: zookeeper:2181 is available after 0 seconds
wait-for-it.sh: waiting 11 seconds for zookeeper:2888
wait-for-it.sh: zookeeper:2888 is available after 1 seconds
wait-for-it.sh: waiting 11 seconds for zookeeper:3888
wait-for-it.sh: zookeeper:3888 is available after 2 seconds
```

To see if we can access ports 6379-6390 on redis and wait for 5s for redis to get initialized with some data. Useful when you want to refer to your containers with names instead of ip and have a port range to check on that container. So, instead of writing `redis:6379:5 redis:6380:5 ... redis:6390:5`, you can keep it clean via `redis:6379-6390:5`.

```
$ ./wait-for-it.sh redis:6379-6390:5
wait-for-it.sh: waiting 16 seconds for redis:6379
wait-for-it.sh: redis:6379 is available after 0 seconds
wait-for-it.sh: sleeping for 5s to ensure service is "ready"
...
wait-for-it.sh: waiting 16 seconds for redis:6390
wait-for-it.sh: redis:6390 is available after 1 seconds
wait-for-it.sh: sleeping for 5s to ensure service is "ready"
```

You can set your own timeout with the `-t` option. Setting the timeout value to 0 will disable the timeout:

```
$ ./wait-for-it.sh -t 0 www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting for www.google.com:80 without a timeout
wait-for-it.sh: www.google.com:80 is available after 0 seconds
wait-for-it.sh: sleeping for 3s to ensure service is "ready"
google is up
```

The subcommand will be executed regardless if the service is up or not. If you wish to execute the subcommand only if the service is up, add the `-s` argument. In this example, we will test port 81 on www.google.com which will fail:

```
$ ./wait-for-it.sh www.google.com:81:0 -t 1 -s -- echo "google is up"
wait-for-it.sh: waiting 1 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 1 seconds for www.google.com:81
wait-for-it.sh: strict mode, refusing to execute subprocess
```

If you don't want to execute a subcommand, leave off the `--` argument. This way, you can test the exit condition of `wait-for-it.sh` in your own scripts, and determine how to proceed:

```
$ ./wait-for-it.sh www.google.com:80
wait-for-it.sh: waiting 14 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
$ echo $?
0
$ ./wait-for-it.sh www.google.com:81
wait-for-it.sh: waiting 14 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 14 seconds for www.google.com:81
$ echo $?
124
```

Why `3` and `11` as sleep and timeout respectively?
```
I just love prime numbers!
```
