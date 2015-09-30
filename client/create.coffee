log = util.log

class DoCreateData
  constructor: () ->
    @_tasks = new SessionVar('tasks')
    @_tasks.set([])
    @_importing = new ReactiveVar(false)
    @_error = new ReactiveVar('')
  error:        ()    -> @_error.get()
  setError:     (msg) -> @_error.set(msg)
  importing:    ()    -> @_importing.get()
  setImporting: (b)   -> @_importing.set(b)
  tasks:        ()    -> @_tasks.get()
  nextTask:     ()    -> @_tasks.get().length + 1
  defaultName:  ()    -> new Date().toISOString().replace(/T.*/, '-') + User.name()
  username:     ()    -> Meteor.user()?.username
  email:        ()    -> Meteor.user()?.emails?[0]?.address

  addTask: (desc) ->
    if desc
      t = @tasks()
      t.push {desc: desc, votes: {}}
      @_tasks.set(t)
  removeTask: (num) ->
    t = @tasks()
    t.splice(num-1, 1)
    @_tasks.set(t)
  createGame: (name) ->
    tasks = []
    for task in @tasks()
      delete task.num
      tasks.push(task)
    @_tasks.set([])
    id = @_genId(name)
    game = new Game(_id: id, name: name, tasks: tasks)
    game.insert()
    return id
  _genId: (name) ->
    base = name.replace /[^-0-9a-zA-Z$.!*'()]+/g, '_'
    n = 0
    loop
      id = base + if n then '.' + n else ''
      g = Games.findOne id
      if not g?
        return id
      n += 1

template
  name: 'create'
  helpers:
    doCreateData: () -> new DoCreateData()

template
  name: 'doCreate'
  events:
    'click a#import': (e) -> @setImporting(true)
    'click a#delete': (e) -> @parent.removeTask(@num)
    'submit form#createGame': (e, t) ->
      name = e.target.name.value
      # check for a task desc that hasn't been added
      @addTask(t.find('form.addTask input[name="desc"]')?.value)
      Router.go '/play/' + @createGame(name)

template
  name: 'addTask'
  events:
    'click a#add': (e, t) ->
      input = t.$('input')
      @addTask(input.val())
      input.val('')
      input.focus()
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
      log 'import from', userRepo
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
