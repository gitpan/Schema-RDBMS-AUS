package Schema::RDBMS::AUS;

use 5.006;
use strict;
use warnings;

use DBI;
use DBIx::Transaction;
use DBIx::Migration::Directories::Base;

our $VERSION = '0.02';
our $SCHEMA_VERSION = '0.01';

our @optmap = (
    ['AUS_DB_DSN',  'DBI_DSN'],
    ['AUS_DB_USER', 'DBI_USER'],
    ['AUS_DB_PASS', 'DBI_PASS'],
);

sub sdbh {
    my $class = shift;
    my $dbh = $class->dbh(@_);
    
    DBIx::Migration::Directories::Base->new(dbh=>$dbh)->require_schema(
        'Schema-RDBMS-AUS'  =>  $VERSION
    );
    
    return $dbh;
}

sub db_opts {
    my($class, @db_opts) = @_;
    
    $db_opts[$_->[0]] = $ENV{$_->[1]}
        foreach(
            grep    { defined $_->[1] }
            map     { [ $_, (grep { defined $ENV{$_} } @{$optmap[$_]})[0] ] }
            grep    { !defined $db_opts[$_] }
                ($[ .. $#optmap)
        );

    $db_opts[3] = {
        RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1
    } unless defined $db_opts[3];
    
    return(@db_opts);
}

sub dbh {
    my($class, @db_opts) = @_;
   
    @db_opts = $class->db_opts(@db_opts);
    
    my $dbh = DBIx::Transaction->connect_cached(@db_opts)
        or die "Database connection @db_opts[0,1] failed: ", DBI->errstr;

    return $dbh;
}

1;

=pod

=head1 NAME

Schema::RDBMS::AUS - Authentication, Users and Sessions in an SQL schema

=head1 SYNOPSIS

  $ migrate-database-schema --dsn DBI:Pg: --verbose Schema::RDBMS::AUS

=head1 DESCRIPTION

B<Note:> I<This is an alpha release. The interface is somewhat stable and
well-tested, but other changes may come as I work in implementing this on
my website.>

The Schema::RDBMS::AUS distribution provides a complete transactional, mid-level
interface to users, groups, and sessions, including:

=over

=item * SQL schema defining users, sessions, groups, permissions, and a security log

=item * A rich L<user object|Schema::RDBMS::AUS::User> and L<user management script|aus-user>

=item * A L<CGI::Session|CGI::Session> subclass (L<CGI::Session::AUS|CGI::Session::AUS>) for session management

=back

This package only supplies an API for the management of users and sessions, it
does not integrate them with any particular user interface.

If you are developing a web application that needs authentication, users, and sessions,
see L<Apache2::AUS>. Apache2::AUS provides a mod_perl2 handler over top of
Schema::RDBMS::AUS that manages users and sessions, which can then be used by
other mod_perl2 modules, CGI scripts, or even PHP/Ruby/Python.

=head1 INSTALLING THE DATABASE SCHEMA

Currently, PostgreSQL (7.4 and above) and MySQL (5.0 and above) are supported.

To install the database schema, use the L<migrate-database-schema|migrate-database-schema>
utility, supplied by the L<DBIx::Migration::Directories|DBIx::Migration::Directories>
distribution. For example, the following line would install the schema into
the MySQL database 'joe':

  $ migrate-database-schema --dsn DBI:mysql:database=joe --verbose Schema::RDBMS::AUS

B<NOTE:> For both the PostgreSQL and MySQL schemas, it's best to install
them as the database superuser.

=head2 PostgreSQL

The entire PostgreSQL database schema can be installed by a regular database
user so long as the C<plpgsql> language is already installed in the database
you wish to use. If C<plpgsql> is I<not> installed, Schema::RDBMS::AUS will
attempt to install it for you. This requires database administrator
priviliges.

=head2 MySQL

With MySQL, you're really better off just installing the entire schema as
root. The permissions system for C<CREATE VIEW> and C<CREATE TRIGGER>
in MySQL are a bit screwed up, and if your user B<doesn't> have permissions
to install these objects, the situation is even worse:
B<MySQL auto-commits a transaction after each CREATE TABLE>, meaning that
a half-finished, failed schema installation can not be backed out properly.

I've tried all sorts of crazy GRANT statements and have not yet successfully
installed this schema as an unpriviliged user and have concluded that
MySQL is pretty much braindead.

Once the schema is installed, it can be accessed with a regular user with
no problems.

=head1 MANAGING SESSIONS

See L<CGI::Session::AUS>.

=head1 MANAGING USERS, GROUPS, AND PERMISSIONS

See L<Schema::RDBMS::AUS::User>.

=head1 ENVIRONMENT

The following environment variables are used by Schema::RDBMS::AUS:

=over

=item AUS_DB_DSN

=item AUS_DB_USER

=item AUS_DB_PASS

The L<DBI|DBI> Data Source Name, Username, and Password to connect to the
database with. If any of these environment variables are not specified, the
DBI standard C<DBI_DSN>, C<DBI_USER>, and C<DBI_PASS> variables are checked
as well.

=item AUS_SESSION_ID

If this environment variable is specified, it is used as the default session
id for L<CGI::Session::AUS|CGI::Session::AUS>.

=back

=head1 METHODS

Most of the methods you would be interested in are probably in
L<Schema::RDBMS::AUS::User|Schema::RDBMS::AUS::User> or
L<CGI::Session::AUS|CGI::Session::AUS>. However, C<Schema::RDBMS::AUS>
itself provides a few class methods:

=over

=item dbh

Returns a C<DBIx::Transaction> database handle connected to the authentication,
users, and sessions database. It acceps the same arguments as connect() in
the L<DBI|DBI> distribution. If any parameters are not specified, their
default values are taken from the environment as described above.

=item sdbh

Obtains a database handle from dbh(), then asks
L<DBIx::Migration::Directories|DBIx::Migration::Directores> if our SQL
schema is installed there. If it is, the database handle is returned.
If not, sbdh will die() with a useful error message.

=back

=head1 THANKS

=over

=item Mischa Sandberg <mischa.sandberg@telus.net>

Mischa has taught me quite a bit about Postgres in general, and wrote
the triggers and views that are used to support heiarchial user/group
membership.

=back

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=cut
