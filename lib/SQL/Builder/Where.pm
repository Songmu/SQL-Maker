package SQL::Builder::Where;
use strict;
use warnings;
use utf8;
use SQL::Builder::Part;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {bind => [], %args}, $class;
}

sub add {
    my ( $self, $col, $val ) = @_;

    my ( $term, $bind ) = SQL::Builder::Part->make_term( $col, $val );
    push @{ $self->{where} }, $term;
    push @{ $self->{bind} },  @$bind;

    return $self; # for influent interface
}

sub as_sql {
    my ($self, $need_prefix) = @_;
    my $sql = join(' AND ', map { "($_)" } @{$self->{where}});
    $sql = " WHERE $sql" if $need_prefix && length($sql)>0;
    return $sql;
}

sub bind {
    my $self = shift;
    return @{$self->{bind}};
}

1;
