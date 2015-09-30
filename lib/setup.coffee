@ADMIN_EMAIL = 'tim@tkeith.com'

# create users for testing
if Meteor.isServer
  Meteor.startup () ->
    if Meteor.users.find().count() == 0
      Accounts.createUser username: 'User1', email: 'user1@example.com', password: 'user1'
      Accounts.createUser username: 'User2', email: 'user2@example.com', password: 'user2'
