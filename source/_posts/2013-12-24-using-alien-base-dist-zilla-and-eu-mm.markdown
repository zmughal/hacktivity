---
layout: post
title: "Using Alien::Base, Dist::Zilla, and EU::MM"
date: 2013-12-24 15:28:11 -0600
comments: true
categories: Perl
---

Since I use [Dist::Zilla](http://p3rl.org/Dist::Zilla) to help manage my
Perl distributions, I wanted to use it with the XS package that I am working
on. This post is just a small note how how to do that if you are using
[Alien::Base](http://p3rl.org/Alien::Base) to build your native library.

Dist::Zilla usually writes it's own `Makefile.PL` so that
[ExtUtils::MakeMaker](ExtUtils::MakeMaker) will know how to build, test, and
install the code. However, since I'm using Alien::Base, I need to pass the
compiler and linker flags to ExtUtils::MakeMaker as well. To do that, I grabbed
the [Dist::Zilla::Plugin::MakeMaker::Awesome](http://p3rl.org/Dist::Zilla::Plugin::MakeMaker::Awesome)
plugin. Setting that up in your `dist.ini` is relatively straightforward:

{% include_code 2013-12-24/dist.ini %}

The line
```
[=inc::MyLibMakeMaker]
```
specifies that the code that will be used to generate the `Makefile.PL` will be
in a module called `inc/MyLibMakeMaker.pm`. Now in that file, I'll need
compilation flags by calling the `cflags` and `libs` methods on my Alien::Base
subclass (Alien::MyLib). But this needs to happen when `Makefile.PL` is run by
the user, not when Dist::Zilla writes out the file. The following code does that
by appending our own options to the string we write out to in `Makefile.PL`.

{% include_code lang:perl 2013-12-24/MyLibMakeMaker.pm %}

We use the `CONFIGURE` option to set `CCFLAGS` and `LIBS` instead of setting
`CCFLAGS` and `LIBS` directly because these need to be set after the
`Alien::MyLib` prerequisite has been met.
