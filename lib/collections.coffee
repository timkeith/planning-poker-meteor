@Games = new Mongo.Collection 'games'

if Meteor.isServer
  Meteor.publish 'users', () -> Meteor.users.find()
  Meteor.publish 'games', () -> Games.find()

if Meteor.isClient
  Meteor.subscribe 'users'
  Meteor.subscribe 'games'

if Meteor.isClient
  UI.registerHelper 'asTask', (arr, options) ->
    parentContext = @
    if !Array.isArray(arr)
      try
        arr = arr.fetch()
      catch e
        console.log("Not an array or collection", arr)
        return []
    return (_.extend(item, num: index+1) for item, index in arr)

# Possible states a game can be in
@GameStates =
  Done:    'done'
  Showing: 'showing'
  Voting:  'voting'

# Possible states a player within a game can be in
@PlayerStates =
  Waiting: 'waiting'  # this is the default
  Playing: 'playing'
  Joining: 'joining'

class @Game
  # takes game data from db
  constructor: (data) ->
    _.extend @, data
    for prop in ['_id', 'name']
      if not @[prop]?
        throw new Meteor.Error "Required field in Game: #{prop}"

  debugString: () -> JSON.stringify(@, null, 2)

  # access and set game state
  isMod:      () -> @mod == User.id()
  isDone:     () -> @state == GameStates.Done
  setDone:    () -> @_setState GameStates.Done
  isShowing:  () -> @state == GameStates.Showing
  setShowing: () -> @_setState GameStates.Showing
  isVoting:   () -> @state == GameStates.Voting
  setVoting:  () -> @_setState GameStates.Voting

  # access and set player state
  iAmPlaying: () -> @_myState() == PlayerStates.Playing
  iAmJoining: () -> @_myState() == PlayerStates.Joining
  iAmWaiting: () -> @_myState() == PlayerStates.Waiting
  _myState: () -> @players?[User.id()]?.state || PlayerStates.Waiting
  getPlayersInState: (state) ->
    (_.extend(player, id: id) for id, player of @players when player.state == state)

  currTask: () -> @tasks[@curr-1]

  # array of {player, vote} for votes on this task, sorted by vote
  votes: (task) ->
    votes = task.votes
    ({player: @players[id], vote: votes[id]} \
      for id in Object.keys(votes).sort((a, b) -> votes[a] - votes[b]))

  insert: () ->
    Meteor.call 'createGame', @_id, @name, @tasks, (error, result) ->
      if error? then throw new Meteor.Error("Error creating planning session: #{error}")
  delete: () ->
    Meteor.call 'deleteGame', @_id
  _setState: (state) ->
    Meteor.call 'setState', @, state
  addPlayer: () ->
    Meteor.call 'addPlayer', @
  setPlayerState: (id, state) ->
    Meteor.call 'setPlayerState', @, id, state
  setCurr: (curr) ->
    Meteor.call 'setCurr', @, curr
  setCurrProp: (key, value) ->
    Meteor.call 'setCurrProp', @, key, value
  setVote: (choice) ->
    Meteor.call 'setVote', @, choice


Meteor.methods

  createGame: (id, name, tasks) ->
    checkAuth Meteor.userId()?, 'Must be logged in to create game'
    Games.insert
      _id:       id
      name:      name
      mod:       User.id()
      createdAt: new Date()
      tasks:     tasks
      players:   {}
    game = Games.findOne id
    Meteor.call 'addPlayer', game
    Meteor.call 'setPlayerState', game, User.id(), PlayerStates.Playing

  deleteGame: (id) ->
    checkAuth Meteor.userId()?, 'Must be logged in to delete game'
    game = Games.findOne id
    if not game?
      util.log "No game found with id '#{id}'"
      return
    if Meteor.user().emails[0].address != ADMIN_EMAIL
      checkMod game, 'delete this session'
    Games.remove id

  # Add self as joining
  addPlayer: (game) ->
    updateGame game._id, "players.#{User.id()}",
      { username: User.name(), email: User.email(), state: PlayerStates.Joining }

  setCurr: (game, curr) ->
    checkMod game
    updateGame game._id, 'curr', curr

  setState: (game, state) ->
    checkMod game
    updateGame game._id, 'state', state

  # Set a property in the current task
  setCurrProp: (game, key, value) ->
    checkMod game
    updateGame game._id, "tasks.#{game.curr-1}.#{key}", value

  # Set the current user's vote on the current task.
  setVote: (game, choice) ->
    checkAuth game.players[User.id()]?.state == PlayerStates.Playing, 'User must be playing to vote'
    updateGame game._id, "tasks.#{game.curr-1}.votes.#{User.id()}", choice

  setPlayerState: (game, playerId, state) ->
    if User.id() != game.mod
      if User.id() != playerId
        util.log "Only moderator and user can change user's state"
        throw new Meteor.Error('not-authorized')
      if state == PlayerStates.Playing
        util.log "Only moderator can change user's state to #{PlayerStates.Playing}"
        throw new Meteor.Error('not-authorized')
    updateGame game._id, "players.#{playerId}.state", state


# Helper for updating a property in the game.  Caller must check that user is authorized.
updateGame = (id, key, value) ->
  Games.update id, util.$set(key, value)

# Verify that current user is moderator of game
checkMod = (game, action) ->
  checkAuth game.mod == User.id(),
    "Only the moderator (#{game.players[game.mod].email}) can #{action}"

# Verify that condition is true; log msg if not
checkAuth = (cond, msg) ->
  if not cond
    if msg? then console.log msg
    throw new Meteor.Error('not-authorized')
