# This class represents an error to be displayed.
# It remembers all of the instances so they can be clear with clearAll().
# This allows you to clear errors on keyup events, for example.
class @PageError
  constructor: () ->
    @_error = ReactiveVar('')
  @_allErrors: []
  get: () -> @_error.get()
  set: (msg) ->
    @_error.set(msg)
    PageError._allErrors.push(@_error)
    false
  @clearAll: () ->
    e.set('') for e in PageError._allErrors
    PageError._allErrors = []
    false
