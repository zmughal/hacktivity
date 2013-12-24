package inc::MyLibMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::MyLib;
	my $alien_mylib = Alien::MyLib->new;
	+{ CCFLAGS => $alien_mylib->cflags, LIBS => $alien_mylib->libs };
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
