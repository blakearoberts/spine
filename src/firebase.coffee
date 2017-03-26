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
      ctr.log('auth error', error)

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

  load: (options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    if options?.child
      @fbref.child(options.child).on 'value', (data) =>
        @refresh(data.val() or [], options)
        l_deferred.resolve(data.val())
        console.log('firebase load', data.val())
    else
      @fbref.on 'value', (data) =>
        @refresh(data.val() or [], options)
        l_deferred.resolve(data.val())
        console.log('firebase load', data.val())
    promise

  loadOnce: (options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    if options.child
      @fbref.child(options.child).once 'value', (data) =>
        @refresh(data.val() or [], options)
        l_deferred.resolve(data.val())
        console.log('firebase load', data.val())
    else
      @fbref.once 'value', (data) =>
        @refresh(data.val() or [], options)
        l_deferred.resolve(data.val())
        console.log('firebase load', data.val())
    promise

  off: ->
    @fbref?.off()

  update: (record = {}, options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    u_deferred = $.Deferred()
    promise  = u_deferred.promise()
    if record.id
      @fbref.child(record.id).update(record.attributes()).then ->
        console.log('firebase update record', record.attributes())
        u_deferred.resolve()
    else
      updates = {}
      for obj in @all()
        updates[obj.id] = obj.attributes()
      @fbref.update(updates).then ->
        console.log('firebase update', updates)
        u_deferred.resolve()
    promise

  delete: (record = {}, options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    d_deferred = $.Deferred()
    promise  = d_deferred.promise()
    if record.id
      @fbref.child(record.id).remove()
      .then ->
        console.log('firebase delete record')
        d_deferred.resolve()
      .catch (error) ->
        console.log('firebase delete record error', error)
        d_deferred.reject(error)
    else
      @fbref.remove()
      .then ->
        console.log('firebase delete all')
        d_deferred.resolve()
      .catch (error) ->
        console.log('firebase delete error', error)
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
