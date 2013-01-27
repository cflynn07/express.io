
should = require('chai').should()
io = require 'socket.io-client'
easyrequest = require 'request'
spawn = require('child_process').spawn

startExample = (appName, done, next) ->
    app = spawn 'node', [appName]
    setTimeout ->
        next ->
            app.kill 'SIGKILL'
            setTimeout ->
                done()
            , 1200
    , 2000

describe 'the routing example', ->
    it 'should work', (next) ->
        startExample '../examples/routing/app', next, (done) ->
            client = io.connect 'http://localhost:7076',
                'force new connection': true
            client.on 'talk', (data) ->
                data.message.should.equal 'io event from an io route on the server'
                client.disconnect()
                done()
            client.emit 'ready'

describe 'the route forwarding example', ->
    it 'should work', (next) ->
        startExample '../examples/route-forwarding/app', next, (done) ->
            easyrequest 'http://localhost:7076', (error, response, body) ->
                body = JSON.parse body
                body.hello.should.equal 'from io route'
                done()

describe 'the broadcast example', ->
    it 'should work', (next) ->
        startExample '../examples/broadcasting/app', next, (done) ->
            client = io.connect 'http://localhost:7076',
                'force new connection': true
            other = io.connect 'http://localhost:7076',
                'force new connection': true
            client.emit 'ready'
            other.on 'new visitor', ->
                done()
            client.on 'new visitor', ->
                throw new Error 'should not receive'

describe 'the session example', ->
    it 'should work', (next) ->
        startExample '../examples/sessions/app', next, (done) ->
            easyrequest 'http://localhost:7076', (error, response, body) ->
                cookie = response.headers['set-cookie']
                client = io.connect "http://localhost:7076?cookie=#{encodeURIComponent(cookie)}",
                    'force new connection': true
                client.emit 'ready', 'brad'
                client.on 'get-feelings', ->
                    client.emit 'send-feelings', 'good'
                client.on 'session', (session) ->
                    session.name.should.equal 'brad'
                    session.feelings.should.equal 'good'
                    should.exist session.loginDate 
                    done()

describe 'the rooms example', ->
    it 'should work', (next) ->
        startExample '../examples/rooms/app', next, (done) ->
            client = io.connect 'http://localhost:7076',
                'force new connection': true
            other = io.connect 'http://localhost:7076',
                'force new connection': true
            client.emit 'ready', 'cool'
            process.nextTick ->
                other.emit 'ready', 'cool'
            client.on 'announce', (data) ->
                message.should.equal 'New client in the cool room. '
                done()
            other.on 'announce', (data) ->
                data.message.should.equal 'New client in the cool room. '
                done()

describe 'the acknowledgements example', ->
    it 'should work', (next) ->
        startExample '../examples/acknowledgements/app', next, (done) ->
            client = io.connect 'http://localhost:7076',
                'force new connection': true
            client.emit 'ready', {}, (data) ->
                data.success.should.equal 'here is your acknowledegment for the ready event'
                done()

describe 'the realtime canvas example', ->
    it 'should work', (next) ->
        startExample '../examples/realtime-canvas/app', next, (done) ->
            client = io.connect 'http://localhost:7076',
                'force new connection': true
            other = io.connect 'http://localhost:7076',
                'force new connection': true
            client.emit 'drawClick'
            other.on 'draw', ->
                done()
            client.on 'new visitor', ->
                throw new Error 'should not receive'