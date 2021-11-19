---
layout: post
title: An Odyssey with Outlook
author: umhau
description: "Frustration breeds annoyance breeds contempt"
tags: 
- Powershell
- C#
- Outlook
- GUI_vs_CLI
- Life_Lessons
categories: walkthroughs
---

Have I ever mentioned how deeply I detest the programming interfaces created for the Windows OS?

One of the employees at work changed their name, and I was asked to make sure that the change would be reflected in the emails they sent to the other employees. No biggie, right? Just pop over into the email server, change the name, bip-bop-boop, and we're done?

Wrong.

We use GSuite and Outlook. No exchange server, sadly. Don't ask me why we went this route - it was before my time, and on behalf of the poor, deluded soul that picked GSuite, I deeply regret their decision and fear to imagine the rest of their life choices. At least, if it was running 365 or Exchange, it would all be compatibly broken. 

But I digress. We use gsuite and outlook, and so I went to the [admin panel](https://admin.google.com/ac/users), found the name-changing user, did the needful, and waited the recommended 10 minutes for the change to take effect. 

Nothing happened. 

Because, guess what, outlook doesn't recheck display names every time an email comes in - it just checks whatever that user was called last time they showed up in the mail queue. And since we don't use 365 or, god help us, Microsoft Exchange, there's no central outlook-savvy database to update with the name change. 

What to do? 

Update each user individually, of course. That's what login scripts are for! Now the question becomes, 'how do we programmatically change the display name for an email account in our local outlook program?'  The answer is another question: 'is this display name recorded in the contacts list, or the outlook cache?'

Guess what: there's no central contacts list, and nobody uses a local contacts list - it's all just whatever is in the outlook cache. So how do we modify email account display names in the outlook cache?

```PowerShell
Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Office\Office15\Outlook.exe' -ArgumentList '/cleanautocompletecache','/recycle'
```

Not like that!

```PowerShell
Outlook.exe /CleanAutoCompleteCache
```

Not like that, either.

```PowerShell
Start-Process -FilePath 'C:\Program Files\Microsoft Office\Office16\OUTLOOK.EXE' -ArgumentList '/cleanautocompletecache','/recycle'
```

Nope.

...3 hours later. 

```PowerShell
Start-Process -FilePath 'C:\Program Files\Microsoft Office\Office16\OUTLOOK.EXE' -ArgumentList '/cleanautocompletecache'
```

Behold! The magic incantation. If this is run, all the remembered display names and email addresses will disappear like smoke, and any new emails that come in will have their display names refreshed.

Turns out, it isn't, and they won't. Plain and simple, that's not how it works, you don't get to do that, and it's just. not. possible. Sorry windows admin, no one wanted to create an option for that to be done, so there's no option to do it, so it can't get done. Find another way, or give up.

We're not giving up, so we're finding another way.  Someone mention the local contacts list? Let's make a login script that adds just one user to everybody's contacts list. That _should_ override the cache, and show the proper display name when the emails come through. 

Figure out how to write the program. Looks like it's not a powershell thing this time; C# seems to be the way to go. Even found the [prototype](https://www.add-in-express.com/creating-addins-blog/2011/10/07/outlook-create-contact-item/) of a program to work with.

```C#
private void CreateContactUsingCreateItem()
{
    Outlook.ContactItem contact = OutlookApp.CreateItem(Outlook.OlItemType.olContactItem)
           as Outlook.ContactItem;
    if (contact != null)
    {
        contact.Save();
        contact.Display(true);
        Marshal.ReleaseComObject(contact);
    }
}
```

How does this compile?

Word of advice: don't - ever - use [this](https://www.microsoft.com/en-us/p/csharp/9n4w6bhc0hml) abomination of a compiler. If you ever need to compile C# on Windows 10, then if you have `.NET` available (probably do), there's a compiler already installed at `C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe` (or somewhere similar: probably a different version number). Then it's just

```PowerShell
csc.exe somefile.cs
```

Wrong!

In my-paths-are-screwed-up world, you'll actually have to do

```PowerShell
& 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe' somefile.cs
```

...and then it'll work.

Except it won't. 

Why?

Because before we went to all the trouble of figuring out how to write this program, we decided to do a quick sanity-check and add the contact to the address list manually. When we did that, we discovered something: it doesn't change a single blessed thing. The original display name is still the display name.  

_The original display name is still the display name._

Even though we cleared the cache. Even though we set an alternate name in the address book. Even though - 

Maybe the display name is being sent with the email from the sender. Maybe, the sender's information overrides the local settings. Maybe, the sender's outlook config needs to be changed. Maybe, we were so myopic that we forgot there's a whole other side to this - the sender's side. Maybe we've been at work too long.

```
File -> Account Settings
Double click the email account
Change 'Your Name' to the new display name
Next -> Finish
```
