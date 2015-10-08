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
      util.log "delete #{key}"
      set = $unset: {}
      set.$unset[key] = ''
    else
      util.log "set #{key} to #{JSON.stringify(value)}"
      set = $set: {}
      set.$set[key] = value
    return set
