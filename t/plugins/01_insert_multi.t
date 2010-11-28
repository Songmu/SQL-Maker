use strict;
use warnings;
use Test::More;
use SQL::Builder;
use Test::Requires 'Tie::IxHash';

sub ordered_hashref {
    tie my %params, Tie::IxHash::, @_;
    return \%params;
}

SQL::Builder->load_plugin('InsertMulti');

my $builder = SQL::Builder->new(driver => 'mysql');
my ( $sql, @binds ) = $builder->insert_multi(
    'foo' => [
        ordered_hashref( bar => 'baz', john => 'man' ),
        ordered_hashref( bar => 'bee', john => 'row' )
    ]
);
is $sql, "INSERT INTO foo\n(bar, john)\nVALUES (?, ?)\n,(?, ?)\n";
is join(',', @binds), 'baz,man,bee,row';

done_testing;

