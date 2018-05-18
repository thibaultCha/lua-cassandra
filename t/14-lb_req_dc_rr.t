# vim:set ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua;
use t::Util;

our $HttpConfig = $t::Util::HttpConfig;

plan tests => repeat_each() * blocks() * 3 - 2;

run_tests();

__DATA__

=== TEST 1: lb_req_dc_rr sanity
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require 'resty.cassandra.policies.lb.req_dc_rr'
            ngx.say(req_dc_rr.name)

            local peers = {
                {host = '10.0.0.1', data_center = 'dc2'},

                {host = '127.0.0.1', data_center = 'dc1'},
                {host = '127.0.0.2', data_center = 'dc1'},
                {host = '127.0.0.3', data_center = 'dc1'},

                {host = '10.0.0.2', data_center = 'dc2'},
                {host = '10.0.0.3', data_center = 'dc2'}
            }

            local lb = req_dc_rr.new('dc1')
            ngx.say('local_dc: ', lb.local_dc)

            lb:init(peers)

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("1.", i, ' ', peer.host)
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("2.", i, ' ', peer.host)
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("3.", i, ' ', peer.host)
            end
        }
    }
--- request
GET /t
--- response_body
req_and_dc_aware_round_robin
local_dc: dc1

1.1 127.0.0.1
1.2 127.0.0.2
1.3 127.0.0.3
1.4 10.0.0.1
1.5 10.0.0.2
1.6 10.0.0.3

2.1 10.0.0.3
2.2 127.0.0.2
2.3 127.0.0.3
2.4 127.0.0.1
2.5 10.0.0.2
2.6 10.0.0.1

3.1 10.0.0.1
3.2 127.0.0.3
3.3 127.0.0.1
3.4 127.0.0.2
3.5 10.0.0.3
3.6 10.0.0.2
--- no_error_log
[error]



=== TEST 2: lb_req_dc_rr on loop break
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require 'resty.cassandra.policies.lb.req_dc_rr'
            ngx.say(req_dc_rr.name)

            local peers = {
                {host = '10.0.0.1', data_center = 'dc2'},

                {host = '127.0.0.1', data_center = 'dc1'},
                {host = '127.0.0.2', data_center = 'dc1'},
                {host = '127.0.0.3', data_center = 'dc1'},

                {host = '10.0.0.2', data_center = 'dc2'},
                {host = '10.0.0.3', data_center = 'dc2'}
            }

            local lb = req_dc_rr.new('dc1')
            ngx.say('local_dc: ', lb.local_dc)

            lb:init(peers)

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("1.", i, ' ', peer.host)
                if i == #peers - 1 then
                    break
                end
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("2.", i, ' ', peer.host)
                ngx.log(ngx.INFO, i, ' ', peer.host)
            end
        }
    }
--- request
GET /t
--- response_body
req_and_dc_aware_round_robin
local_dc: dc1

1.1 127.0.0.1
1.2 127.0.0.2
1.3 127.0.0.3
1.4 10.0.0.1
1.5 10.0.0.2

2.1 10.0.0.2
2.2 127.0.0.2
2.3 127.0.0.3
2.4 127.0.0.1
2.5 10.0.0.3
2.6 10.0.0.1
--- no_error_log
[error]



=== TEST 3: lb_req_dc_rr with missing local_dc
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require 'resty.cassandra.policies.lb.req_dc_rr'
            local lb = req_dc_rr.new()
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
local_dc must be a string



=== TEST 4: lb_req_dc_rr with missing data_center fields
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require 'resty.cassandra.policies.lb.req_dc_rr'

            local peers = {
                {host = '10.0.0.1', data_center = 'dc2'},

                {host = '127.0.0.1', data_center = 'dc1'},
                {host = '127.0.0.2', data_center = 'dc1'},
                {host = '127.0.0.3'}
            }

            local lb = req_dc_rr.new('dc1')

            lb:init(peers)
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
peer 127.0.0.3 data_center field must be a string



=== TEST 5: lb_req_dc_rr with hyphens in dc name
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require "resty.cassandra.policies.lb.req_dc_rr"

            local peers = {
                { host = "10.0.0.1", data_center = "europe-west1-b" },

                { host = "127.0.0.1", data_center = "dc1"},
                { host = "127.0.0.2", data_center = "dc1"},
                { host = "127.0.0.3", data_center = "dc1"},
            }

            local lb = req_dc_rr.new("europe-west1-b")
            ngx.say("local_dc: ", lb.local_dc)

            lb:init(peers)

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("1.", i, " ", peer.host)
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("2.", i, " ", peer.host)
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("3.", i, " ", peer.host)
            end
        }
    }
--- request
GET /t
--- response_body
local_dc: europe-west1-b

1.1 10.0.0.1
1.2 127.0.0.1
1.3 127.0.0.2
1.4 127.0.0.3

2.1 127.0.0.3
2.2 10.0.0.1
2.3 127.0.0.2
2.4 127.0.0.1

3.1 127.0.0.1
3.2 10.0.0.1
3.3 127.0.0.3
3.4 127.0.0.2
--- no_error_log
[error]



=== TEST 6: lb_req_dc_rr break several times
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local req_dc_rr = require 'resty.cassandra.policies.lb.req_dc_rr'
            ngx.say(req_dc_rr.name)

            local peers = {
                {host = '10.0.0.1', data_center = 'dc2'},

                {host = '127.0.0.1', data_center = 'dc1'},
                {host = '127.0.0.2', data_center = 'dc1'},
                {host = '127.0.0.3', data_center = 'dc1'},

                {host = '10.0.0.2', data_center = 'dc2'},
                {host = '10.0.0.3', data_center = 'dc2'}
            }

            local lb = req_dc_rr.new('dc1')
            ngx.say('local_dc: ', lb.local_dc)

            lb:init(peers)

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("1.", i, ' ', peer.host)
                if i == 1 then
                    break
                end
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("2.", i, ' ', peer.host)
                if i == 1 then
                    break
                end
            end

            ngx.say()
            for i, peer in lb:iter() do
                ngx.say("3.", i, ' ', peer.host)
                if i == 1 then
                    break
                end
            end
        }
    }
--- request
GET /t
--- response_body
req_and_dc_aware_round_robin
local_dc: dc1

1.1 127.0.0.1

2.1 127.0.0.1

3.1 127.0.0.1
--- no_error_log
[error]

