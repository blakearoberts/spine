Spine = @Spine or require('spine')

Spine.Model.Local =
  extended: ->
    unless window.localStorage
      return

    @change @saveLocal
    @fetch @loadLocal

  saveLocal: ->
    result = JSON.stringify(@)
    localStorage[@className] = result

  loadLocal: (options = {})->
    options.clear = true unless options.hasOwnProperty('clear')
    result = localStorage[@className]
    @refresh(result or [], options)

module?.exports = Spine.Model.Local
