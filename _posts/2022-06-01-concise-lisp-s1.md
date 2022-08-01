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