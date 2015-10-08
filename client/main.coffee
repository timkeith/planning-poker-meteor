log = util.log

Template.mainRoot.helpers
  newMainPage: () -> new MainPage()

class MainPage
  constructor: () -> initTemplate(@)
  FindById: () -> new FindById()
  FindByMod: () -> new FindByMod()
  MyGames: () -> new MyGames()
  events:
    'click #create': (e) -> Router.go('/create')
    'keyup input': (e) -> if e.keyCode != 13 then PageError.clearAll()

class FindById
  constructor: () ->
    initTemplate(@)
    @error = new PageError()
  events:
    'submit form': (e, t) ->
      gameId = e.target.gameId.value
      game = Games.findOne gameId
      if not game?
        return @error.set "There is no session with id '#{gameId}'"
      Router.go "/play/#{gameId}"

class FindByMod
  constructor: () ->
    initTemplate(@)
    @error = new PageError()
    @_games = new ReactiveVar([])
  ShowGames: () -> new ShowGames('', @_games.get())
  events:
    'submit form': (e,t) ->
      @_games.set([])
      email = e.target.email.value
      u = Meteor.users.findOne 'emails.0.address': email
      if not u?
        return @error.set "There is no user with email address '#{email}'"
      g = Games.find({mod: u._id, state: {$ne: GameStates.Done}}, {sort: {createdAt: -1}}).fetch()
      @_games.set(g)
      if g.length == 0
        return @error.set "There are no sessions moderated by #{email}"

class MyGames
  constructor: () -> initTemplate(@)
  ShowGames: (kind) ->
    if kind == 'done'
      new ShowGames('Completed sessions:', @_findGames(GameStates.Done))
    else if kind == 'notdone'
      new ShowGames('None', @_findGames($ne: GameStates.Done))
    else
      throw new Meteor.Error("Bad kind of games: #{kind}")
  _findGames: (state) ->
    Games.find({mod: Meteor.userId(), state: state}, {sort: {createdAt: -1}}).fetch()

class ShowGames
  constructor: (@title, @games) -> initTemplate(@)
  ShowGame: (game) -> new ShowGame(game)

class ShowGame
  constructor: (data) ->
    initTemplate(@)
    _.extend(@, data)
  myGame: () -> @mod == Meteor.userId()
  isDone: () -> @state == GameStates.Done
  estimatedCount: () -> _.reduce(@tasks, ((memo, task) -> memo + +(task.estimate > 0)), 0)
  events:
    'click .play': (e, t) -> Router.go "/play/#{@_id}"
    'click .delete': (e, t) -> new Game(@).delete()
    'click .complete': (e, t) -> new Game(@).setDone()
