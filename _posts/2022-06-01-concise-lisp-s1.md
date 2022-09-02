---
layout: post
title: "Intro to Lisp: Session 1"
author: umhau
description: "getting started with femtolisp"
tags: 
- lisp
- scheme
categories: tools
---

I've been wanting to figure out lisp for a while.  So, this is my rubber ducking session to figure it out.  I'm working from the Scheme variation, rather than the (apparently) kitchen-sink common lisp variation...though they both seem pretty awesome.

# setup

We're using femtolisp, because I think it's cool.

This is my foray into learning lisp. Rather than attempting to learn some part of the greater whole of Common Lisp, I'm using a smaller variation called (femtolisp)[https://github.com/JeffBezanson/femtolisp]. This is considered a dialect of Scheme, and a "lisp-1 with lexical scope," (which means that)[https://stackoverflow.com/a/4578888] you cannot have a function and a variable that share the same name. I think it's a neat version of lisp because it's small and fast and claims to have among its focii "to keep the code concise and interesting."  Also, I think it was used in the development of the Julia language -- and a similar lisp can be accessed through the Julia interface. 

There's a number of concepts that seem based on lisp, that I haven't run into before, including "tail recursion" and "gensyms."   I'll include sections to try and cover the strange concepts.  Also this should include documentation of the available functions, and how to use them.

## Installation & a 'Hello World'

This is one of the simpler compilations I've encountered.

    git clone https://github.com/JeffBezanson/femtolisp.git
    cd femtolisp
    make

I think you need a couple compiler-related dependencies, but femto is already set up on all my available machines, so I don't have an easy way to check what those deps are. 

To run the program while in the `./femtolisp` directory, just do

    ./flisp

# the ten commandments

1. When recurring on a list of atoms, lat, ask two questions about it: (null? lat) and else. When recurring on a number, n, ask two questions about it: (zero? n) and else.  When recurring on a list of S-expressions, l, ask three question about it: (null? l), (atom? (car l)), and else.

2. Use cons to build lists.

3. When building a list, describe the first typical element, and the cons to it onto the natural recursion.

4. Always change at least one argument while recurring. When recurring on a list of atoms, lat, use (cdr lat). When recurring on a number, n, use (sub1 n). And when recurring on a list of S-expressions, l, use (car l) and (cdr l) if neither (null? l) nor (atom? (car l)) are true. It must be changed to be closer to termination. The changing argument must be tested in the terminaion condition: when using cdr, test termination with null? and when using sub1, test termination with zero?.

5. When building a value with +, always use 0 for the value of the terminating line, for adding 0 does not change the value of an addition. When building a value with ×, always use 1 for the value of the terminating line, for multiplying by 1 does not change the value of a multiplication. When building a value with cons, always consider () for the value of the terminating line.

6. Simplify only after the function is correct.

7. Recur on the subparts that are of the same nature:
-  On the sublists of a list.
- On the subexpressions of an arithmetic expression.

8. Use help functions to abstract from representations.

9. Abstract common patterns with a new function.

10. Build functions to collect more than one value at a time.

# The Five Rules

- **The Law of Car** The primitive car is defined only for non-empty lists.

- **The Law of Cdr** The primitive cdr is defined only for non-empty lists. The cdr of any non-empty list is always another list.

- **The Law of Cons** The primitive cons takes two arguments. The second argument to cons must be a list. The result is a list.

- **The Law of Null?** The primitive null? is defined only for lists.

- **The Law of Eq?** The primitive eq? takes two arguments. Each must be a non-numeric atom.
There doesn't seem to be a way to run `make install`, so you'll have to do that manually, by trial and error. I'm content to just leave the stuff where it was compiled.

You can run it interactively (is that what's known as a Read-Eval-Print Loop (REPL) ?), by running 

    ./flisp

from inside the directory.  Print to the command line with

    (print "Hello World")

though, this will append a `#t` to the string. Don't know why. Get out with

    (exit)

## The Impatient Schemer

Now we're gonna do a crash course in Lisp, because why not.  It's probably been written only a thousand times before. However: it's never been written by me, and that means I've never had the chance to learn by teaching. So here goes. 

