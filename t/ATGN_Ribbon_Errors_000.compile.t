use Test::More;



use_ok( 'ATGN::Ribbon::Errors' );

my $error_number = 1001;
my @params       = ('node 1');
my $error_text   = "The license key applies to a different node $params[0]";
is( ribbon_error( 1001, @params ), $error_text, "Error $error_number is good. $error_text" );


done_testing();
