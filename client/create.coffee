log = util.log

Template.createRoot.helpers
  newCreateForm: () -> new CreateForm()

class CreateForm
  constructor: () ->
    initTemplate(@)
    @_tasks = new Tasks()
    @_name = new ReactiveVar()
    @_gameId = new ReactiveVar()
    @_setName(@defaultName())
  TaskList: () -> new TaskList(@_tasks)
  defaultName: () -> new Date().toISOString().replace(/T.*/, '-') + User.name()
  url: () -> window.location.origin + @_path()
  anyTasks: () -> @_tasks.any()
  createGame: () ->
    game = new Game(_id: @_gameId.get(), name: @_name.get(), tasks: @_tasks.getAndClear())
    game.insert()
  events:
    'keyup form#createGame input[name="name"]': (e, t) -> @_setName(e.target.value)
    'focusout form#createGame input[name="name"]': (e, t) -> @_setName(e.target.value)
    'submit form#createGame': (e, t) ->
      @createGame()
      Router.go @_path()
  _setName: (name) -> @_name.set(name); @_gameId.set(@_genId(name))
  _path: () -> "/play/#{@_gameId.get()}"
  _genId: (name) ->
    base = name.replace /[^-0-9a-zA-Z$.!*'()]+/g, '_'
    for n in [1..100]
      id = base + (if n > 1 then '.' + n else '')
      g = Games.findOne id
      if not g? then return id
    throw new Meteor.Error("Failed to generate id for name #{name}")

class TaskList
  constructor: (@tasks) -> initTemplate(@)
  ImportForm: () -> new ImportForm(@tasks)
  AddTaskForm: () -> new AddTaskForm(@tasks)
  events:
    'click td.delete a': (e) -> @parent.tasks.remove(@num)
    'keyup form.addTask input[name="desc"]': (e, t) -> @tasks.setMaybe(e.target.value)

class AddTaskForm
  constructor: (@tasks) -> initTemplate(@)
  events:
    'submit form.addTask': (e) ->
      @tasks.add(e.target.desc.value)
      e.target.desc.value = ''

class ImportForm
  constructor: (@tasks) ->
    initTemplate(@)
    @_error = new ReactiveVar('')
    @_importing = new ReactiveVar(false)
  error:        ()    -> @_error.get()
  setError:     (msg) -> @_error.set(msg)
  importing:    ()    -> @_importing.get()
  setImporting: (b)   -> @_importing.set(b)
  events:
    'click a#import': (e) -> @setImporting(true)
    'focusout form': (e) -> @setError ''
    'submit form#import': (e) ->
      userRepo = e.target.from.value
      userRepo = userRepo.replace(/^https?:/, '')
      userRepo = userRepo.replace(/^\/*github.com/, '')
      userRepo = userRepo.replace(/^\/*repos/, '')
      userRepo = userRepo.replace(/^\/+/, '')
      url = "https://api.github.com/repos/#{userRepo}/issues"
      self = @
      HTTP.get url, (err, result) ->
        if err
          if result.data?.message?
            err = result.data.message
          self.setError "Error getting #{url}: #{err}"
        else
          issues = result.data
          if issues.length == 0
            self.setError "No issues found at #{url}"
          else
            self.setImporting false
            for issue in issues
              self.tasks.add "[#{issue.user.login}] #{issue.title}"


# Manage the current list of tasks, stored in a session variable
class Tasks
  constructor: () ->
    @_tasks = new SessionVar('tasks', [])
    @_maybe = new ReactiveVar('')  # desc that has been typed but not added
  nextNum: () -> @get().length + 1
  any: () -> @get().length > 0 || @_maybe.get() != ''
  get: () -> @_tasks.get()
  withNum: () -> _.extend(task, num: index+1) for task, index in @get()
  getAndClear: () ->
    @add(@_maybe.get())
    t = @get()
    @_set([])
    return t
  add: (desc) ->
    if desc
      t = @get()
      t.push {desc: desc, votes: {}}
      @_set(t)
    @_maybe.set('')
  setMaybe: (desc) -> @_maybe.set(desc)
  remove: (num) ->
    t = @get()
    t.splice(num-1, 1)
    @_set(t)
  _set: (t) -> @_tasks.set(t)

