package ATGN::Ribbon;
use Moo;
use URI;
use Types::Standard (':all');
use LWP::UserAgent;
use HTTP::CookieJar::LWP;
use XML::Hash;
use ATGN::Ribbon::Errors;

our $VERSION = "0.01";

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has scheme => (
    is       => 'ro',
    required => 1,
    isa      => Enum['http', 'https'],
    default  => 'https'
);

has port => (
    is       => 'ro',
    isa      => Int,
    required => 1,
    default  => 443
);

##TODO: Use a builder for the calls to normalize the trailing slash on
## the 
has base_path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => 'rest/',
);

has _uri => (
    is  => 'lazy',
    isa => InstanceOf[ 'URI' ],
);

sub _build__uri  {
    my $self = shift;
    my $uri  = URI->new();
    $uri->scheme( $self->scheme );
    $uri->host( $self->host );
    $uri->path( $self->base_path );

    return $uri;
}

has _ua => (
    is => 'lazy',
);

sub _build__ua {
    my $self      = shift;
    my $cookiejar = HTTP::CookieJar::LWP->new();
    my $ua  = LWP::UserAgent->new(
        cookie_jar        => $cookiejar,
        protocols_allowed => ['http', 'https'], 
        timeout           => 10,  
        ssl_opts          => { verify_hostname => 0 },
    );
    return $ua;
}


# _failed_login_count is used to prevent loops for automatic logins.  It is set to 
# 0 on successful login, and 1 on login failure, which can be used to allow for
# a single re-login attempt (because maybe the login timed out, etc).
has _failed_login_count => (
    is      => 'rwp',
    isa     => Int,
    default => 0
);





sub login {
    my $self = shift;
    
    if ( $self->_failed_login_count ) {
        
    };

    my $params = { 
        Username => $self->{username},
        Password => $self->{password},
    };

    my $uri = URI->new_abs( 'login', $self->_uri );
    my $ua   = $self->_ua;
    my $response = $ua->post( $uri, $params );
    $response = $self->_xml2hashref( $response->decoded_content );
    
    if ( $response->{status}->{http_code}->{text} == 200 ) {
        $self->_set__failed_login_count( 0 );
    }
    else {
        $self->_set__failed_login_count( 1 );
        $self->_check_ribbon_rc( $response );
    }


    return $response;

}


sub get {
    my $self     = shift;
    $self->request( 'get', @_ );
}


sub post {
    my $self     = shift;
    $self->request( 'post', @_ );
}


sub request {
    my $self     = shift;
    my $method   = shift;
    my $rel_path = shift;
    my $params   = shift;

    
    my $ua  = $self->_ua;
    my $uri = URI->new_abs( $rel_path, $self->_uri );

    
    my @args          = ( $uri );
    if ( $params ) {
        push @args, $params;
    }
    my $response = $ua->$method( @args );
    my $data     = $self->_xml2hashref( $response->decoded_content );
    my $app_code = $data->{status}->{app_status}->{app_status_entry}->{code};

    ## Not logged in. Try to login one time.
    if ( $app_code && $app_code == 20032  && !$self->_failed_login_count ) {
        ## set failed login count to 1, so that we don't repeat this loop.
        $self->_set__failed_login_count( 1 );
        $self->login;
        $data = $self->request( $method, $rel_path, $params );
    }

    return $data;

}



sub _xml2hashref {
    my $self = shift;
    my $xml  = shift;

    # Ribbon puts leading whitespace in their xml responses, which is
    # invalid, so we have to clear it before processing the message.
    $xml =~ s/^\s*\n//g;

    my $ribbon_data = XML::Hash->new->fromXMLStringtoHash($xml);
    $ribbon_data = $ribbon_data->{root};
    $self->_check_ribbon_rc( $ribbon_data );
    return $ribbon_data;
}


## Checks the ribbon specific response code (not the same as the http rc).
sub _check_ribbon_rc {
    my $self      = shift;
    my $rbn_data  = shift;
    my $status    = $rbn_data->{status};
    my $http_code = $status->{http_code}->{text};
    
    ## Note that this is not the actual http response code.  But a 200 is still
    ## an 'OK' value.
    return if ( $http_code == 200 );


    my $app_code = $status->{app_status}->{app_status_entry}->{code};
    if ( $app_code == 20032 ) {
        return;
    }
    my @params   = ($status->{app_status}->{app_status_entry}->{params} );
    
    my $error_text = ribbon_error( $app_code, @params );
    warn("Error $app_code: $error_text");

}


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    if ( $args{base_path} && $args{base_path} !~ m{/$} ) {
        $args{base_path} .= '/';
    }
    
    return $class->$orig( %args );
};







1;

__END__

=encoding utf-8

=head1 NAME

ATGN::Ribbon - Perl module to simplify use communication with Ribbon SBCs

=head1 SYNOPSIS

    use ATGN::Ribbon;
    
    my $rbn = ATGN::Ribbon->new (
        host     => $ribbon_hostname,
        username => $rest_username,
        password => $rest_password
    );

    my $sipsg1 = $rbn->get( 'sipsg/1' );

    my $sipsg1_description =  $sipsg1->{sipsg}->{Description}->{text}; 

=head1 DESCRIPTION

ATGN::Ribbon can be used to simply communication with Ribbon SBCs.  The module
will transparently handle logins, normalize the invalid XML returned by the
Ribbon SBCs, and convert it to a perl hashref for easy manipulation.

=head1 LICENSE

Copyright (C) Ben Kaufman.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ben Kaufman E<lt>ben.kaufman@altigen.comE<gt>

=cut

