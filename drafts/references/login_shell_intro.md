
The text displayed before the login prompt is stored in /etc/issue (there's a related file, /etc/motd, that's displayed after the user logs in, before their shell is started). It's just a normal text file, but it accepts a bunch of escape sequences:

    \b -- Baudrate of the current line.
    \d -- Current date.
    \s -- System name, the name of the operating system.
    \l -- Name of the current tty line.
    \m -- Architecture identifier of the machine, eg. i486
    \n -- Nodename of the machine, also known as the hostname.
    \o -- Domainname of the machine.
    \r -- Release number of the OS, eg. 1.1.9.
    \t -- Current time.
    \u -- Number of current users logged in.
    \U -- The string "1 user" or " users" where is the number of current users logged in.
    \v -- Version of the OS, eg. the build-date etc.

