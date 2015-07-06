module.exports = do ->
  Neptune.Views.ExistingLibraryView = class ExistingLibraryView extends Backbone.View
    className: 'editor--library'
    template: 'source/renderer/views/templates/existing_library.html'
    events:
      'click .editor--library-remove': 'remove'

    render: ->
      @$el.html JST[@template]
        name: @model.get 'name'
      @

    remove: ->
      @model.destroy()

      super
