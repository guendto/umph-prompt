
use warnings;
use strict;
use v5.10;

use Umph::Prompt;

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
      my @a;
      push @a, {cmd => 'foo', desc => 'bar'};
      $p->help(\@a);
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

# vim: set ts=2 sw=2 tw=72 expandtab:
