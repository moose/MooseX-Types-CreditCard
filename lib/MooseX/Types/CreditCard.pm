package MooseX::Types::CreditCard;
use 5.008;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use MooseX::Types -declare => [ qw(
	CreditCard
	CardNumber
	CardSecurityCode
	CardExpiration
) ];

use MooseX::Types::Moose                   qw( Str Int HashRef );
use MooseX::Types::Common::String 0.001005 qw( NumericCode     );
use MooseX::Types::DateTime ();

use Class::Load 0.20 qw( load_class );

subtype CardNumber,
	as NumericCode,
	where {
		length($_) <= 20
		&& length $_ >= 12
		&& load_class('Business::CreditCard')
		&& Business::CreditCard::validate($_)
	},
	message {'"'. $_ . '" is not a valid credit card number' };


subtype CardSecurityCode,
	as NumericCode,
	where {
		length $_ >= 3
		&& length $_ <= 4
		&& $_ =~ /^[0-9]+$/xms
	},
	message { '"'
		. $_
		. '" is not a valid credit card security code. Must be 3 or 4 digits'
	};

subtype CardExpiration,
	as MooseX::Types::DateTime::DateTime,
	where {
		my ( $month, $year ) = ( $_->month, $_->year );

		my $comparitor
			= load_class('DateTime')
			->last_day_of_month( month => $month, year => $year )
			;

		return 0 unless DateTime->compare( $_, $comparitor ) == 0;
		return 1;
	},
	message {
		'DateTime object is not the last day of month';
	};

subtype CreditCard,
	as CardNumber,
	where {
		our @CARP_NOT = qw( Moose::Meta::TypeConstraint );
		load_class('Carp');
		Carp::carp 'DEPRECATED: use CardNumber instead of CreditCard Type';
		1;
	}, # just for backcompat
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CardNumber, from Str,
	via {
		my $int = $_;
		$int =~ tr/0-9//cd;
		return $int;
	};
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CreditCard, from Str,
	via {
		my $int = $_;
		$int =~ tr/0-9//cd;
		return $int;
	};
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CardExpiration, from HashRef,
	via {
		return load_class('DateTime')->last_day_of_month( %{ $_ } );
	};

1;

# ABSTRACT: Moose Types related to Credit Cards

=head1 SYNOPSIS

	{
		package My::Object;
		use Moose;
		use MooseX::Types::CreditCard qw(
			CardNumber
			CardSecurityCode
			CardExpiration
		);

		has credit_card => (
			coerce => 1,
			is     => 'ro',
			isa    => CreditCard,
		);

		has cvv2 => (
			is  => 'ro',
			isa => CardSecurityCode,
		);

		has expiration => (
			isa    => CardExpiration,
			coerce => 1,
			is     => 'ro'
		);

		__PACKAGE__->meta->make_immutable;
	}

	my $obj = My::Object->new({
		credit_card => '4111111111111111',
		cvv2        => '123',
		expiration  => { month => 10, year => 2013 },
	});

=head1 DESCRIPTION

This module provides types related to Credit Cards for weak validation.

=head1 TYPES

=head2 CardNumber

B<Base Type:> C<Str>

It will validate that the number passed to it appears to be a
valid credit card number. Please note that this does not mean that the
Credit Card is actually valid, only that it appears to be by algorithms
defined in L<Business::CreditCard>.



Enabling coerce will strip out any non C<0-9> characters from a string
allowing for numbers like "4111-1111-1111-1111" to be passed.

=head2 CardSecurityCode

B<Base Type:> C<Str>

A Credit L<Card Security Code|http://wikipedia.org/wiki/Card_security_code> is
a 3 or 4 digit number. This is also called CSC, CVV, CVC, and CID, depending
on the issuing vendor.

=head2 CardExpiration

B<Base Type:> C<DateTime>

A Credit Card Expiration Date. It's a L<DateTime> Object and checks to see if
the object is equal to the last day of the month, using the month and year
stored in the object.

Coerce allows you to create the L<DateTime> object from a C<HashRef> by passing
the keys C<month> and C<year>.

=back

=head1 SEE ALSO

=over

=item * L<Business::CreditCard>

=item * L<DateTime>

=back

=cut
