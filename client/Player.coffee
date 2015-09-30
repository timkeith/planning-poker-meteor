# Utility functions operating on players
#@Player =
#  # No args: current user's state; 1 arg: that user's state; 2 args: set that user's state
#  state: (id, state) ->
#    if not id?
#      return Game.get().players[Meteor.userId()]?.state || 'waiting'
#    else if not state?
#      return Game.get().players[id]?.state || 'waiting'
#    else
#      Game.update "players.#{id}.state", state
#      return state
#
#  # All players in given state
#  inState: (state) ->
#    (player for player in Game.players() when player.state == state)
#    #(_.extend(player, id: id) for id, player of Game.get().players when player.state == state)

