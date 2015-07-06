module.exports = do ->
  Neptune.Models.Library = class Library extends Backbone.Model
    localStorage: Neptune.librariesStore
