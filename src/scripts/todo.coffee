# Description
#   A Hubot script that manage TODOs.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot todo add <task> - add TODO
#   hubot todo list - list TODOs
#   hubot todo done <task no> - delete TODO
#
# Author:
#   bouzuya <m@bouzuya.net>
#
module.exports = (robot) ->

  # robot.brain.todo.<user>[<no>] = <todo>
  todos = {}
  robot.brain.set 'todo', todos
  robot.brain.on 'loaded', (data) ->
    loadedTodos = (data._private.todo ? {})
    for userId of loadedTodos
      loadedUserTodos = loadedTodos[userId]
      userTodos = todos[userId]
      if userTodos?
        loadedUserTodos[userId].forEach (todo) ->
          unless userTodos.some((t) -> t is todo)
            userTodos.push todo

  format = (n, todo) -> "(#{n}) #{todo}"

  add = (res) ->
    return unless todos?
    todo = res.match[1]
    userId = res.message.user.id
    userTodos = todos[userId] ? []
    userTodos.push todo
    todos[userId] = userTodos
    res.robot.brain.save()
    res.send format(userTodos.length, todo)

  list = (res) ->
    return unless todos?
    userId = res.message.user.id
    userTodos = todos[userId] ? []
    return if userTodos.length is 0
    res.send userTodos.map((todo, i) -> format(i + 1, todo)).join '\n'

  done = (res) ->
    return unless todos?
    todoNo = res.match[1]
    return list(res) unless todoNo?
    userId = res.message.user.id
    userTodos = todos[userId] ? []
    return if userTodos.length is 0
    index = parseInt(todoNo, 10) - 1
    todo = userTodos[index]
    userTodos.splice(index, 1)
    res.robot.brain.save()
    res.send format(index + 1, todo) if todo?

  robot.respond /todo add (.+)$/i, add
  robot.respond /todo li?st?$/i, list
  robot.respond /todo done(?:\s+(\d+))?$/i, done
