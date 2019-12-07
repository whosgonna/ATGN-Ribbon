requires 'perl', '5.008001';
requires 'Moo';
requires 'File::Spec::Functions';
requires 'URI';
requires 'Types::Standard';
requires 'LWP::UserAgent';
requires 'HTTP::CookieJar::LWP';
requires 'XML::Hash';
#requires 'ATGN::Ribbon::Errors';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'build' => sub {
    requires 'Module::Build::Tiny';
}
