log = util.log

# Base class for data context with error field
class WithError
  constructor: () ->
    @error = ReactiveVar('')
  @allErrors: []
  getError: () -> @error.get()
  setError: (msg) ->
    @error.set(msg)
    WithError.allErrors.push(@error)
    false
  @clearErrors: () ->
    e.set('') for e in WithError.allErrors
    WithError.allErrors = []
    false

class FindByIdData extends WithError
  constructor: () -> super()

class FindByModData extends WithError
  constructor: () ->
    super()
    @_games = new ReactiveVar([])
  games: () -> @_games.get()
  setGames: (g) -> @_games.set(g)

class MyGamesData
  gamesNotDone: () -> @_findGames($ne: GameStates.Done)
  gamesDone: () -> @_findGames(GameStates.Done)
  _findGames: (state) ->
    Games.find({mod: Meteor.userId(), state: state}, {sort: {createdAt: -1}}).fetch()

template
  name: 'main'
  helpers:
    findByIdData: () -> new FindByIdData()
    findByModData: () -> new FindByModData()
    myGamesData: () -> new MyGamesData()
  events:
    'click #create': (e) -> Router.go('/create')
    'keyup input': (e) -> if e.keyCode != 13 then WithError.clearErrors()

template
  name: 'findById'
  events:
    'submit form': (e, t) ->
      gameId = e.target.gameId.value
      if not gameId
        return @setError "The session id is required"
      game = Games.findOne gameId
      if not game?
        return @setError "There is no session with id '#{gameId}'"
      Router.go "/play/#{gameId}"


template
  name: 'findByMod'
  events:
    'submit form': (e,t) ->
      email = e.target.email.value
      if not email?
        return @setError "The email address is required"
      u = Meteor.users.findOne 'emails.0.address': email
      if not u?
        return @setError "There is no user with email address '#{email}'"
      g = Games.find({mod: u._id, state: {$ne: GameStates.Done}}, {sort: {createdAt: -1}})
      @setGames(g.fetch())
      if @games().length == 0
        return @setError "There are no sessions moderated by #{email}"

template
  name: 'myGames'

# Display the matching games
template
  name: 'showGames'
  helpers:
    estimatedCount: (game) ->
      n = 0
      n += 1 for task in @tasks when task.estimate
      return n
  events:
    'click .play': (e, t) -> Router.go "/play/#{@_id}"
    'click .delete': (e, t) -> new Game(@).delete()
    'click .complete': (e, t) -> new Game(@).setDone()
