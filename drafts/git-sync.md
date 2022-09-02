I'm synchronizing git repositories with syncthing. Yes, I know it's a bit cowboy-ish. But the most annoying thing is when windows messes with the permissions, and then git thinks all the files changed. 

This is a per-repository fix:

```shell
git config core.filemode false   
```

Or you can run this to change it on everything:
```shell
git config --global core.filemode false
```

