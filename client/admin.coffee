Template.adminRoot.helpers
  newAdmin: () -> new Admin()

class Admin
  constructor: () -> initTemplate(@)
  UsersList: () -> new UsersList(@isAdmin())
  SessionsList: () -> new SessionsList(@isAdmin())
  isAdmin: () -> User.email() == ADMIN_EMAIL

class UsersList
  constructor: (@isAdmin) -> initTemplate(@)
  users: () -> Meteor.users.find()
  email: (user) -> user.emails?[0]?.address
  events:
    'click .deleteUser': () -> Meteor.users.remove _id: @_id

class SessionsList
  constructor: (@isAdmin) -> initTemplate(@)
  games: () -> Games.find()
  modEmail: (game) -> game.players[game.mod].email
  events:
    'click .deleteGame': () -> new Game(@).delete()
    'click .game': () -> Router.go "/play/#{@_id}"
