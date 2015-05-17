module.exports = do ->
  Neptune.Collections.Libraries = class Libraries extends Backbone.Collection
    localStorage: new Backbone.LocalStorage 'Libraries'
    id: 'storage'
