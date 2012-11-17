// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  window.Domains = (function(_super) {

    __extends(Domains, _super);

    function Domains() {
      return Domains.__super__.constructor.apply(this, arguments);
    }

    Domains.prototype.localStorage = new Store('domains');

    Domains.prototype.save = function(obj) {
      var domains;
      domains = _.pluck(app.Domains.toJSON(), 'url');
      if (!_.include(domains, obj.url)) {
        return this.create(obj);
      }
    };

    return Domains;

  })(Backbone.Collection);

}).call(this);
