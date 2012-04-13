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

package Words;
use Text::ExtractWords qw(words_list);
use Lingua::EN::Inflect::Phrase qw/to_S/;

sub check_words {
  my @list = ();
  my $self = shift;
  my $text = shift;
  my ($s,$word,@dbs);
  my $res = '';
  words_list(\@list, $text);
  foreach (@list) {
    next if /\d/;
    $s = to_S($_);
    $res .= $s;
    if ($word = Words::Word->search(word => $s)->first) {
      @dbs = $word->dbs;
      map { $res .= '|'.$_->db->dbname } @dbs;
    }
    $res .= ", ";
  }
  return $res;
}

sub check_text {
  my @list = ();
  my $self = shift;
  my $text = shift;
  my $libs = shift;
  my ($s,$word,@dbs,$isChecked);
  my $res = '';
  words_list(\@list, $text);
  foreach (@list) {
    next if /\d/;
    $s = to_S($_);
    $isChecked = 0;
    if ($word = Words::Word->search(word => $s)->first) {
      @dbs = $word->dbs;
      map {
        my $dbn = $_->db->dbname;
        if ($libs =~ /${dbn}/){
          $isChecked = 1;
        }
      } @dbs;
    }
    if ($isChecked == 1) {
      $res .= join('','<em>',$s,'</em>');
    }
    else{
     $res .= $s;
    }
    $res .= " ";
  }
  $res =~ s/<\/em> <em>/ /g;
  return $res;
}

1;
