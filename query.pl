use Mojolicious::Lite;
use lib 'lib';
use Words;

get '/' => 'query';

get '/query/:word' => sub {
  my $self = shift;
  my $word = $self->stash('word');
  $self->render(text => Words->check_words($word));
};

app->start;

__DATA__

