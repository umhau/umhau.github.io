---
layout: post
title: set up ssh to use keys instead of passwords
author: umhau
description: "look ma, no passwords!"
tags: 
- ssh
- linux
- encryption
- public keys
- private keys
categories: walkthroughs
---

Using ssh without a password involves encryption keys -- a public key and a private key -- to authenticate you. Those keys are stored, usually, in `~/.ssh/`. Though they can go anywhere else, too - just have to tell ssh where to find them.

```
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

The contents of those keys are really simple, too.  One of them is the text representation of large number, whose size is measured in bits -- the number of digits in the number, if it was converted to binary.  That is the _private key_.

For instance: I can create a new key really easily, with an empty password:

```
ssh-keygen -N '' -f demokey
```

That creates two files, `./demokey` and `./demokey.pub`.  You want to share the public key, and keep the private one...private.  The private key looks like this: 

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1VrNVTArYOS8qUHFSGXKuIwYIIRIWDJuGH/VkjaA0T1PRe8e
O20F3uPNPkHwVThu4G4TFr+cXfXwd26ikOM1NJ4cpeMJccTK7DV+uqOCh1ZGK5ia
n8mBscCAKgInx/drMDVhSiRDygwpDXfZPFc4ZpBN2UOtKe5KT9YxEg9brmqkS7Im
WgJABvK2QTBawT4qgJBkL6OiBpi1vTc6TYd+ZcujPcN0qz8nupz1LANq5o37n3P5
DgW5fZoKwJwkPfc3SvAUpYW7WL2tRuk9SnvlraMFQEm+UEMyi1fYyqpHNMZ2MvCO
GS2bYkrHaoQA0Hdw99zF3GRfBVe5q1NB79QTWQIDAQABAoIBAQClE2t5tRprDq/W
OZg+CtxN678jMZaT/vjmJcqGJXuH6Wrzji6TBiibqx/7QqOEHHTVWvWUDU8b+BVF
IynO9q0M+CTsSPzetMfY+Q8Ds01kD2Gdi6ZfaVbaxDmlxyMmeg3KMBMFfYehxcTh
sdA3+rgdyxsgtlc98Sw4F17CPXXPPTNVVoSIZKDx5PyPR6nv1BhnYHOAykaeF6VT
WQWhA+cmY9lQu2rpldauV02XWIpl4X5PjoTFiczRCZMcH7/Z0w71CDjKkE5StNh8
sk2kT5cC1JS8XjpIOUSUwBJf2YDgRC7gkR2aiCIjFTPPvnommtsSgjhDq6tZMHon
Lh9hcKYtAoGBAPlnNu8DWwed118k1q2lpbIXjnBDw3foUvX8PqFRFV8ttgCK7iCb
X0cT1kXEJNmlgCIphu1gDFrWSI/tMYTub7IfkztP3nGGp5uLRVIAizqAfv9qNpMz
dkj7XBN5Kt5V0SyeFfHvP1lUvFUgZXyf5C08AEs4jZRPwzrRDxzxrhpLAoGBANr/
ff0OyQ87QCcIDcJVsJdpTRoeM4pRVTIYRRq5pRjSLaNcr2UXSYIhZFA0sOJAfodK
B3VTmd5O/vG/WAslaMUrkZucgAqAOiaWB3ndFKx6DFy1PSeJKoeeh8DGZiCpatVj
jzAcMJAosOYR02IpZBtsgr8E2n9W2pQhElO2/4JrAoGAEubus+i2MnqVAyIAn0KJ
r1i3s+x+2QyjlP8cJA/IJeGKBLqC17fO3c00FS+Ld29iqbQqBL2d0hihgT8B3MhR
cNeRyhIAkuwYseI5S8C8zJ9GgMclAb0JvvhF/zfUtuscIlyM3zw5ueSBLZZ5+psH
qSH+B7VujYoKCuAjXBc5EccCgYEArIlYCHSKoW5r55RnyrDaNSAoN6iNsK7NcW8/
moOieAC3JhqSsRF8v4JxVuN8bHSlew8u+xfHhSc1ot6+jeGGPrlJuZC+LAfESLww
3aj5bb2mWbAMo0Zk9H5Is+9bbOYtHjuXBy9eb2UvocNvh8nWbei6xaYcQvD5unSn
zL7DZUsCgYBHdqk+WXl4lOHX8NGGEbHj7M8H95ll2oynM+mpbuIRd+7Tuu/o10TR
4oKaVrWuddW6PGeWtzpbzHnkHnXiBra9m0fgfUL1WkJdiqlgtEyy6TFTWiXgYX78
1LI4rpiC+fNl3BKIR69l33J6B4w2vqo6IrRSd89CZXnxEWB2a8chjA==
-----END RSA PRIVATE KEY-----
```

The public key is a lot shorter. In other scenarios, this one is used to encrypt things, while the private key is the only one that can decrypt them. The public key: 

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVWs1VMCtg5LypQcVIZcq4jBgghEhYMm4Yf9WSNoDRPU9F7x47bQXe480+QfBVOG7gbhMWv5xd9fB3bqKQ4zU0nhyl4wlxxMrsNX66o4KHVkYrmJqfyYGxwIAqAifH92swNWFKJEPKDCkNd9k8VzhmkE3ZQ60p7kpP1jESD1uuaqRLsiZaAkAG8rZBMFrBPiqAkGQvo6IGmLW9NzpNh35ly6M9w3SrPye6nPUsA2rmjfufc/kOBbl9mgrAnCQ99zdK8BSlhbtYva1G6T1Ke+WtowVASb5QQzKLV9jKqkc0xnYy8I4ZLZtiSsdqhADQd3D33MXcZF8FV7mrU0Hv1BNZ <username here>@<hostname here>
```

Obviously, these are both generated just for this little explanation, and are of no value whatsoever otherwise.

There's also another couple files that go in that `~/.ssh` folder: `authorized_keys` and `known_keys`. We're interested in the first one. 

## copy & paste

