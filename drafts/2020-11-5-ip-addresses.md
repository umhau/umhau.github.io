---
layout: post
title: IP addresses
author: umhau
description: "how they work"
tags: 
- ip address
- ipv4
- ipv6
categories: memos
---






IP range specifications are weird; they're actually binary, and we use something called 'dot decimal notation' and convert them to decimal to make them a bit easier to read. 

For example: the IP address 127.0.0.1 is actually a binary number with 32 numerals - or bits:
```
01111111000000000000000000000001
```
The largest possible value of that 32 bit number, in both decimal and binary:
```
4,294,967,296
11111111111111111111111111111111
```
In order to express a range of possible values, the most concise method is to write down the number of bits to ignore at the end. For example, using decimal numbers:
```
4,294,967,296 IGNORE:3
```
That means, any number between
```
4,294,967,000 - 4,294,967,999
```
In binary, the effect would be slightly different since a single binary numeral can represent fewer possible numbers.

```
11111111111111111111111111111111 IGNORE:5
```
would become the range:
```
11111111111111111111111111100000 - 11111111111111111111111111111111
```
Now, if we split the 


 That's what the /24 means - in binary, the IP address above would actually be 
```
