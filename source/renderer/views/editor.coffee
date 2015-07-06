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

    render: ->
      @$el.html JST[@template]()

      @dragster = new Dragster(@el)

      @messageEls =
        $message: @$(".editor--message")
        $header: @$(".editor--message-header")
        $details: @$(".editor--message-details")
        $nameInput: @$('.editor--library-name-input')

      @renderExistingLibraries()

      @

    renderExistingLibraries: ->
      $existingLibraries = @$('.editor--existing-libraries')
      $existingLibraries.toggle (not _(Neptune.libraries.models).isEmpty())

      @$('.editor--library').empty()
      Neptune.libraries.each (library) ->
        view = new Neptune.Views.ExistingLibraryView
          model: library
        @$('.editor--existing-libraries').append view.render().$el

    addLibrary: (e) ->
      e.preventDefault()
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

    renderValidation: (e) ->
      @newLibraryPath = null

      path = @_getFilePath e
      pathHasInvalidExtension = path.substring(path.length - 4) isnt ".itl"
      pathIsDuplicate = Neptune.libraries.find (model) ->
        model.get('path') is path

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
        @newLibraryPath = path

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
      e.preventDefault()

      # hack to allow dragster:enter to fire multiple times
      # https://github.com/bensmithett/dragster/issues/8
      @dragster.dragleave(@el)

      return unless @newLibraryPath

      @messageEls.$header.text 'One more thing...'
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
