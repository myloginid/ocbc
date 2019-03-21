# iperf3-test-util
Utility scripts that use iperf3 to test the cluster network bandwidth. There are two main scripts:

### launch-test.sh
This is a iperf3 launcher script that is written in bash. It helps to automate the executation if the iperf3 server and client to each of the nodes in the cluster and collect the results in JSON format.

```
IPERF Cluster Network Benchmark Utility v

USAGE:
  ./launch-test.sh [OPTIONS]

OPTIONS:
  -h, --hostfile <arg>
        File containing the list of hosts (default host.ini).

  -u, --sshuser <arg>
        User account used for SSH to the hosts. This account must be able to
        SSH without specifying a password.

IPERF OPTIONS:
  -p, --port <arg>
        Set server port to listen on/connect to (default 5201)

  -P, --parallel <arg>
        Number of parallel client streams to run (default 5).

  -t, --time <arg>
        Time in seconds to transmit for (default 10 secs).

CLOUDERA MANAGER OPTIONS:
  --cmurl <arg>
        Cloudera Manager URL (e.g. http://cm-mycluster.com:7180).

  --cmuser <arg>
        Cloudera Manager username.

  --cmpassword <arg>
        Cloudera Manager user password.

```
***Examples:***

```
# Start iperf3 tests using a host file
$ cat hosts
node01.domain.org
node02.domain.org
node03.domain.org
$ ./launch-test.sh -h hosts -u root
```


### Zip and send the results directory, will be called like RESULTS-YYMMDD-HHMMSS

## Pre-requisites
### Supported Versions:
The toolkit has only been tested on the following version of the software:

* OS - RHEL 7.3/7.4, CentOS 7.3/7.4
* iperf version 3.1.7

Other operating systems and iperf3 version may work, but have not been tested.

### Install iperf3:
On RHEL 7 or CentOS 7, iperf3 is available in the base repository. Run "yum install iperf3" to install. You have to install iperf3 on all the nodes in the cluster that you intend to run the network bandwidth test on.

### Install RPM Manually:
Download the RPM from [https://iperf.fr/iperf-download.php]().


## HTML Sample Result Output

![Sample result in HTML](help/iperf3_sample.png)
