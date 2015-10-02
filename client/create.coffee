log = util.log

class DoCreateData
  constructor: () ->
    @_tasks = new SessionVar('tasks', [])
    @_importing = new ReactiveVar(false)
    @_error = new ReactiveVar('')
    @_name = new ReactiveVar()
    @_gameId = new ReactiveVar()
    @_setName(@defaultName())
  error:        ()    -> @_error.get()
  setError:     (msg) -> @_error.set(msg)
  importing:    ()    -> @_importing.get()
  setImporting: (b)   -> @_importing.set(b)
  tasks:        ()    -> @_tasks.get()
  nextTask:     ()    -> @_tasks.get().length + 1
  defaultName:  ()    -> new Date().toISOString().replace(/T.*/, '-') + User.name()
  username:     ()    -> Meteor.user()?.username
  email:        ()    -> Meteor.user()?.emails?[0]?.address
  _setName:     (name) -> @_name.set(name); @_gameId.set(@_genId(name))
  path: () -> '/play/' + @_gameId.get()
  url: () -> window.location.origin + @path()
  addTask: (desc) ->
    if desc
      t = @tasks()
      t.push {desc: desc, votes: {}}
      @_tasks.set(t)
  removeTask: (num) ->
    t = @tasks()
    t.splice(num-1, 1)
    @_tasks.set(t)
  createGame: () ->
    tasks = (_.omit(task, 'num') for task in @tasks())
    @_tasks.set([])
    game = new Game(_id: @_gameId.get(), name: @_name.get(), tasks: tasks)
    game.insert()
  _genId: (name) ->
    base = name.replace /[^-0-9a-zA-Z$.!*'()]+/g, '_'
    for n in [1..100]
      id = base + (if n > 1 then '.' + n else '')
      g = Games.findOne id
      if not g? then return id
    throw new Meteor.Error("Failed to generate id for name #{name}")

template
  name: 'create'
  helpers:
    doCreateData: () -> new DoCreateData()

template
  name: 'doCreate'
  events:
    'click a#import': (e) -> @setImporting(true)
    'click td.delete a': (e) -> @parent.removeTask(@num)
    'keyup form#createGame input[name="name"]': (e, t) -> @_setName(e.target.value)
    'focusout form#createGame input[name="name"]': (e, t) -> @_setName(e.target.value)
    'submit form#createGame': (e, t) ->
      # check for a task desc that hasn't been added
      @addTask(t.find('form.addTask input[name="desc"]')?.value)
      @createGame()
      Router.go @path()

template
  name: 'addTask'
  events:
    'submit form.addTask': (e) ->
      desc = e.target.desc.value
      e.target.desc.value = ''
      @addTask(desc)

template
  name: 'importForm'
  events:
    'keyup input': (e) -> @setError ''
    'submit form#import': (e) ->
      userRepo = e.target.from.value
      userRepo = userRepo.replace(/^https?:/, '')
      userRepo = userRepo.replace(/^\/*github.com/, '')
      userRepo = userRepo.replace(/^\/*repos/, '')
      userRepo = userRepo.replace(/^\/+/, '')
      url = "https://api.github.com/repos/#{userRepo}/issues"
      context = @
      HTTP.get url, (err, result) ->
        if err
          if result.data?.message?
            err = result.data.message
          context.setError "Error getting #{url}: #{err}"
        else
          context.setImporting false
          for issue in result.data
            context.addTask "[#{issue.user.login}] #{issue.title}"
