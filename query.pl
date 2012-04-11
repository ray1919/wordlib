use Mojolicious::Lite;
use lib 'lib';
use Words;

get '/' => 'appLayout';

get '/query/:word' => sub {
  my $self = shift;
  my $word = $self->stash('word');
  $self->render(text => Words->check_words($word));
};

app->start;

__DATA__

