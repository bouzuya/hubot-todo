{Robot, User, TextMessage} = require 'hubot'
assert = require 'power-assert'
path = require 'path'
sinon = require 'sinon'

describe 'todo', ->
  beforeEach (done) ->
    @sinon = sinon.sandbox.create()
    # for warning: possible EventEmitter memory leak detected.
    # process.on 'uncaughtException'
    @sinon.stub process, 'on', -> null
    @robot = new Robot(path.resolve(__dirname, '..'), 'shell', false, 'hubot')
    @robot.adapter.on 'connected', =>
      @robot.load path.resolve(__dirname, '../../src/scripts')
      done()
    @robot.run()

  afterEach (done) ->
    @robot.brain.on 'close', =>
      @sinon.restore()
      done()
    @robot.shutdown()

  describe 'listeners[0].regex', ->
    beforeEach ->
      @sender = new User 'bouzuya', room: 'hitoridokusho'
      @add = @sinon.spy()
      @list = @sinon.spy()
      @done = @sinon.spy()
      @robot.listeners[0].callback = @add
      @robot.listeners[1].callback = @list
      @robot.listeners[2].callback = @done

    describe 'receive "@hubot todo add fuga hoge"', ->
      beforeEach ->
        message = '@hubot todo add fuga hoge'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'matches', ->
        assert @add.callCount is 1
        match = @add.firstCall.args[0].match
        assert match.length is 2
        assert match[0] is '@hubot todo add fuga hoge'
        assert match[1] is 'fuga hoge'

    describe 'receive "@hubot todo list"', ->
      beforeEach ->
        message = '@hubot todo list'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'matches', ->
        assert @list.callCount is 1
        match = @list.firstCall.args[0].match
        assert match.length is 1
        assert match[0] is '@hubot todo list'

    describe 'receive "@hubot todo ls"', ->
      beforeEach ->
        message = '@hubot todo ls'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'matches', ->
        assert @list.callCount is 1
        match = @list.firstCall.args[0].match
        assert match.length is 1
        assert match[0] is '@hubot todo ls'

    describe 'receive "@hubot todo done 1"', ->
      beforeEach ->
        message = '@hubot todo done 1'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'matches', ->
        assert @done.callCount is 1
        match = @done.firstCall.args[0].match
        assert match.length is 2
        assert match[0] is '@hubot todo done 1'
        assert match[1] is '1'

    describe 'receive "@hubot todo done"', ->
      beforeEach ->
        message = '@hubot todo done'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'matches', ->
        assert @done.callCount is 1
        match = @done.firstCall.args[0].match
        assert match.length is 2
        assert match[0] is '@hubot todo done'
        assert match[1] is undefined

  describe 'listeners[0].callback', ->
    beforeEach ->
      @add = @robot.listeners[0].callback
      @list = @robot.listeners[1].callback
      @done = @robot.listeners[2].callback

    describe 'receive "@hubot add hoge"', ->
      beforeEach ->
        @send = @sinon.spy()
        @add
          match: ['@hubot add hoge', 'hoge']
          robot: @robot
          message:
            user:
              id: 'user1'
          send: @send

      it 'send "(1) hoge"', ->
        assert @send.callCount is 1
        assert @send.firstCall.args[0] is '(1) hoge'
        data = @robot.brain.get 'todo'
        assert.deepEqual data.user1, ['hoge']

    describe 'receive "@hubot list"', ->
      beforeEach ->
        @robot.brain.get('todo').user1 = ['fuga']
        @send = @sinon.spy()
        @list
          match: ['@hubot list']
          robot: @robot
          send: @send
          message:
            user:
              id: 'user1'

      it 'send "(1) fuga"', ->
        assert @send.callCount is 1
        assert @send.firstCall.args[0] is '(1) fuga'
        data = @robot.brain.get 'todo'
        assert.deepEqual data.user1, ['fuga']

    describe 'receive "@hubot done 2"', ->
      beforeEach ->
        @robot.brain.get('todo').user1 = ['fuga', 'hoge', 'piyo']
        @send = @sinon.spy()
        @done
          match: ['@hubot done 2', '2']
          robot: @robot
          message:
            user:
              id: 'user1'
          send: @send

      it 'send "(2) hoge"', ->
        assert @send.callCount is 1
        assert @send.firstCall.args[0] is '(2) hoge'
        data = @robot.brain.get 'todo'
        assert.deepEqual data.user1, ['fuga', 'piyo']
