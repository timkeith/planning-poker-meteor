Router.route '/', 'mainRoot'
Router.route '/create', 'createRoot'
Router.route '/admin', 'adminRoot'

Router.route '/play/:gameId',
  waitOn: () ->
    Meteor.subscribe('games')
  action: () ->
    @render 'playRoot', data: () -> gameId: @params.gameId, debug: @params.query.debug

Router.onBeforeAction () ->
  if !Meteor.userId()
    @render 'login'
  else
    @next()
