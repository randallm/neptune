module.exports = do ->
  Neptune.Collections.Libraries = class Libraries extends Backbone.Collection
    localStorage: Neptune.librariesStore
    model: Neptune.Models.Library

    isEmpty: ->
      _(@models).isEmpty()
