# Allow anyone? to remove users
Meteor.users.allow
  remove: (userId, user) ->
    Meteor.user().emails[0].address == ADMIN_EMAIL
