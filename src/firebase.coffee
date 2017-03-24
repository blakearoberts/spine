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
      if userParams
        userParams.getToken().then (accessToken) ->
          userParams['accessToken'] = accessToken
          ctr.appUser = new User(userParams)
          ctr.trigger('firebaseAuthChange')
    ), (error) ->
      ctr.log('auth error', error)

  @firebaseSignOut: =>
    deferred = $.Deferred()
    promise  = deferred.promise()
    firebase.auth().signOut().then =>
      if @appUser then delete @appUser
      deffered.resolve()
    promise

Model =
  extended: ->
    unless firebase
      return
    @change @saveFirebase
    @fetch @loadFirebase
    @startLoadListener() if @listenToFirebase

  saveFirebase: ->
    result = JSON.parse(JSON.stringify(@))
    firebase.database().ref(@ref + result[0].id).set(result[0])

  startLoadListener: ->
    firebase.database().ref(@ref + @id).on 'value', (data) =>
      @refresh(data.val() or [], options)

  loadFirebase: (options = {}) ->
    options.clear = true unless options.hasOwnProperty('clear')
    deferred = $.Deferred()
    promise  = deferred.promise()
    unless firebase.auth().currentUser
      deferred.reject()
      return promise
    firebase.database().ref(@ref).once('value').then (data) =>
      @refresh(data.val() or [], options)
      deferred.resolve(data)
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
