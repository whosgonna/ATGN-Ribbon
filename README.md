# NAME

ATGN::Ribbon - Perl module to simplify use communication with Ribbon SBCs

# SYNOPSIS

    use ATGN::Ribbon;
    
    my $rbn = ATGN::Ribbon->new (
        host     => $ribbon_hostname,
        username => $rest_username,
        password => $rest_password
    );

    my $sipsg1 = $rbn->get( 'sipsg/1' );

    my $sipsg1_description =  $sipsg1->{sipsg}->{Description}->{text}; 

# DESCRIPTION

ATGN::Ribbon can be used to simply communication with Ribbon SBCs.  The module
will transparently handle logins, normalize the invalid XML returned by the
Ribbon SBCs, and convert it to a perl hashref for easy manipulation.

# LICENSE

Copyright (C) Ben Kaufman.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ben Kaufman <ben.kaufman@altigen.com>
