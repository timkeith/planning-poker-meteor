# Utility functions on current user
@User =
  id:    () -> Meteor.userId()
  name:  () -> Meteor.user()?.username || User.email()?.replace /\@.*/, ''
  email: () -> Meteor.user()?.emails?[0].address
