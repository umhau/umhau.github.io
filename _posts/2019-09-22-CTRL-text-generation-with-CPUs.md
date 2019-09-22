---
layout: post
title: CTRL text generation with CPUs
author: umhau
description: "sometimes overkill is just that"
tags: 
- Ubuntu 18.04
- CTRL
- DigitalOcean
- neural net
- text generation
categories: walkthroughs
---

So here's the thing.  GPUs are often only needed for training neural nets. When it comes time to actually use them, a cluster of CPUs can do just fine.  From what I've found, the main branch of the salesforce CTRL neural net can run at about one sentence per minute on 32GB of RAM and 8CPUs.  If that sounds better than digging up a cutting-edge GPU from someone online, read on.

I'm using DigialOcean because I'm a sucker for good advertising.  So far, I've crashed the model using 16GB of ram, so we're going with 32.  The model, from my observations in htop, uses 14.6 GB at rest.

Here's the workflow.

## get your computer running

- Get an account with DigitalOcean, if you haven't already.  Or, if you have a really snazzy gaming computer, use that.  
- At minimum, ask for a Standard, 32GB, 8 CPU instance.  You will have to open a ticket to verify yourself.

## install the software

Log into your new computer.  If it's your own, your probably familiar with the procedure.  If it's a DigitalOcean computer, you'll need ssh (unless you can drive really, really fast).  By default, expect the password to the droplet to be emailed to you.  You can get the IP address from clicking on the sidebar to view your droplets; the username is root.

```shell
ssh root@IP_ADDRESS
```

Once inside, it's time to do the needful.  Note that I'm not worried here about installation cleanliness or extreme security; adding new user accounts and using virtual environments is for later.

### install dependencies

```shell
sudo apt update && apt upgrade
sudo apt install python-pip 
sudo pip install Cython tensorflow==1.14

git clone https://github.com/glample/fastBPE.git && cd fastBPE
sudo python setup.py install
cd ..
```

install & patch tensorflow

```shell
git clone https://github.com/salesforce/ctrl.git && cd ./ctrl
sudo patch -b "/usr/local/lib/python2.7/dist-packages/tensorflow_estimator/python/estimator/keras.py" estimator.patch
cd ..
```

### download CTRL model from google cloud

Do recall, the model you're copying is 12.2 GB.  It'll take about 3 minutes to copy over to DigitalOcean.

```shell
mkdir seqlen256_v1 && cd seqlen256_v1
wget https://storage.googleapis.com/sf-ctrl/seqlen256_v1.ckpt/checkpoint
wget https://storage.googleapis.com/sf-ctrl/seqlen256_v1.ckpt/model.ckpt-413000.index
wget https://storage.googleapis.com/sf-ctrl/seqlen256_v1.ckpt/model.ckpt-413000.meta
wget https://storage.googleapis.com/sf-ctrl/seqlen256_v1.ckpt/model.ckpt-413000.data-00000-of-00001
```

## run the model

Now we're all ready.  There's a lower memory version of the model, but it's not tested as well. We'll use the full-size version.  

```shell
cd ctrl
python generation.py ----model_dir /root/seqlen256_v1/
```

The startup will take a while, and you'll see some warnings.  If you have htop running in another ssh session or in another tmux pane, you'll see the memory usage grow up to something like 14.6GB. Once it gets there, the startup process is almost done.  Eventually, you'll see a prompt. 

```
ENTER PROMPT: 
```

Once there, use the formats described in the original description.

```
ENTER PROMPT: Links In a shocking finding, scientist discovered a herd of unicorns living in a remote, previously unexplored valley, in the Andes Mountains.
```

The results may surprise you!

## variations

There's a full list of control codes on the CTRL github page, [here](https://github.com/salesforce/ctrl/blob/master/control_codes.txt).  Apparently, the model can even generate poetry.  

## credits

Thanks to [minimaxir](https://github.com/minimaxir/ctrl-gce); his walkthrough was very helpful in setting up the model.  Most of the thanks goes to [CTRL](https://github.com/salesforce/ctrl) though, since they actually did the work to make this model a reality.
