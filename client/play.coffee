log = util.log

CHOICES = ['?', '1', '2', '3', '5', '8', '12', '20', '30', '50']
NO_CHOICE = '?'
# Convert a value in CHOICES to a number
choiceNum = (choice) -> if not choice? || choice == NO_CHOICE then 0 else +choice

Template.playRoot.helpers
  newPlay: (gameId, debug) -> new Play(gameId, debug)

class Play
  constructor: (@gameId, @debug) ->
    initTemplate('Play', @)
    g = Games.findOne @gameId
    if g?
      @game = new Game(g)
  ShowTasks: () -> new ShowTasks(@game)
  Estimators: () -> new Estimators(@game)
  Estimating: () -> new Estimating(@game, @game.currTask())
  events:
    'click #join':    (e) -> @game.addPlayer()
    'click #unjoin':  (e) -> @game.setPlayerState(User.id(), PlayerStates.Waiting)
    'click #done':    (e) -> @game.setDone()
    'click #notdone': (e) -> @game.setShowing()
    'click #delete':  (e) ->
      @game.delete()
      Router.go('/')

class Estimators
  constructor: (@game) -> initTemplate('Estimators', @)
  playing: () ->
    (_.extend(player, isMod: player.id == @game.mod, isMe: player.id == User.id()) \
      for player in @game.getPlayersInState(PlayerStates.Playing))
  joining: () -> @game.getPlayersInState(PlayerStates.Joining)
  events:  # context has game and player
    'click #allow':  (e) -> @game.setPlayerState(@player.id, PlayerStates.Playing)
    'click #reject': (e) -> @game.setPlayerState(@player.id, PlayerStates.Waiting)
    'click #leave':  (e) -> @game.setPlayerState(@player.id, PlayerStates.Waiting)

class Estimating
  constructor: (@game, @task) -> initTemplate('Estimating', @)
  ShowVotes: () -> new ShowVotes(@game, @task)
  ShowVoted: () -> new ShowVoted(@game, @task)
  Choice: (choice) -> new Choice(@game, @task, choice)
  choices: () -> CHOICES

class Choice
  constructor: (@game, @task, @choice) -> initTemplate('Choice', @)
  disabled: () -> @game.isShowing() && !@game.isMod()
  selected: () ->
    choice = choiceNum @choice
    selection = if @game.isShowing() then @task.proposed else @task.votes[User.id()]
    return selection == choice
  events:
    'click button.choice': (e) ->
      choice = choiceNum @choice
      if @game.isShowing()
        @game.setCurrProp 'proposed', choice
      else
        @game.setVote choice

class ShowVoted
  constructor: (@game, @task) -> initTemplate('ShowVoted', @)
  players: () ->  # {name:..., voted:...} sorted by name
    sorted = _(@game.players).sortBy((player) -> player.username.toLowerCase())
    ({ name: player.username, voted: @task.votes[player.id] } for player in sorted)
  events:
    'click #show': (e) ->
      @game.setCurrProp 'proposed', @_middleVote()
      @game.setShowing()
  _middleVote: () ->  # choice closest to the middle of the votes
    sorted = _.reject(_.values(@task.votes).sort(), (x) -> x == 0)
    mid = Math.floor(sorted.length / 2)
    if sorted.length == 0
      return 0
    else if sorted.length % 2 == 1
      return sorted[mid]  # use the middle choice
    else
      # use the choice closest to the middle of these two
      lo = +CHOICES.indexOf sorted[mid-1].toString()
      hi = +CHOICES.indexOf sorted[mid].toString()
      return +CHOICES[Math.ceil((lo + hi) / 2)]

class ShowVotes
  constructor: (@game, @task) -> initTemplate('ShowVotes', @)
  votes: () -> @game.votes(@task)
  events:
    'click #revote': (e) -> @game.setVoting()
    'click #save': (e) ->
      @game.setCurrProp 'estimate', choiceNum(@task.proposed)
      @game.setCurrProp 'proposed', undefined
      curr = @game.curr
      loop
        curr += 1
        if curr > @game.tasks.length
          curr = 0
          break
        break if not @game.tasks[curr-1].estimate
      @game.setCurr curr
      @game.setVoting()

class ShowTasks
  constructor: (@game) -> initTemplate('ShowTasks', @)
  ShowTask: (task) -> new ShowTask(task, @game)
  tasks: () -> _.extend(task, num: index+1) for task, index in @game.tasks

class ShowTask
  constructor: (@task, @game) -> initTemplate('ShowTask', @)
  estimate: () -> @task.estimate || '-'
  isCurr: () -> @task.num == @game.curr && !@game.isDone()
  canSelectTask: () -> @game.isMod() && !@game.isDone()
  events:
    'click .desc': (e) ->
      @game.setCurr @task.num
      @game.setVoting()
