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
    ctr = @
    jq_deferred = $.Deferred()
    promise  = deferred.promise()
    firebase.auth().signOut().then ->
      if ctr.appUser then delete ctr.appUser
      jq_deffered.resolve()
    promise

Model =
  extended: ->
    unless firebase
      return
    unless @ref
      error('Please add variable \'ref\' to a Spine.Firebase.Model')
      return

  update: ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    u_deferred = $.Deferred()
    promise  = u_deferred.promise()
    @fbref.child(@id).update(@attributes()).done ->
      console.log('firebase update', @attributes())
      u_deferred?.resolve()
    promise

  load: (options = {})->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    @fbref.on 'value', (data) =>
      @refresh(data.val() or [], options)
      l_deferred?.resolve(data.val())
      console.log('firebase load', data.val())
    promise

  loadOnce: (options = {}) ->
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    options.clear = true unless options.hasOwnProperty('clear')
    l_deferred = $.Deferred()
    promise  = l_deferred.promise()
    @fbref.once 'value', (data) =>
      @refresh(data.val() or [], options)
      l_deferred?.resolve(data.val())
      console.log('firebase load', data.val())
    promise

  off: ->
    @fbref?.off()

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
