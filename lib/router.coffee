Router.route '/', 'main'

Router.route '/create'

Router.route '/admin'

Router.route '/play/:gameId',
  subscriptions: () -> [Meteor.subscribe 'games']
  action: () ->
    game = Games.findOne @params.gameId
    if not game?
      util.log "No game with id #{@params.gameId}"
      @render 'badGameId', data: () -> id: @params.gameId
      return
    game.debug = true if @params.query.debug
    @render 'play', data: () -> new Game(game)

Router.onBeforeAction () ->
  if !Meteor.userId()
    @render 'login'
  else
    @next()
