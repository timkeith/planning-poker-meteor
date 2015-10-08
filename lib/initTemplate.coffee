###
Initialize template classes with:
class FooTemplate
  constructor: (...) ->
    initTemplate('FooTemplate', @)
  helper1: () -> ...
  onRendered/onCreated/onDestroyed: () -> ...
  events: ...
  eventsAllowDefault: ...
###
@initTemplate = (name, t) ->
  proto = t.__proto__
  if proto._did_template_?
    return  # already registered this one
  proto._did_template_ = true
  util.log 'register template', name
  template = Template[name]
  if not template?
    throw new Meteor.Error("No templated named #{name} defined in html")
  # each of these may be a function or array of functions
  for key in ['onRendered', 'onCreated', 'onDestroyed']
    val = proto[key]
    if not val?
    else if _.isFunction(val)
      template[key] val
    else if _.isArray(val)
      for fn in val
        template[key] fn
    else
      throw new Meteor.Error("#{key} must be function or array of functions")
  events = proto.eventsAllowDefault || {}
  for key, fn of proto.events
    do(key, fn) ->
      events[key] = (x, y) -> fn.bind(@)(x, y); false
  template.events events
