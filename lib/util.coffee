@util =
  log: (x, y) ->
    if y?
      console.log x, ': ', y
    else
      console.log x

  extend: (obj, props) ->
    for key, val of props
      obj[key] = val
    return obj

  parent: () -> Template.parentData(1)
  self: () -> Template.parentData(0)

  # Create $set object for setting deeply nested field in Mongo
  $set: (key, value) ->
    if value == undefined
      log "delete #{key}"
      set = $unset: {}
      set.$unset[key] = ''
    else
      log "set #{key} to #{JSON.stringify(value)}"
      set = $set: {}
      set.$set[key] = value
    return set

class @SessionVar
  constructor: (@name) ->
  toString: () -> "#{@name}=#{get()}"
  get: () -> Session.get @name
  set: (value) -> Session.set @name, value
  clear: () -> Session.set @name, undefined

# Helper method to allow template code to be delared together in a block
# name, helpers, events, and eventsWithDefault are provided as named parameters
# Methods in events are treated like they always return false (i.e. preventDefault).
@template = (map) ->
  name = map.name
  if not name?
    throw new Meteor.Error('name is required')
  for key of map
    if key != 'name' && key != 'helpers' && key != 'events' && key != 'eventsWithDefault'
      throw new Meteor.Error("Unknown key: #{key}")

  Template[name].helpers map.helpers
  #Template[name].events map.events
  events = {}
  for key, fn of map.eventsWithDefault
    events[key] = fn
  for key, fn of map.events
    do (key, fn) ->
      events[key] = (e, t) -> fn.bind(@)(e, t); false
  Template[name].events events


# Conditional expression
UI.registerHelper 'cond', (test, a, b) -> if test then a else b

UI.registerHelper 'stringify', (x) -> JSON.stringify(x)

UI.registerHelper 'isEmpty', (x) -> _.isEmpty(x)

# Use withExtras to add _parent, _index, _first, _last into context
# Use withExtras parent='foo' to include foo in the context, also returning the parent
# E.g. each withExtras tasks parent='game'
# Problem: can't use just _parent or game, must be a function: _parent(), game()
# Otherwise problems with circular refs
UI.registerHelper 'withExtras', (arr, options) ->
  parentContext = @
  if !Array.isArray(arr)
    try
      arr = arr.fetch()
    catch e
      console.log("Error in withExtras: perhaps you aren't sending in a collection or array.")
      return []
  return ((
    x = _.extend(item,
      _parent: () -> parentContext
      _index:  index
      _first:  index == 0
      _last:   index == arr.length-1)
    if options.hash?.parent?
      x[options.hash?.parent] = () -> parentContext
    x
  ) for item, index in arr)

log = util.log
