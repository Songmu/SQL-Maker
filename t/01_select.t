use strict;
use warnings;
use Test::More;
use SQL::Maker;
use Test::Requires 'Tie::IxHash';

sub ordered_hashref {
    tie my %params, Tie::IxHash::, @_;
    return \%params;
}

subtest 'driver: sqlite' => sub {
    my $builder = SQL::Maker->new(driver => 'sqlite');

    subtest 'columns and tables' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ '*' ] );
        is $sql, qq{SELECT *\nFROM "foo"};
        is join(',', @binds), '';
    };

    subtest 'columns and tables, where cause (hash ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], ordered_hashref( bar => 'baz', john => 'man' ) );
        is $sql, qq{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (array ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], [ bar => 'baz', john => 'man' ] );
        is $sql, qq{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (hash ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], ordered_hashref(bar => 'baz', john => 'man'), {order_by => 'yo'});
        is $sql, qq{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo'});
        is $sql, qq{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by, limit, offset' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo', limit => 1, offset => 3});
        is $sql, qq{SELECT "foo", "bar"\nFROM "foo"\nWHERE ("bar" = ?) AND ("john" = ?)\nORDER BY yo\nLIMIT 1 OFFSET 3};
        is join(',', @binds), 'baz,man';
    };

    subtest 'modify prefix' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [], { prefix => 'SELECT SQL_CALC_FOUND_ROWS '} );
        is $sql, qq{SELECT SQL_CALC_FOUND_ROWS "foo", "bar"\nFROM "foo"};
        is join(',', @binds), '';
    };

    subtest 'order_by' => sub {
        subtest 'scalar' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => 'yo'});
            is $sql, qq{SELECT *\nFROM "foo"\nORDER BY yo};
            is join(',', @binds), '';
        };

        subtest 'hash ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => {'yo' => 'DESC'}});
            is $sql, qq{SELECT *\nFROM "foo"\nORDER BY "yo" DESC};
            is join(',', @binds), '';
        };

        subtest 'array ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => ['yo', 'ya']});
            is $sql, qq{SELECT *\nFROM "foo"\nORDER BY yo, ya};
            is join(',', @binds), '';
        };

        subtest 'mixed' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => [{'yo' => 'DESC'}, 'ya']});
            is $sql, qq{SELECT *\nFROM "foo"\nORDER BY "yo" DESC, ya};
            is join(',', @binds), '';
        };
    };

    subtest 'from' => sub {
        subtest 'multi from' => sub {
            my ($sql, @binds) = $builder->select( [ qw/foo bar/ ], ['*'], +{}, );
            is $sql, qq{SELECT *\nFROM "foo", "bar"};
            is join(',', @binds), '';
        };

        subtest 'multi from with alias' => sub {
            my ($sql, @binds) = $builder->select( [ [ foo => 'f' ], [ bar => 'b' ] ], ['*'], +{}, );
            is $sql, qq{SELECT *\nFROM "foo" "f", "bar" "b"};
            is join(',', @binds), '';
        };
    };

    subtest 'join' => sub {
        my ($sql, @binds) = $builder->select(undef, ['*'], +{}, {joins => [
            [foo => {
                type      => 'LEFT OUTER',
                table     => 'bar',
                condition => 'foo.bar_id = bar.id',
            }]
        ]});
        is $sql, qq{SELECT *\nFROM "foo" LEFT OUTER JOIN "bar" ON foo.bar_id = bar.id};
        is join(',', @binds), '';
    };
};

subtest 'driver: mysql' => sub {
    my $builder = SQL::Maker->new(driver => 'mysql');

    subtest 'columns and tables' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ '*' ] );
        is $sql, qq{SELECT *\nFROM `foo`};
        is join(',', @binds), '';
    };

    subtest 'columns and tables, where cause (hash ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], ordered_hashref( bar => 'baz', john => 'man' ) );
        is $sql, qq{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (array ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], [ bar => 'baz', john => 'man' ] );
        is $sql, qq{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (hash ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], ordered_hashref(bar => 'baz', john => 'man'), {order_by => 'yo'});
        is $sql, qq{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo'});
        is $sql, qq{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by, limit, offset' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo', limit => 1, offset => 3});
        is $sql, qq{SELECT `foo`, `bar`\nFROM `foo`\nWHERE (`bar` = ?) AND (`john` = ?)\nORDER BY yo\nLIMIT 1 OFFSET 3};
        is join(',', @binds), 'baz,man';
    };

    subtest 'modify prefix' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [], { prefix => 'SELECT SQL_CALC_FOUND_ROWS '} );
        is $sql, qq{SELECT SQL_CALC_FOUND_ROWS `foo`, `bar`\nFROM `foo`};
        is join(',', @binds), '';
    };

    subtest 'order_by' => sub {
        subtest 'scalar' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => 'yo'});
            is $sql, qq{SELECT *\nFROM `foo`\nORDER BY yo};
            is join(',', @binds), '';
        };

        subtest 'hash ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => {'yo' => 'DESC'}});
            is $sql, qq{SELECT *\nFROM `foo`\nORDER BY `yo` DESC};
            is join(',', @binds), '';
        };

        subtest 'array ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => ['yo', 'ya']});
            is $sql, qq{SELECT *\nFROM `foo`\nORDER BY yo, ya};
            is join(',', @binds), '';
        };

        subtest 'mixed' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => [{'yo' => 'DESC'}, 'ya']});
            is $sql, qq{SELECT *\nFROM `foo`\nORDER BY `yo` DESC, ya};
            is join(',', @binds), '';
        };
    };

    subtest 'from' => sub {
        subtest 'multi from' => sub {
            my ($sql, @binds) = $builder->select( [ qw/foo bar/ ], ['*'], +{}, );
            is $sql, qq{SELECT *\nFROM `foo`, `bar`};
            is join(',', @binds), '';
        };

        subtest 'multi from with alias' => sub {
            my ($sql, @binds) = $builder->select( [ [ foo => 'f' ], [ bar => 'b' ] ], ['*'], +{}, );
            is $sql, qq{SELECT *\nFROM `foo` `f`, `bar` `b`};
            is join(',', @binds), '';
        };
    };

    subtest 'join' => sub {
        my ($sql, @binds) = $builder->select(undef, ['*'], +{}, {joins => [
            [foo => {
                type      => 'LEFT OUTER',
                table     => 'bar',
                condition => 'foo.bar_id = bar.id',
            }]
        ]});
        is $sql, qq{SELECT *\nFROM `foo` LEFT OUTER JOIN `bar` ON foo.bar_id = bar.id};
        is join(',', @binds), '';
    };
};

