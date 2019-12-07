use strict;
use warnings;
use v5.12;
use Test::More;
use ATGN::Ribbon;

my $host = '127.0.0.1';
my %args = (
    host     => $host,
    username => 'username',
    password => 'password',
    #    path     => 'restapi',
);

my $rbn = ATGN::Ribbon->new( %args );



is( $rbn->scheme, 'https', "Scheme defaults to 'https'" );
is( $rbn->host, $host, "Host is set to the value from \$host" );
is( $rbn->port, 443, "Port defaults to 443");
isa_ok( $rbn->_uri, 'URI', "->_uri" );



done_testing();
