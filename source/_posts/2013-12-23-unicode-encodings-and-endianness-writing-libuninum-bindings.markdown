---
layout: post
title: "Unicode encodings and endianness — writing libuninum bindings"
date: 2013-12-23 13:32:33 -0600
comments: true
categories:
  - Perl
  - C
  - Unicode
---

The past few days I've been learning how to write bindings for Perl using
[XS](http://perldoc.perl.org/perlxs.html) so that I can use the many great
libraries out there that I normally use in C or C++. Native bindings are very
magical things because they glue together different languages that often don't
have a direct mapping of semantics with respect to each other. XS is a bit
quirky in that, while most language binding APIs require writing calls directly
in C or C++, it is actually it's own DSL for making bindings. There is a
preprocessor called [xsubpp](http://perldoc.perl.org/xsubpp.html) that
generates the actual API calls to glue the Perl interpreter with the native
code.

I actually wanted to start learning XS a few months back. In the past,
I would put together rudimentary bindings using [SWIG](http://www.swig.org/),
but the results weren't very pleasant to use. It ends up creating bindings that
look very much like calling C code and force you to deal with pointers and context
directly. That pretty much defeats the purpose of creating a binding! So now that
I have a bit more [tuits](http://en.wiktionary.org/wiki/round_tuit), I started looking
around for documentation on using XS. Coincidentally, I found a
[project](https://github.com/Perl-XS/notes) that gathered many of the same
notes I was using. Seems that I timed my learning process just
[right](http://www.nntp.perl.org/group/perl.xs/2013/12/msg2749.html) and I've
been learning a great deal about Perl internals from the newly relaunched `#xs`
channel on [irc.perl.org](http://www.irc.perl.org/).

As I usually do when I'm learning something new, I jump right into making
something as I'm picking things up. I chose to work on something that was both
simple, but non-trivial. Years ago on Freshmeat, I came across a project called
[libuninum](http://billposer.org/Software/libuninum.html) that converts
different number system strings into integers. Once you have these integers,
you can use them in operations for arithmetic and sorting. Pretty useful if you
have to deal with data in different languages.

Before I actually hack on the bindings, I need to think about how I'm going to
distribute this code. Most people's systems aren't going to have access to the libuninum
source code to build these bindings, so I'll need to somehow get the source
code and build it on those systems. That's where [Alien::Base](https://metacpan.org/release/Alien-Base)
comes in. It's a neat module that will download a tarball, extract it, build
it, and place the dynamic library and headers in a place that can be accessed
by other modules. I made a subclass of Alien::Base called
[Alien::Uninum](https://github.com/zmughal/p5-Alien-Uninum) that will do just
that for libuninum. I even got a small [patch](https://github.com/jberger/Alien-Base/pull/31) in to
Alien::Base to fix some issues I had. All I needed now to start hacking on the XS code is a
way to tell the compiler where all the libuninum files are. With Alien::Base,
I just send those to the package build process using the `cflags`
and `libs` methods which is pretty much like using `pkg-config`
([code](https://github.com/zmughal/p5-Unicode-Number/blob/dfe5abea501a830e159f8271be188cfc129baa0e/inc/UninumMakeMaker.pm)).

I got to hacking and started on the simplest task: getting the list of all the
number systems. I first approached this by just making a list of hashes that
contained the name and ID of each number system
([code](https://github.com/zmughal/p5-Unicode-Number/blob/86b5951d0e2a4b3956e6806331ea0a7f2a3a8734/Number.xs#L26)).
Not too bad. I then added caching of that list by storing that as a private
attribute of my `Unicode::Number` class
([code](https://github.com/zmughal/p5-Unicode-Number/commit/e0625c2ecf2c7a448c174fe78ed409456b93b2da)).
Then I built on that and created a `Unicode::Number::System` class to
store the number system name and ID so that I could return instances of that
instead ([code](https://github.com/zmughal/p5-Unicode-Number/blob/71d77361ad780574a8ae235061089befe23d5e9f/Number.xs#L88)).

I then moved on to to the actual main function of the library: converting a
Unicode number to an integer. This was a bit tricky because Unicode comes in
many different encodings (e.g. UTF-8, UTF-16, UTF-32) and these encodings can
also have different endianness. Since the libuninum library expects all strings
to be in UTF-32, I converted Perl strings from UTF-8 to UTF-32 and sent them to
the XS code, but the library was giving me an "illegal character" error. To
debug this, I grabbed some of the data from an example file that came with
libuninum and put it in my XS. Still not working. This didn't make sense
because I could get it working in plain C, but not in the XS. So I put together
a small script using [Inline::C](https://metacpan.org/pod/Inline::C) that let
me call the libuninum function directly.

{% include_code 2013-12-23/inline-test.pl %}

It still wasn't working. So, as you can see above, I grabbed a function from
`uninum.c` and renamed it to `MyLaoToInt` and called it directly. Still wasn't
working. Only when I started to print out the contents of each character did I
realise what was happening. In libuninum's `unicode.h`, the `UTF32` typedef is
defined as an `unsigned long`, however `sizeof(unsigned long)` is 8 (64-bits)
on my system, not 4 (32-bits).

{% include_code 2013-12-23/libuninum-2,7_unicode_snip.h %}

That means that as the library iterates over each character, it is actually
looking at two characters instead of one and of course, none of the comparisons
were working. What it actually needed to use was a `uint32_t` from `stdint.h`.
However, even though this typedef is in the C99 standard, there are some portability
issues with using it. Instead, I used the integer type that Perl detected to be
32-bits wide and patched the code when I built it using Alien::Uninum
([code](https://github.com/zmughal/p5-Alien-Uninum/blob/6d28c2fab8e22d1164309de23a92a724982fb1d6/inc/Alien/Uninum/ModuleBuild.pm#L75)). Now the file looked like this:

{% include_code 2013-12-23/libuninum-2,7_unicode-patched_snip.h %}

Yay! Now the XS code was working on the test data. All I had to do now was get
my string to libuninum and pass the result back. I tried that and libuninum was giving me errors again.
Now what?! I decided I need to look at what the C was accessing, so I grabbed a
hex dump routine from
[here](http://c2.com/cgi/wiki?HexDumpInManyProgrammingLanguages) and looked at it:

```
00 00 fe ff ...
```

As soon as I saw the first character, I knew what was going on. What I was
looking at was the [byte-order mark](http://en.wikipedia.org/wiki/Byte_order_mark) or BOM.  Remember, I had
converted the UTF-8 string to UTF-32 in Perl before sending it to C, but I
never specified the endianness, so Perl used big-endian as the [default endianness](http://perldoc.perl.org/Encode/Unicode.html#by-endianness).
Well, since the C code was using the native endianness of the machine, I needed to
find the machine's endianness and encode either a little-endian or
big-endian version of UTF-32. All I had to was ask Perl the byte order it
detected at compile time and use that ([code](https://github.com/zmughal/p5-Unicode-Number/blob/89cfb5471235dc2d23d9a490417d9b7e558266cf/lib/Unicode/Number.pm#L122)).

Once I did that, my code was working and all my tests passed! There are still a
couple of things I need to do in my code to clean it up, but the code is mostly
done for now.
