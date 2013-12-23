#!/usr/bin/env perl

use Inline C;
use Inline C => Config =>
	#CCFLAGS => "",
	INC => "-I/home/zaki/perl5/perlbrew/perls/perl-5.18.1/lib/site_perl/5.18.1/auto/share/dist/Alien-Uninum/include/uninum",
	LIBS => "-L/usr/local/lib -fstack-protector -L/home/zaki/perl5/perlbrew/perls/perl-5.18.1/lib/site_perl/5.18.1/auto/share/dist/Alien-Uninum/lib -luninum";
# CFLAGS = -I/home/zaki/perl5/perlbrew/perls/perl-5.18.1/lib/site_perl/5.18.1/auto/share/dist/Alien-Uninum/include/uninum -O2
# LDFLAGS = -O2 -L/usr/local/lib -fstack-protector -L/home/zaki/perl5/perlbrew/perls/perl-5.18.1/lib/site_perl/5.18.1/auto/share/dist/Alien-Uninum/lib -luninum
use v5.14;
use strict;
use warnings;

say gg();

__END__
__C__
#include <gmp.h>
#include <unicode.h>
#include <nsdefs.h>
#include <uninum.h>


static void MyLaoToInt(mpz_t mpzResult, UTF32 *s) {
  unsigned long CurrentValue; 
  UTF32 c;
  mpz_t Result;

  uninum_err = NS_ERROR_OKAY;
  mpz_init(Result);
  CurrentValue = 0;

  while ( (c = *s++) != 0x0000) {
    fprintf(stderr, "%lx - %d ===== %d \n", c, CurrentValue, c == (unsigned long)0x0ED5UL);
    switch (c) {
    case 0x0ED0:
      CurrentValue = 0;
      break;
    case 0x0ED1:
      CurrentValue = 1;
      break;
     case 0x0ED2:
      CurrentValue = 2;
      break;
    case 0x0ED3:
      CurrentValue = 3;
      break;
    case 0x0ED4:
      CurrentValue = 4;
      break;
    case 0x0ED5:
      CurrentValue = 5;
      break;
    case 0x0ED6:
      CurrentValue = 6;
      break;
    case 0x0ED7:
      CurrentValue = 7;
         break;
    case 0x0ED8:
      CurrentValue = 8;
      break;
    case 0x0ED9:
      CurrentValue = 9;
      break;
    default:			/* Error */
      uninum_err = NS_ERROR_BADCHARACTER;
      uninum_badchar = c;
      mpz_clear(Result);
      return;
    }
    mpz_mul_ui(Result, Result, 10L);
    fprintf(stderr,"%d", CurrentValue);
    mpz_add_ui(Result, Result, CurrentValue);
  }
  mpz_init_set(mpzResult, Result);
  mpz_clear(Result);
}


unsigned long gg() {
	uninum_err = 20;
	wchar_t str[] =L"\x0ED5\x0ED7\x0ED6"; /* Lao digits 5 7 6 */
        /*wchar_t str[] =L"\x0000\x0ED5\x0ED7\x0000\x0ED6"; /* Lao digits 5 7 6 */
	/*fprintf(stderr, "%lx - %d with size %d %d\n",  ( (UTF32*)str )[0] ,  ( (UTF32*)str )[0] == 0x0ED5, sizeof(str[0]), sizeof(0x0ED5));*/
	int ns = GuessNumberSystem(str);
	mpz_t Result;
	union ns_rval val;
	StringToInt(&val, (UTF32*)str, NS_TYPE_ULONG, ns);
	/*MyLaoToInt(Result, (UTF32*)str);*/
	fprintf(stderr, "error: %d\n", uninum_err);
	return val.u;
}
