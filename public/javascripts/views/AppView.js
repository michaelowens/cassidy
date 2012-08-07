// Generated by CoffeeScript 1.3.3
(function() {
  var AppView;

  AppView = Backbone.View.extend({
    active_panel: 1,
    el: $('#new_secret form'),
    events: {
      'change #master': 'toggle_master',
      'keyup input.required': 'render'
    },
    initialize: function() {
      var $panel, self, _ref;
      self = this;
      $panel = $('#swipe .panel');
      window.Swipe = new Swipe($('#swipe')[0], {
        startSlide: self.active_panel,
        callback: function(x, d) {
          return $('#swipe').trigger('swipe.animated');
        }
      });
      App.ConfigView.model.bind('change', this.render, this);
      this.load_master();
      this.focus_input();
      App.is_mobile = (_ref = navigator.userAgent.match(/mobile/i) !== null) != null ? _ref : {
        "true": false
      };
      $('body').on('swipe.animated', '#swipe', function(e) {
        var pos;
        pos = Swipe.getPos();
        if (pos !== self.active_panel) {
          self.active_panel = pos;
          return self.focus_input();
        }
      });
      return $('#secret').bind('focus touchstart', function() {
        this.selectionStart = 0;
        this.selectionEnd = this.value.length;
        if (self.mobile_user) {
          return $('small.hint').fadeIn();
        }
      }).blur(function() {
        if (self.mobile_user) {
          return $('small.hint').fadeOut();
        }
      });
    },
    load_master: function() {
      return $('#master').val(App.ConfigView.model.get('master'));
    },
    focus_input: function() {
      return $('input.required:visible', this.el).each(function(i) {
        if (!this.value.length) {
          $(this).focus();
          return false;
        }
      });
    },
    toggle_master: function() {
      if (App.ConfigView.model.get('save_all')) {
        return App.ConfigView.saveConfig();
      }
    },
    render: function() {
      var config, hatchpass, self;
      self = this;
      config = App.ConfigView.model.toJSON();
      hatchpass = new App.Secret({
        master: $('#master').val(),
        domain: $('#domain').val(),
        config: config
      });
      if (hatchpass) {
        $('#secret').val(hatchpass.get('secret'));
        if (App.is_mobile) {
          if ($('#secret').val().length > 0) {
            $('#secret').show().attr('readonly', false);
          } else {
            $('#secret').hide().attr('readonly', true);
          }
        }
        return $('#secret').off().one('focus', function(e) {
          return App.Domains.save({
            url: $('#domain').val()
          });
        });
      }
    }
  });

  App.AppView = new AppView;

}).call(this);
