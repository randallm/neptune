ipc = require 'ipc'
path = require 'path'
require 'shelljs/global' # TODO: use namespaced version of shelljs

module.exports = do ->
  Neptune.Views.LibraryView = class LibraryView extends Backbone.View
    el: '.editor'
    template: 'source/renderer/views/templates/editor.html'
    events:
      'dragster:enter': 'renderValidation'
      'dragster:leave': 'hideValidation'
      'drop': 'renderLibraryNaming'
      'submit .editor--library-naming': 'addLibrary'
    messageTypes: 'editor--message-error editor--message-action editor--message-success'

    initialize: ->
      @listenTo Neptune.libraries, 'change', @renderExistingLibraries
      @listenTo Neptune.libraries, 'sync', ->
        ipc.send 'syncLocalStorage', JSON.stringify(localStorage)
      @listenTo Neptune.libraries, 'update', ->
        if Neptune.libraries.isEmpty()
          @renderLibraryDetect()

    render: ->
      @$el.html JST[@template]()

      @dragster = new Dragster(@el)

      @messageEls =
        $message: @$(".editor--message")
        $header: @$(".editor--message-header")
        $details: @$(".editor--message-details")
        $nameInput: @$('.editor--library-name-input')

      if Neptune.libraries.isEmpty()
        @renderLibraryDetect()
      else
        @renderExistingLibraries()

      @

    renderExistingLibraries: ->
      $existingLibraries = @$('.editor--existing-libraries')
      $existingLibraries.empty()

      Neptune.libraries.each (library) ->
        view = new Neptune.Views.ExistingLibraryView
          model: library
        $existingLibraries.append view.render().$el

    addLibrary: (e) ->
      e?.preventDefault()
      $.when @_addLibrary()
        .then @renderSuccess()

    _addLibrary: ->
      Neptune.libraries.create
        path: @newLibraryPath
        name: @messageEls.$nameInput.val()

    remove: ->
      @dragster.removeListeners()
      super

    _getFilePath: (e) ->
      e.originalEvent.detail.dataTransfer.files.item(0).path

    detectOpenLibrary: =>
      exec 'lsof -c iTunes | grep "iTunes Library.itl" -m 1', (code, output) =>
        if code is 0
          @newLibraryPath = output.slice(output.indexOf('/')).trim()

          @renderLibraryNaming()
        else
          @detectOpenLibrary()

    renderLibraryDetect: ->
      @messageEls.$message.removeClass @messageTypes
      @messageEls.$message.addClass "editor--message-action"
      @messageEls.$message.removeClass "hidden"

      @messageEls.$header.text "Welcome to Neptune."
      # TODO: auto-open iTunes
      @messageEls.$details.html "To add your first library, open up iTunes and check back here."

      @detectOpenLibrary()

    renderValidation: (e) ->
      @newLibraryPath = null

      libraryPath = @_getFilePath e
      pathHasInvalidExtension = libraryPath.substring(libraryPath.length - 4) isnt ".itl"
      pathIsDuplicate = Neptune.libraries.find (model) ->
        model.get('path') is libraryPath

      @messageEls.$message.removeClass @messageTypes

      if pathIsDuplicate
        @renderDuplicate()
        @messageEls.$message.addClass "editor--message-error"
      else if pathHasInvalidExtension
        @renderInvalidExtension()
        @messageEls.$message.addClass "editor--message-error"
      else
        @renderDropPrompt()
        @messageEls.$message.addClass "editor--message-action"
        @newLibraryPath = libraryPath

      @messageEls.$message.removeClass "hidden"

    renderDuplicate: ->
      @messageEls.$header.text "Library already exists"
      @messageEls.$details.text "Try again with a new library."

    renderInvalidExtension: ->
      @messageEls.$header.text "Invalid library file"
      @messageEls.$details.text 'iTunes library files must end with ".itl"'

    renderDropPrompt: ->
      @messageEls.$header.text "Looks good!"
      @messageEls.$details.text 'Drop the library to import it into Neptune.'

    renderLibraryNaming: (e) ->
      e?.preventDefault()

      # hack to allow dragster:enter to fire multiple times
      # https://github.com/bensmithett/dragster/issues/8
      @dragster.dragleave(@el)

      return unless @newLibraryPath

      headerText = switch
        when Neptune.libraries.length is 0
          'iTunes library found!'
        when Neptune.libraries.length > 0
          'One more thing...'
      @messageEls.$header.text headerText

      @messageEls.$details.text "Give your library a name so you'll remember it later."
      @messageEls.$nameInput.show()

    renderSuccess: ->
      @messageEls.$message.removeClass @messageTypes
      @messageEls.$message.addClass 'editor--message-success'
      @messageEls.$header.text 'Saved!'
      @messageEls.$details.text ''

      @messageEls.$nameInput.hide()
      @messageEls.$nameInput.val ''

      _.delay @hideValidation, 1000

    hideValidation: =>
      return if @messageEls.$message.is('.editor--message-action')
      @messageEls.$message.addClass "hidden"
