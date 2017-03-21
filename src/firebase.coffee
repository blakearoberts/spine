Spine = @Spine or require('spine')
$     = Spine.$

class Firebase extends Spine.Controller
  constructor: (params) ->
    super
    @bind('authStateChange', @authStateChange)

  initFirebase: (config) ->
    ctr = @
    firebase.initializeApp(config)
    ui = new firebaseui.auth.AuthUI(firebase.auth())
    ui.start('#firebaseui-auth-container', {
      signInOptions: [
        firebase.auth.GoogleAuthProvider.PROVIDER_ID,
        firebase.auth.FacebookAuthProvider.PROVIDER_ID,
        firebase.auth.TwitterAuthProvider.PROVIDER_ID,
        firebase.auth.GithubAuthProvider.PROVIDER_ID
      ]
    })
    firebase.auth().onAuthStateChanged ((userParams) ->
      ctr.log('firebase auth state change', userParams)
      if userParams
        userParams.getToken().then (accessToken) ->
          userParams['accessToken'] = accessToken
          Spine.Firebase.User.signIn(userParams).done (data) ->
            ctr.log('spine user signin', data)
            ctr.trigger('authStateChange')
    ), (error) ->
      ctr.log('auth error', error)

  authStateChange: ->
    console.log('auth state change triggered')

  onAuthStateChanged: ->
    ctr = @
    deferred = $.Deferred()
    promise  = deferred.promise()
    firebase.auth().onAuthStateChanged ((userParams) ->
      ctr.log('firebase auth state change', userParams)
      if userParams
        userParams.getToken().then (accessToken) ->
          userParams['accessToken'] = accessToken
          Spine.Firebase.User.signIn(userParams).done (data) ->
            ctr.log('spine user signin', data)
            deferred.resolve(data)
      else deferred.reject()
    ), (error) ->
      ctr.log('auth error', error)
      deferred.reject()
    promise

  @signOut: =>
    deferred = $.Deferred()
    promise  = deferred.promise()
    resolve  = (data) ->
      if data then deferred.resolve(data)
      else deferred.reject(data)
    firebase.auth().signOut().then =>
      if @user then delete @user
      resolve()
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

class User extends Spine.Model
  @configure 'User',
    'displayName',
    'email',
    'accessToken'

  @ref = '/users/'

  @signIn: (params) ->
    userPath = params.email.replace(/([.@])/g, '-')
    deferred = $.Deferred()
    promise  = deferred.promise()
    firebase.database().ref(User.ref + userPath).once('value').then (data) ->
      if data then deferred.resolve(data)
      else deferred.reject(data)
    promise

Firebase.Model  = Model
Firebase.User   = User
Spine.Firebase  = Firebase
module?.exports = Firebase
