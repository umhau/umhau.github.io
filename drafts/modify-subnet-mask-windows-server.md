So if you know enough to recognize what a subnet mask is, I'd expect you to know better than to be changing one on Windows Server. However, we can't all do things the way we'd like, so here I am.  

First thing, export the current scope configuration. Windows is so well built, that you can't change the subnet mask without also rebuilding the scope from scratch! We shortcut (or just hack around) that process by doing some manual edits and then rebuilding the scope from this backup.

```powershell
Export-DhcpServer -ComputerName HOSTNAME_OF_DHCP_SERVER -Leases -File C:\dhcp_export.xml -Verbose -ScopeId X.X.X.X
```

I changed two variables above, which are somewhat personal.  The first is literally just the name of the windows server; as in, check the properties of My Computer.  The second, the `X.X.X.X`, is the IP address/range/number given as part of the title of the scope you're interested in.

Now open the file you created -- you were paying attention to what you pasted in your terminal, weren't you? -- and find the section dealing with the subnet mask. Change the subnet mask to what you need. In my case, I'm restricting it from something that was way too broad.

```xml
    <Scopes>
      <Scope>
        <ScopeId>192.168.0.0</ScopeId>
        <Name>ScrappyUnderdogsINC</Name>
        <SubnetMask>255.255.0.0</SubnetMask>
        <StartRange>192.168.123.1</StartRange>
        <EndRange>192.168.123.255</EndRange>
        <LeaseDuration>1.00:00:00</LeaseDuration>
        <State>Active</State>
        <Type>Dhcp</Type>
```

I will admit that I altered the numbers here, but they're still accurate -- to someone else's network. So good luck using this to break into mine. This segment of the file was about 700 lines down in my copy. You'll definitely need to do a ctrl-f to get to it.

Now you should be ready to put it back -- but wait! There's already the original scope still in place. You can't just update the existing scope, you have to delete it. Nice architecture, that. Way to go, dudes.

Personally, I'd be more comfortable knowing it's reversible. If you want to, try all this on a dummy scope first.

**Delete the scope.** Use the GUI, delete the whole scope. That's right, you heard me. Hope your backup is good.

Then, reinstate the backup.

```powershell
Import-DhcpServer -ComputerName HOSTNAME_OF_DHCP_SERVER -File C:\dhcp_export.xml -Verbose -ScopeId X.X.X.X -Lease -BackupPath C:\BkDHCP
```

At this point, everything should work, especially if you did a dry run of the whole thing. If you messed up, at least you have your backups -- right?

## notes and rememberances

There were some serious problems that I had to deal with, and it came down to this: when you want to do a basic scope, do `192.168.1.0` as the scope.  
