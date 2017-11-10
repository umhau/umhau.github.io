---
layout: post
title: Installing Mimic (by Mycroft A.I.)
author: umhau
description: "Walkthrough for installing the Mimic text to speech engine."
tags:
- Mycroft A.I.
- Ubuntu GNOME 17.04
- Linux
- Mimic
categories: walkthroughs
---

This is a step-by-step walkthrough for installing the mimic TTS engine developed by Mycroft A.I. for their AI system. 

## Dependencies

    sudo apt-get install gcc make pkg-config automake libtool libasound2-dev

## Installation 

Let's keep the software in ~/projects.  Keeps it simple and accessible. Watch out: this is a 700 MB repository.

    mkdir -p ~/projects && cd ~/projects
    git clone https://github.com/MycroftAI/mimic.git
    cd ./mimic

Build stuff.  The make command takes a while; if you're on a multi-core machine, try parallel compilation.  

    ./dependencies.sh --prefix="/usr/local"
    ./autogen.sh
    ./configure --prefix="/usr/local"

Do this to play it safe.

    make 
    make check

Do this if you're a steely-eyed missile man.

    CORES=$(nproc --all 2>&1)
    make -j $CORES
    make check

One of the checks failed for me - looks like the pcre2 doesn't actuall install correctly.  However, it still worked fine for audio generation, and I have no complaints. 

## Use

Pretty simple, actually.  Make sure you're still in the directory of the repository that you downloaded ("cloned").  Then, 

    ./mimic -t "I am a computer."

The system has a fantastic British accent.  Also, it looks like all you actually need is the ./mimic file itself - which you can put anywhere in your system that you like.  
