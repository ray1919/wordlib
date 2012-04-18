#!/usr/bin/env perl
# Data: 2012-04-17
# Purpose: load wordlib db data into mysql databaes
package Words::DBI;
use base 'Class::DBI';
Words::DBI->connection( 'dbi:mysql:dbname=ZhaoRui;mysql_socket=/var/lib/mysql/mysql.sock', 'zhaorui', '', { RaiseError => 1 } );

package Words::Word;
use base 'Words::DBI';
Words::Word->table('wl_word');
Words::Word->columns( All => qw/wordid word/ );
Words::Word->has_many( dbs => 'Words::Db' );

package Words::Dbname;
use base 'Words::DBI';
Words::Dbname->table('wl_dbname');
Words::Dbname->columns( All => qw/dbnameid dbname/ );

package Words::Db;
use base 'Words::DBI';
Words::Db->table('wl_db');
Words::Db->columns( All => qw/dbid db word/ );
Words::Db->has_a( db   => 'Words::Dbname' );
Words::Db->has_a( word => 'Words::Word' );

use 5.010;
use warnings;
use Text::ExtractWords qw(words_list);
use Lingua::EN::Inflect::Phrase qw/to_S/;

&create_db;
&check_words('a1.txt');

sub create_db {
  $dbh =
    DBI->connect( 'dbi:mysql:dbname=ZhaoRui;mysql_socket=/var/lib/mysql/mysql.sock', 'zhaorui', '', { RaiseError => 1 } );
  $dbh->do('DROP TABLE IF EXISTS wl_word');
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS wl_word (
  wordid integer PRIMARY KEY AUTO_INCREMENT,
  word varchar(50) not null,
  unique (word)
)');
  $dbh->do('DROP TABLE IF EXISTS wl_db');
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS wl_db (
  dbid integer PRIMARY KEY AUTO_INCREMENT,
  db integer,
  word integer
)');
  $dbh->do('DROP TABLE IF EXISTS wl_dbname');
  $dbh->do(
    'CREATE TABLE IF NOT EXISTS wl_dbname (
  dbnameid integer PRIMARY KEY,
  dbname varchar(50)
)');
  $dbh->disconnect;

  Words::Dbname->insert( { dbnameid => 1, dbname => 'junior' } );
  Words::Dbname->insert( { dbnameid => 2, dbname => 'senior' } );
  Words::Dbname->insert( { dbnameid => 3, dbname => 'CET-4' } );
  Words::Dbname->insert( { dbnameid => 4, dbname => 'CET-6' } );
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
