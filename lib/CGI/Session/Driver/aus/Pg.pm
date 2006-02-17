#!perl

package CGI::Session::Driver::aus::Pg;

use strict;
use warnings;
use CGI::Session::Driver::aus;
use CGI::Session::Driver::postgresql;
use base qw(CGI::Session::Driver::aus);
use DBD::Pg qw(PG_BYTEA);

return 1;

sub driver { "Pg"; }

sub session_class { "CGI::Session::Driver::postgresql"; }

sub init {
    my $self = shift;
    $self->{ColumnType} = PG_BYTEA;
    return $self->SUPER::init(@_);
}
