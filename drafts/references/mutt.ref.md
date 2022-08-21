Mutt Cheat Sheet

General Commands

q      (x)      exit the current menu (abort without saving)
^g              cancel current action
?               list all keybindings for the current menu

The Message Index  (browsing through mailbox)

m               compose a new message
d      (D)      delete the current message (matching a pattern)
u      (U)      undelete-message (matching a pattern)
C      (ALT C)  copy the current message to another mailbox (decode first)
s      (ALT s)  save-message (decode first)
r      (g)  (L) reply to sender (all recipients) (reply to mailing list)
f      (b)      forward message (bounce)
/      (ALT /)  search  (search-reverse)
c               change to a different mailbox/folder
F      (N)      mark as important (new)
l               show messages matching a pattern
o      (O)      change the current sort method (reverse sort)
t      (ALT t)  toggle the tag on a message (entire message thread)
T      (^t)     tag messages matching a pattern (untag)
v               view-attachments
<Return>        display-message
<Tab>           jump to the next new message
@               show the author's full e-mail address
$               save changes to mailbox
^l              clear and redraw the screen
ALT k           mail a PGP public key to someone

The Pager       (reading an email)

<Return>        go down one line
<Space>  (-)    display the next page/message (previous)
^        ($)    jump to the top (bottom) of the message
/   (ALT /) (n) search for a regular expression (search backwards) (next match)
\               toggle search pattern coloring
S        (T)    skip beyond quoted text (toggle display of quoted text)

Composer        (setting the send options for an email)

y    (P)   (w)  send the message  (postpone)  (write to folder)
i               check spelling, if available 
a    (A)   (D)  attach a file  (attach message)  (detach)
d               edit description on attachment
t      (ALT f)  edit the To field (From field)
c      (b)      edit the Cc field (Bcc field)
s               edit the Subject
r               edit the Reply-To field
p               select PGP options
ALT k           attach a PGP public key
^f              wipe PGP passphrase from memory
f               specify an 'Fcc' mailbox i.e. sent folder

^g means CTRL and the g key. ALT f means ALT and the f key.
If you do not have an ALT key then use ESC then key. Do not type the brackets.
Get the latest copy from http://files.zeth.net/mutt.txt
