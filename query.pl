use Mojolicious::Lite;
use lib 'lib';
use Words;

get '/' => 'query';

post '/query' => sub {
  my $self = shift;
  my $text = $self->param('text') || '';
  my $libs = $self->param('libs') || '';
  $self->render(text => Words->check_text($text,$libs));
};
get '/query/:word' => sub {
  my $self = shift;
  my $word = $self->stash('word');
  $self->render(text => Words->check_words($word));
};

app->start;

__DATA__

