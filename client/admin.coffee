template
  name: 'admin'
  helpers:
    isAdmin: () -> Meteor.user().emails[0].address == ADMIN_EMAIL
    games: () -> Games.find()
    users: () -> Meteor.users.find()
    email: () -> @emails?[0]?.address
    modEmail: () -> @players[@mod].email
  events:
    'click #deleteGame': () -> new Game(@).delete()
    'click #deleteUser': () -> Meteor.users.remove _id: @_id

