module.exports = do ->
  Neptune.Views.LibraryView = class LibraryView extends Backbone.View
    el: '.library-editor'
    template: 'source/templates/library-editor.html'
    events:
      'submit .js-addLibrary': 'addLibrary'

    render: ->
      @$el.html JST[@template]()

      Neptune.libraries.forEach (model) ->
        $library = $('<li>').text(model.attributes.path)
        @$('.editor--libraries').append $library

    addLibrary: (e) ->
      e.preventDefault()

      library = new Neptune.Models.Library
        path: @$('.editor--newLibrary').get(0).files['0'].path
      Neptune.libraries.add library
      Neptune.libraries.sync 'update', Neptune.libraries
