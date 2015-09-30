Meteor.startup () ->
  # Note: process.env.IS_MIRROR is not set as expected
  if Meteor.users.find().count() == 0
    Accounts.createUser username: 'User 1', email: 'user1@example.com', password: 'passwd1'
    Accounts.createUser username: 'User 2', email: 'user2@example.com', password: 'passwd2'
