Quick note, this is the favored incantation to prevent too many instances of lost connections. 

```sh
sshfs -o allow_root,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3  user@remotelocation:/path/to/folder /local/mount/point
```

