# for tests
console.log 't1'
if process.env.IS_MIRROR
  console.log 't2'
  Meteor.methods
    loadFixtures: () ->
      console.log 'Loading default fixtures'
      # TODO: add your fixtures here
      Accounts.createUser email: 'email@example.com', password: '123456'
      console.log 'Finished loading default fixtures'

    clearDB: () ->
      console.log 'Clear DB'
      collectionsRemoved = 0
      db = Meteor.users.find()._mongo.db
      db.collections (err, collections) ->
        appCollections = _.reject collections, (col) ->
          col.collectionName.indexOf('velocity') == 0 || col.collectionName == 'system.indexes'
        _.each appCollections, (appCollection) ->
          appCollection.remove (e) ->
            if e
              console.error('Failed removing collection', e)
            else
              collectionsRemoved++
              console.log 'Removed collection'
              if appCollections.length == collectionsRemoved
                console.log 'Finished resetting database'
      console.log 'Finished clearing'
