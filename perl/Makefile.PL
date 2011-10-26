use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Oktest',
    ABSTRACT          => 'a new-style testing library',
    AUTHOR            => 'makoto kuwata <kwa@kuwata-lab.com>',
    VERSION           => ('$Release: 0.0.0 $' =~ /(\d[.\d]+)/ && $1),
    PREREQ_PM         => { 'Text::Diff' => 0 },
    #PMLIBDIRS         => ['lib'],
    EXE_FILES         => ['bin/oktest.pl'],
    LICENSE           => 'MIT-License',
);


## prepend 'Kookbook.pl' to be installed into 'lib/perl5'
sub MY::libscan {
    package MY;
    my ($self, $file) = @_;
    return if $file =~ /Kookbook\.pl/;
    return $self->SUPER::libscan($file);
}