subtest 'driver: mysql, quote_char: "", new_line: " "' => sub {
    my $builder = SQL::Maker->new(driver => 'mysql', quote_char => '', new_line => ' ');

    subtest 'columns and tables' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ '*' ] );
        is $sql, qq{SELECT * FROM foo};
        is join(',', @binds), '';
    };

    subtest 'columns and tables, where cause (hash ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], ordered_hashref( bar => 'baz', john => 'man' ) );
        is $sql, qq{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (array ref)' => sub {
        my ($sql, @binds) = $builder->select( 'foo', [ 'foo', 'bar' ], [ bar => 'baz', john => 'man' ] );
        is $sql, qq{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?)};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and tables, where cause (hash ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], ordered_hashref(bar => 'baz', john => 'man'), {order_by => 'yo'});
        is $sql, qq{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo'});
        is $sql, qq{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo};
        is join(',', @binds), 'baz,man';
    };

    subtest 'columns and table, where cause (array ref), order by, limit, offset' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [bar => 'baz', john => 'man'], {order_by => 'yo', limit => 1, offset => 3});
        is $sql, qq{SELECT foo, bar FROM foo WHERE (bar = ?) AND (john = ?) ORDER BY yo LIMIT 1 OFFSET 3};
        is join(',', @binds), 'baz,man';
    };

    subtest 'modify prefix' => sub {
        my ($sql, @binds) = $builder->select('foo' => ['foo', 'bar'], [], {prefix => 'SELECT SQL_CALC_FOUND_ROWS '});
        is $sql, qq{SELECT SQL_CALC_FOUND_ROWS foo, bar FROM foo};
        is join(',', @binds), '';
    };

    subtest 'order_by' => sub {
        subtest 'scalar' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => 'yo'});
            is $sql, qq{SELECT * FROM foo ORDER BY yo};
            is join(',', @binds), '';
        };

        subtest 'hash ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => {'yo' => 'DESC'}});
            is $sql, qq{SELECT * FROM foo ORDER BY yo DESC};
            is join(',', @binds), '';
        };

        subtest 'array ref' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => ['yo', 'ya']});
            is $sql, qq{SELECT * FROM foo ORDER BY yo, ya};
            is join(',', @binds), '';
        };

        subtest 'mixed' => sub {
            my ($sql, @binds) = $builder->select('foo' => ['*'], +{}, {order_by => [{'yo' => 'DESC'}, 'ya']});
            is $sql, qq{SELECT * FROM foo ORDER BY yo DESC, ya};
            is join(',', @binds), '';
        };
    };

    subtest 'from' => sub {
        subtest 'multi from' => sub {
            my ($sql, @binds) = $builder->select( [ qw/foo bar/ ], ['*'], +{}, );
            is $sql, qq{SELECT * FROM foo, bar};
            is join(',', @binds), '';
        };

        subtest 'multi from with alias' => sub {
            my ($sql, @binds) = $builder->select( [ [ foo => 'f' ], [ bar => 'b' ] ], ['*'], +{}, );
            is $sql, qq{SELECT * FROM foo f, bar b};
            is join(',', @binds), '';
        };
    };

    subtest 'join' => sub {
        my ($sql, @binds) = $builder->select(undef, ['*'], +{}, {joins => [
            [foo => {
                type      => 'LEFT OUTER',
                table     => 'bar',
                condition => 'foo.bar_id = bar.id',
            }]
        ]});
        is $sql, qq{SELECT * FROM foo LEFT OUTER JOIN bar ON foo.bar_id = bar.id};
        is join(',', @binds), '';
    };
};

done_testing;
