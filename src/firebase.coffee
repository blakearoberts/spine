Spine = @Spine or require('spine')
$     = Spine.$

class Firebase extends Spine.Controller
  constructor: (params) ->
    super

  initFirebase: (config) ->
    ctr = @
    firebase.initializeApp(config)
    firebase.auth().onAuthStateChanged ((userParams) ->
      ctr.log('firebase auth state change', userParams)
      unless userParams
        ctr.trigger('firebaseAuthToggle')
        ctr.trigger('firebaseAuthOut')
      else
        userParams.getToken().then (accessToken) ->
          userParams['accessToken'] = accessToken
          ctr.appUser = new User(userParams)
          ctr.trigger('firebaseAuthToggle')
          ctr.trigger('firebaseAuthIn')
    ), (error) ->
      ctr.log('auth error', error)

  @signOut: ->
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
    @fbref = firebase.database().ref(@ref)

  save: ->
    deferred = $.Deferred()
    promise  = deferred.promise()
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    @fbref.child(@id).update(@).done ->
      deferred.resolve()
      console.log('save', @)
    promise

  load: ->
    deferred = $.Deferred()
    promise  = deferred.promise()
    unless @fbref
      @fbref = firebase.database().ref(@ref)
    @fbref.on 'value', (data) =>
      @refresh(data.val() or [], options)
      deferred.resolve(data.val())
      console.log('load', data.val())
    promise

  off: ->
    if @fbref
      @fbref.off()

  saveFirebase: ->
    result = JSON.parse(JSON.stringify(@))
    deferred = $.Deferred()
    promise  = deferred.promise()
    firebase.database().ref(@ref + result[0].id).set(result[0]).then (data) ->
      console.log(data)

  loadFirebase: (options = {}) ->

    firebase.database().ref(@ref + @id).on 'value', (data) =>
      @refresh(data.val() or [], options)

  fetchOnce: (options = {}) ->
    options.clear = true unless options.hasOwnProperty('clear')
    deferred = $.Deferred()
    promise  = deferred.promise()
    unless firebase.auth().currentUser
      deferred.reject()
      return promise
    unless options.ref
      options.ref = @ref
    firebase.database().ref(options.ref).once('value').then (data) =>
      @refresh(data.val() or [], options)
      deferred.resolve(data.val())
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
