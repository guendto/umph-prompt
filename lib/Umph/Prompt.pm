#
# Umph::Prompt
# Copyright (C) 2011  Toni Gundogdu <legatvs@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#

package Umph::Prompt;

use 5.010001;
use warnings;
use strict;
use v5.10;

use POSIX qw(isdigit);
use Carp qw(croak);

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
  'all' => [
    qw(

      )
  ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = qw(

);

our $VERSION = '0.1.0';

# Preloaded methods go here.

sub new
{
  my ($self, @args) = @_;
  bless {@args}
    || {
        'max_shown_items' => 20,
        'current_index'   => 0,
       }, $self;
}

sub count_selected
{
  my ($self, $items) = @_;
  my ($n, $i) = (0, 0);
  foreach (@{$items})
  {
    ++$n if $_->{'selected'};
    ++$i;
  }
  return sprintf " [%s of %s]", $n, $self->{'total_items'};
}

sub exec
{
  my ($self) = @_;
  $self->{'exit'} = 0;
  croak "set max_shown_items" unless $self->{'max_shown_items'};
  croak "set total_items"     unless $self->{'total_items'};
  croak "set prompt_msg"      unless $self->{'prompt_msg'};
  croak "set commands"        unless $self->{'commands'};
  $self->{'current_index'} ||= 0;
  $self->{'onloaded'}($self) if $self->{'onloaded'};

  while (not $self->{'exit'})
  {
    my $p = sprintf "(%s", $self->{'prompt_msg'};
    $p .= count_selected($self, $self->{'onitems'}($self))
      if $self->{'onitems'};
    $p .= ") ";
    print STDERR $p;
    my $s = <STDIN>;
    next unless $s;
    chomp $s;
    _parse_line($self, _trim($self, $s));
  }
}

sub exit
{
  my ($self, $items, $args) = @_;    # Pass items, args by ref

  my $c = (caller(0))[3];
  croak $c . q/ expects $self/  unless $self;
  croak $c . q/ expects $items/ unless $items;

  foreach (@{$items})
  {
    if ($_->{selected} or ($args->[0] && $args->[0] eq "!"))
    {
      $self->{'exit'} = 1;

=for comment
      foreach (@{$items})
      {
        say $_->{'url'} if $_->{'selected'};
      }
=cut

      return;
    }
  }
  say STDERR
    qq/error: you have not selected anything (or use "quit !")/;
}

sub toggle
{
  my ($self, $items, $args) = @_;    # Pass items, args by ref

  my $c = (caller(0))[3];
  croak $c . q/ expects $self/  unless $self;
  croak $c . q/ expects $args/  unless $args;
  croak $c . q/ expects $items/ unless $items;

  my ($from, $to) = @{$args};

  say STDERR "error: index must be >= 1" and return
    if $from < 1;

  for (my $i = $from; $i <= ($to or $from); ++$i)
  {
    my $n = $i - 1;
    if ($items->[$n])
    {
      $items->[$n]->{'selected'} = not $items->[$n]->{'selected'};
      my $st =
        $items->[$n]->{'selected'}
        ? "selected"
        : "unselected";
      say STDERR "=> $st ", ++$n;
    }
  }
}

sub display
{
  my ($self, $items, $args) = @_;    # Pass by ref

  my $c = (caller(0))[3];
  croak $c . q/ expects $self/  unless $self;
  croak $c . q/ expects $items/ unless $items;

  my $i = _move($self, $args);
  return if $i == -1;

  my $m = $self->{'max_shown_items'};

  for (my $j = 0; $items->[$i] && $j < $m; ++$i, ++$j)
  {
    my $s =
      sprintf "%3s%3d: $items->[$i]->{'title'}",
      $items->[$i]->{'selected'}
      ? ">"
      : "",
      $i + 1;
    say STDERR $s;
  }
}

sub max_shown_items
{
  my $self = shift;
  if (@_)
  {
    my $n = shift;
    if (isdigit($n))
    {
      $n = 20 if ($n <= 0 or $n > ($self->{'total_items'} - $n));
      $self->{'max_shown_items'} = $n;
      say STDERR qq/max_shown_items => $n/;
    }
    else
    {
      say STDERR
        qq/error: use syntax: "max (integer)", "display m" to show current/;
    }
  }
  $self->{'max_shown_items'};
}

sub help
{
  my ($self, $additional) = @_;    # Pass by ref
  say STDERR qq/Commands:
  quit [!]                    .. quit, '!' to force
  help                        .. show this help
  display [+|-|^[num]|\$|_|m]  .. display items, see "display h" for help
  select [a|n|i]              .. select items, see "select h" for help
  [index][-to][,]             .. toggle (select) items, e.g. "1,3,7-9"
  max [num]                   .. set max shown items (in page)/;
  foreach (@{$additional})
  {
    my $s = sprintf "  %-*s .. %s", 27, $_->{'cmd'}, $_->{'desc'};
    say STDERR $s;
  }
  say STDERR
    qq/Command name abbreviations are allowed, e.g. "q" instead of "quit"./;
}

my $_qr_move = qr{^([\w+-^\$])(?:(\d+)|$)};

sub select
{
  my ($self, $items, $args) = @_;    # Pass by ref

  my $c = (caller(0))[3];
  croak $c . q/ expects $self/  unless $self;
  croak $c . q/ expects $items/ unless $items;

  my $arg0 = $args->[0];
  _select_help($self) and return unless $arg0;
  return unless $arg0;

  given ($arg0 =~ /$_qr_move/)
  {
    when ($1 eq "a")
    {
      _select_all($self, $items);
    }
    when ($1 eq "n")
    {
      _select_none($self, $items);
    }
    when ($1 eq "i")
    {
      _select_invert($self, $items);
    }
    when ($1 eq "h")
    {
      _select_help($self);
    }
  }
}

sub _select_help
{
  my ($self) = @_;
  say STDERR qq/Examples:
  "select a"          select all
  "select n"          clear selection
  "select i"          invert selection
You can use command name abbreviates, e.g. "s a" instead of "select a"./;
}

sub _select_all
{
  my ($self, $items) = @_;
  $_->{'selected'} = 1 foreach @{$items};
  say STDERR "=> selected all";
}

sub _select_none
{
  my ($self, $items) = @_;
  $_->{'selected'} = 0 foreach @{$items};
  say STDERR "=> cleared selection";
}

sub _select_invert
{
  my ($self, $items) = @_;
  $_->{'selected'} = not $_->{selected} foreach @{$items};
  say STDERR "=> inverted selection";
}

sub _parse_line
{
  my ($self, $ln) = @_;

  if ($ln =~ /^\d+/)
  {
    $ln =~ s{\s}//g;
    foreach (split /,/, $ln)
    {
      if (/^(\d+)(?:-(\d+)|$)/)
      {
        $self->{'ontoggle'}($self, [$1, $2]) if $self->{'ontoggle'};
      }
      else
      {
        say STDERR qq/error: no idea what to do with `$_'/;
      }
    }
  }
  else
  {
    if ($ln =~ /^(\w)/)
    {
      my $c = $self->{'commands'}{$1};
      if ($c)
      {
        my @a = split /\s/, $ln;
        shift @a;
        $c->($self, \@a);
      }
    }
  }
}

sub _trim
{
  my ($self, $s) = @_;
  $s =~ s{^[\s]+}//;
  $s =~ s{\s+$}//;
  $s =~ s{\s\s+}/ /g;
  $s;
}

sub _move
{
  my ($self, $args) = @_;

  my $arg0 = $args->[0];
  my $i    = $self->{'current_index'};

  return $i unless $arg0;

  my $m = $self->{'total_items'} - $self->{'max_shown_items'};

  given ($arg0 =~ /$_qr_move/)
  {
    when ($1 eq "+")
    {
      $i += $self->{'max_shown_items'};
      $i = $m if $i >= $m;
      $i = 0  if $i < 0;
    }
    when ($1 eq "-")
    {
      $i -= $self->{'max_shown_items'};
      $i = 0 if $i < 0;
    }
    when ($1 eq "^")
    {
      my $n = $i;
      $i = ($2 || 0);    # "s ^" or "s ^n", latter moves to index n
      $i = $n if ($i >= $m) || ($i < 0);
    }
    when ($1 eq "\$")
    {
      $i = $m;
      $i = 0 if $i < 0;
    }
    when ($1 eq "_")
    {
      say STDERR "current_index=$self->{'current_index'}";
      $i = -1;           # Do not show list.
    }
    when ($1 eq "m")
    {
      say STDERR "max_shown_items=$self->{'max_shown_items'}";
      $i = -1;
    }
    when ($1 eq "h")
    {
      say STDERR qq/Examples:
  "display"      without any args; display current page
  "display _"    print current index
  "display ^2"   move to index 2
  "display +"    next page
  "display -"    previous page
  "display ^"    first page
  "display \$"    last page
  "display m"    print max_shown_items
You can use command name abbreviates, e.g. "d +" instead of "display +"./;
      $i = -1;    # Do not show list.
    }
    default
    {
      say STDERR
        qq/error: no idea what to do with `$1', try "display h" for help/;
      $i = -1;    # Do not show list.
    }
  }
  $self->{'current_index'} = $i if $i > -1;
  $i;
}

1;

__END__

=head1 NAME

Umph::Prompt - Interactive prompt for Umph

=head1 SYNOPSIS

  my @items;
  push @items, {title => 'foo', url => 'http://foo', selected => 0};
  push @items, {title => 'bar', url => 'http://bar', selected => 0};

  my $p = new Umph::Prompt(

    # Commands.
    commands => {
      q => sub {
        my ($p, $args) = @_;
        $p->exit(\@items, $args);
      },
      d => sub {
        my ($p, $args) = @_;
        $p->display(\@items, $args);
      },
      m => sub {
        my ($p, $args) = @_;
        $p->max_shown_items(@{$args});
      },
      s => sub {
        my ($p, $args) = @_;
        $p->select(\@items, $args);
      },
      h => sub {
        my ($p, $args) = @_;
        $p->help($args);
      },
    },

    # Callbacks. All of these are optional.
    ontoggle => sub {
      my ($p, $args) = @_;
      $p->toggle(\@items, $args);
    },
    onloaded => sub {
      my ($p, $args) = @_;
      $p->display(\@items, $args);
    },
    onitems => sub {return \@items},

    # Other (required) settings
    total_items     => scalar @items,
    prompt_msg      => 'foo',
    max_shown_items => 20
  );

  $p->exec;

=head1 DESCRIPTION

Umph::Prompt is an interactive prompt module for umph and
similar programs.

=head2 EXPORT

None by default.

=head1 SEE ALSO

  gitweb: <http://repo.or.cz/w/umph-prompt.git>

=head1 AUTHOR

Toni Gundogdu E<lt>legatvs at sign cpan org<gt>

=head1 LICENSE

Umph::Prompt is free software, licensed under the LGPLv2.1+.

=cut

# vim: set ts=2 sw=2 tw=72 expandtab:
