
> When trying to salvage as much as possible from a failing device, don't use dd, use ddrescue instead. It can handle failed read attempts, supports retrying and restarting while saving data etc.

> This. I saved an employee's MacBook with ddrescue. The drive would only work for 5 minutes at a time before dying. I set up ddrescue in the cold server room and hooked the drive up to a managed powerstrip. Everytime the drive died I cycled the power via a telnet command and ddrescue continued on its merry way. It took literally 2 weeks to recover a full image


https://www.gnu.org/software/ddrescue/


Hands down the best data recovery tool I've ever used. Between ddrescue and a mini-freezer with a sata cables snaked into it, we could save data from drives that we had no right recovering. It was like black magic.

https://wiki.archlinux.org/title/file_recovery#Failing_drives






