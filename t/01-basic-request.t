use Test::More;
use LWP::UserAgent;
use IO::Handle;
use Async;
use Storable qw(thaw);
use Data::Dump qw(dump);

use_ok('Test::HTTP::MockServer::Once');

my $server = Test::HTTP::MockServer::Once->new(port => 3000);
my $url = $server->url_base();
my $ua = LWP::UserAgent->new(timeout => 1);

STDOUT->autoflush(1);
STDERR->autoflush(1);

my $request;
my $handle_request = sub {
    my $request = shift;
    my $response = shift;
    $response->content("Hello!");
};

note("Starting web server on ".$server->url_base());
my $proc = AsyncTimeout->new(sub { $server->start_mock_server($handle_request) }, 30, "TIMEOUT");
#~ my $result = $proc->result('force completion');
#~ BAIL_OUT "No request received" if($proc->result eq "TIMEOUT");
#~ my $interaction = thaw $proc->result;
#~ note("URI: ".$interaction->{request}->uri->as_string);

my $res = $ua->get($url);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, 'Hello!', 'got the correct response');

TODO: {
	todo_skip("not reimplemented yet",1);

	my $handle_request_phase2 = sub {
		my ($request, $response) = @_;
		die "phase2\n";
	};
	$server->start_mock_server($handle_request_phase2);

	$res = $ua->get($url);
	is($res->code, 500, 'error response code');
	is($res->message, 'Internal Server Error', 'error response message');
	is($res->content, "phase2\n", 'got the correct response');

	$res = $ua->get($url);
	is($res->code, 500, 'error response code');
	is($res->message, 'Internal Server Error', 'error response message');
	is($res->content, "phase2\n", 'got the correct response');

	$server->stop_mock_server();

	my $handle_request_phase3 = sub {
		my ($request, $response) = @_;
		$response->code('204');
		$response->message('Accepted');
		$response->header('Content-type' => 'application/json');
		$response->content('[]');
	};
	$server->start_mock_server($handle_request_phase3);

	$res = $ua->get($url);
	is($res->code, 204, 'custom response code');
	is($res->message, 'Accepted', 'custom response message');
	is($res->header('Content-type'), 'application/json', 'custom header');
	is($res->content, "[]", 'returned content');

	$server->stop_mock_server();
}

done_testing();

__END__

Copyright 2016 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

