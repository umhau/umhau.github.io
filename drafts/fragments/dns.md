> Nslookup is a service/tool to look up the dns query information. Converts the domain name or host to IP address. Nslookup can be used in two modes interactive and non-interactive mode. Interactive mode is used for us for manual checking and non-interactive mode help to script the checks for a large number of inputs. Also in the case of automated scripts, the non-interactive commands are used.

  nslookup 192.168.1.14
  nslookup fbcrsrv1

We can check the rDNS for the IP using the nslookup command.


host command is used for performing the dns lookups.

dig

Dig is the most commonly used command to look for the dns records. We can use this command to get a specific record or all the records in different ways. We can look at the dns records from specific dns server using “dig” command.  Customize the results based on the arguments passed with the command.  Using the trace option, we can look for the trace of the dns lookup.

traceroute
Traceroute command is used to diagnosing the network. Using the traceroute result, we can diagnose the trust delays and packet loss at each node in the network path. By analyzing the traceroute report, we can trace the IP block at the ISP ( Internet Service Provider ) level or track the network delay in the network path.