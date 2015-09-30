log = util.log

CHOICES = ['?', '1', '2', '3', '5', '8', '12', '20', '30', '50']
NO_CHOICE = '?'
# Convert a value in CHOICES to a number
choiceNum = (choice) -> if not choice? || choice == NO_CHOICE then 0 else +choice

UI.registerHelper 'userId', (context, options) -> User.id()

template
  name: 'play'
  events:  # context is game
    'click #join':    (e) -> @addPlayer()
    'click #unjoin':  (e) -> @setWaiting(User.id())
    'click #done':    (e) -> @setDone()
    'click #notdone': (e) -> @setShowing()

template
  name: 'estimators'
  events:  # context has game and player
    'click #allow':  (e) -> @game.setPlaying(@player.id)
    'click #reject': (e) -> @game.setWaiting(@player.id)
    'click #leave':  (e) -> @game.setWaiting(@player.id)

# Context has game and task (the one being estimated)
template
  name: 'estimating'
  helpers:
    choices: () -> CHOICES
    isDisabled: () -> @game.isShowing() && !@game.isMod()
    getClass: () ->
      choice = choiceNum @choice
      selected = if @game.isShowing() then @task.proposed else @task.votes[User.id()]
      return selected == choice && 'active'
  events:
    'click button.choice': (e) ->
      choice = choiceNum @choice
      if @game.isShowing()
        @game.setCurrProp 'proposed', choice
      else
        @game.setVote choice

# Context has game and task (the one being estimated)
template
  name: 'showVoted'
  helpers:
    players: () ->  # sort by username
      _(@game.players).sortBy((player) -> player.username.toLowerCase())
    getClass: () -> !@task.votes[@player.id] && 'not-voted'
  events:
    'click #show': (e) ->
      proposed = middleVote(@game.votes(@task))
      @game.setCurrProp 'proposed', proposed
      @game.setShowing()


# Context has game and task (the one being estimated)
template
  name: 'showVotes'
  helpers:
    votes: () -> @game.votes(@task)
  events:
    'click #revote': (e) -> @game.setVoting()
    'click #save': (e) ->
      estimate = choiceNum @task.proposed
      @game.setCurrProp 'estimate', estimate
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

# Context has game and task and index
template
  name: 'showTask'
  helpers:
    estimate: () -> @task.estimate || '-'
    getClass: () -> @task.num == @game.curr && !@game.isDone() && 'curr'
    canSelectTask: () -> @game.isMod() && !@game.isDone()
  events:
    'click .task': (e) ->
      @game.setCurr @task.num
      @game.setVoting()


## Utilities

# Return the vote closest to the middle
# sorted is { player: , vote: } sorted by vote
middleVote = (sorted) ->
  sorted = (x for x in sorted when x.vote != 0)
  mid = Math.floor(sorted.length / 2)
  if sorted.length == 0
    return 0
  else if sorted.length % 2 == 1
    return sorted[mid].vote  # use the middle choice
  else
    # use the choice closest to the middle of these two
    lo = +CHOICES.indexOf sorted[mid-1].vote.toString()
    hi = +CHOICES.indexOf sorted[mid].vote.toString()
    return +CHOICES[Math.ceil((lo + hi) / 2)]
