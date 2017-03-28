Spine = @Spine or require('spine')
$     = Spine.$

class Firebase extends Spine.Controller
  constructor: (params) ->
    super

  initFirebase: (config) ->
    ctr = @
    firebase.initializeApp(config)
    firebase.auth().onAuthStateChanged ((userParams) ->
      unless userParams
        ctr.trigger('firebaseAuthOut')
      else
        userParams.getToken().then (accessToken) ->
          userParams['accessToken'] = accessToken
          ctr.appUser = new User(userParams)
          ctr.trigger('firebaseAuthIn')
      ctr.trigger('firebaseAuthToggle')
    ), (error) ->
      ctr.log('firebase auth error', error)

  @signOut: ->
    unless firebase.auth().currentUser
      return
    s_deferred = $.Deferred()
    promise  = s_deferred.promise()
    firebase.auth().signOut().then =>
      if @appUser then delete @appUser
      s_deferred.resolve()
    promise

  @deleteUser: ->
    unless firebase.auth().currentUser
      return
    d_deferred = $.Deferred()
    promise  = d_deferred.promise()
    firebase.auth().currentUser.delete()
    .then =>
      if @appUser then delete @appUser
      d_deferred.resolve()
    .catch (error) ->
      d_deferred.reject(error)
    promise

Model =
  extended: ->
    unless firebase
      return
    unless @ref
      error('Please add variable \'ref\' to this Spine.Firebase.Model')
      return

  fetch: (options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
      if options?.child then @fbref = @fbref.child(options.child)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    @fbref.on 'value', (data) =>
      records = []
      if options?.child
        records.push(data.val())
      else
        data.forEach (child) ->
          if options?.where
            for key, value of options.where
              if child.val()[key][value]
                records.push(child.val())
          else records.push(child.val())
        false # must return false or enumeration will stop after first child
      @refresh(records or [], options)
      l_deferred.resolve(records)
      console.log('firebase fetch', records)
    promise

  fetchOnce: (options = {}) ->
    @fbref = firebase.database().ref(@ref)
    if options?.child then @fbref = @fbref.child(options.child)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    @fbref.once 'value', (data) =>
      records = []
      if options?.child
        records.push(data.val())
      else
        data.forEach (child) ->
          if options?.where
            for key, value of options.where
              if child.val()[key][value]
                records.push(child.val())
          else records.push(child.val())
        false # must return false or enumeration will stop after first child
      @refresh(records or [], options)
      l_deferred.resolve(records)
      console.log('firebase fetch once', records)
    promise

  off: =>
    if @fbref
      @fbref.off()
      delete @fbref

  push: (record) =>
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    p_deferred = $.Deferred()
    promise  = p_deferred.promise()
    recordRef = @fbref.push()
    record.id = recordRef.key
    recordRef.set(record.attributes()).then ->
      console.log('firebase push', record.attributes())
      p_deferred.resolve(record)
    promise

  update: (record = {}, options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
      if options?.child then @fbref = @fbref.child(options.child)
    u_deferred = $.Deferred()
    promise  = u_deferred.promise()
    # setting ref depending on if model is a singleton and if record was passed
    tempRef = @fbref
    if not options?.child and record?.id
      tempRef = @fbref.child(record.id)
    # setting updates to record if given else all local model data
    updates = {}
    if record?.id
      updates[record.id] = record.attributes()
    else
      for model in @all()
        updates[model.id] = model.attributes()
    # do the updates!
    tempRef.update(updates).then ->
      console.log('firebase update', updates)
      u_deferred.resolve()
    # give 'em the promise!
    promise

  delete: (record = {}, options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
      if options?.child then @fbref = @fbref.child(record.id)
    d_deferred = $.Deferred()
    promise  = d_deferred.promise()
    # setting ref depending on if model is a singleton and if record was passed
    tempRef = @fbref
    if not options?.child and record?.id
      tempRef = @fbref.child(record.id)
    # setting updates to record if given else all local model data
    updates = {}
    if record?.id
      updates[record.id] = null
    else
      for model in @all()
        updates[model.id] = null
    tempRef.update(updates)
    .then ->
      console.log('firebase delete', updates)
      d_deferred.resolve()
    .catch (error) ->
      console.log('firebase delete error', error, updates)
      d_deferred.reject(error)
    promise

class User
  constructor: (params) ->
    @displayName   = params.displayName
    @email         = params.email
    @emailVerified = params.emailVerified
    @photoURL      = params.photoURL
    @isAnonymous   = params.isAnonymous
    @uid           = params.uid
    @accessToken   = params.accessToken

Firebase.Model  = Model
Firebase.User   = User
Spine.Firebase  = Firebase
module?.exports = Firebase
