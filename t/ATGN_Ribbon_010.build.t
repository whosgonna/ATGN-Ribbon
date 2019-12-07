use Test::More;
use ATGN::Ribbon;

my %args = (
    host     => '127.0.0.1',
    username => 'username',
    password => 'password',
);

new_ok( 'ATGN::Ribbon', [ %args ], 'Ribbon Object' );


done_testing();
