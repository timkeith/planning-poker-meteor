class @SessionVar
  constructor: (@name, value) -> @set value
  toString: () -> "#{@name}=#{get()}"
  get: () -> Session.get @name
  set: (value) -> Session.set @name, value
  clear: () -> Session.set @name, undefined
