#!/usr/bin/env perl
# Data: 2012-04-05 11:40
# Purpose:
package Words::DBI;
use base 'Class::DBI';
Words::DBI->connection( 'dbi:SQLite:dbname=words.db', '', '',
  { RaiseError => 1 } );

package Words::Word;
use base 'Words::DBI';
Words::Word->table('word');
Words::Word->columns( All => qw/wordid word/ );
Words::Word->has_many( dbs => 'Words::Db' );

package Words::Dbname;
use base 'Words::DBI';
Words::Dbname->table('dbname');
Words::Dbname->columns( All => qw/dbnameid dbname/ );

package Words::Db;
use base 'Words::DBI';
Words::Db->table('db');
Words::Db->columns( All => qw/dbid db word/ );
Words::Db->has_a( db   => 'Words::Dbname' );
Words::Db->has_a( word => 'Words::Word' );

use 5.010;
use warnings;
use Text::ExtractWords qw(words_list);
use Lingua::EN::Inflect::Phrase qw/to_S/;

# &create_db;
&check_words('a1.txt');

sub create_db {
  `rm words.db -f`;
  $dbh =
    DBI->connect( 'dbi:SQLite:dbname=words.db', '', '', { RaiseError => 1 } );
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS word (
  wordid integer PRIMARY KEY,
  word text not null collate nocase,
  unique (word)
)');
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS db (
  dbid integer PRIMARY KEY,
  db integer,
  word integer
)');
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS dbname (
  dbnameid integer PRIMARY KEY,
  dbname text
)');
  $dbh->disconnect;

  Words::Dbname->insert( { dbnameid => 1, dbname => '初中' } );
  Words::Dbname->insert( { dbnameid => 2, dbname => '高中' } );
  Words::Dbname->insert( { dbnameid => 3, dbname => '四级' } );
  Words::Dbname->insert( { dbnameid => 4, dbname => '六级' } );
  Words::Dbname->insert( { dbnameid => 5, dbname => 'TOEFL' } );
  Words::Dbname->insert( { dbnameid => 6, dbname => 'IELTS' } );
  Words::Dbname->insert( { dbnameid => 7, dbname => 'GRE' } );
  $n = 19660;
  $i = 1;

  foreach $db ( 1 .. 7 ) {
    open( DB, "source/$db.txt" ) || die $!;
    while (<DB>) {
      chomp;
      $w_id = Words::Word->find_or_create( word => $_ );
      Words::Db->insert( { db => $db, word => $w_id } );
      &bar( $i++, $n );
    }
    close(DB);
  }
  say '';
}

sub bar {
  local $| = 1;
  my $i = $_[0] || return 0;
  my $n = $_[1] || return 0;
  print "\r["
    . ( "#" x int( ( $i / $n ) * 50 ) )
    . ( " " x ( 50 - int( ( $i / $n ) * 50 ) ) ) . "]";
  printf( "%2.1f%%", $i / $n * 100 );
  local $| = 0;
}

sub check_words {
  my @list = ();
  open(IN,shift) || die $!;
  my $text = do { local $/; <IN> };
  words_list(\@list, $text);
  foreach (@list) {
    next if /\d/;
    $s = to_S($_);
    if ($word = Words::Word->search(word => $s)->first) {
      @dbs = $word->dbs;
      print $s;
      map { print '|',$_->db->dbname } @dbs;
      say '';
    }
    else {
      say $_;
    }
  }
}
