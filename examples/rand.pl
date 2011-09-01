#!/usr/bin/env perl

use warnings;
use strict;
use v5.10;

use Carp qw(croak);
use Umph::Prompt;

my @items;

sub rand_title
{
  my $r = int(rand(1000));
  open my $fh, "<", "/usr/share/dict/american-english" or croak "$!\n";

  my $i = 0;
  while (<$fh>)
  {
    last if $i == $r;
    ++$i;
  }
  close $fh;
  my $s = $_;
  chomp $s;
  $s;
}

my $prompt;

sub init
{
  for (my $i = 0; $i < 222; ++$i)
  {
    push @items,
      {title => rand_title(), url => 'http://foo.bar', selected => 0};
  }

  my %c = (
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
  );

  $prompt = new Umph::Prompt(
    commands        => \%c,
    prompt_msg      => 'pager',
    total_items     => scalar @items,
    current_index   => 0,
    max_shown_items => 20,
    ontoggle        => sub {
      my ($p, $args) = @_;

      #      say STDERR "ontoggle = args = $args" if $args;
      $p->toggle(\@items, $args);
    },
    onitems => sub {return \@items},
                            );

  $prompt->exec;
}

sub main
{
  init;
}

main;

# vim: set ts=2 sw=2 tw=72 expandtab:
