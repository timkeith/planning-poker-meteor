cond = (test, a, b) ->
  if test
    a
  else if b instanceof Spacebars.kw  # indicates no 3rd arg was supplied
    ''
  else
    b

# Conditional expression: cond test trueValue falseValue
UI.registerHelper 'cond', cond
# Conditio0nal equality expression: condEq x y equalValue notEqualValue
UI.registerHelper 'condEq', (x, y, a, b) -> cond(x == y, a, b)

@stringify = (x) -> JSON.stringify(x)
UI.registerHelper 'stringify', stringify

UI.registerHelper 'isEmpty', (x) -> _.isEmpty(x)

UI.registerHelper 'currentUserEmail', () -> Meteor.user()?.emails?[0]?.address
