window.Config = Backbone.Model.extend(
  localStorage: new Store("settings")
  defaults:
    key: ''
    length: 10
    caps: true
    symbols: true
    save_settings: false
    save_master: false
    save_key: true

  initialize: ->
    @set(key: @newKey())

  newKey: ->
    Crypto.SHA256(new Date().getTime().toString()).substr(0, 5)
)

window.ConfigView = Backbone.View.extend(
  el: $('#settings')
  tagName: "input"
  events:
    'change input': 'saveConfig'

  initialize: ->
    @model = new Config
    self = this
    @model.fetch(
      success: (model, response)->
        self.model.unset('0')
        self.model.set(response[0])
        self.render()
    )
    @import()
    
  import: ->
    if localStorage.hp_settings
      import_key = localStorage.hp_key  
      import_settings = JSON.parse(localStorage.hp_settings)
      import_master = localStorage.hp_master
    
      import_settings.save_settings = import_settings.remember
      delete import_settings.remember
      delete import_settings.algorithm
    
      @model.set(
        master: import_master 
        key: import_key
      )
      @model.set(import_settings)
      @model.save()
    
      localStorage.removeItem('hp_key')
      localStorage.removeItem('hp_settings')
      localStorage.removeItem('hp_master')
      console.log "Import successful"
      @render()
    
  render: ->
    config = @model.attributes
    for own index, value of config
      switch $("##{index}").attr('type')
        when "checkbox"
          $("##{index}").attr('checked', config[index])
          break
        else
          $("##{index}").val(config[index])
          break
    
  saveConfig: ->
    config = $('form', @el).serializeObject()
    config.key = config.key.toLowerCase()
    
    if config.save_settings
      @model.save(config)
    else
      @model.destroy()
    
    @saveMaster()
    AppView.focus()
      
  saveMaster: ->
    master = $('#master').val()    
    if @model.get('save_master')
      if master.length > 0 && localStorage.master != master
        @model.save(master: master)
    else
      @model.unset('master')
      @model.save()
)

window.Secret = Backbone.Model.extend(
  defaults:
    master: ''
    domain: ''
    
  initialize: ->
    @bind('error', (model, errors) ->
      # console.log errors
    )
    error = @validate(@attributes);
    unless error
      @create()
    
  validate: (attrs) ->
    for own index, value of attrs
      if attrs[index].length == 0
        return [index, "can't be blank"]
  
  create: ->
    config = @attributes.config
    symbols = "!@#]^&*(%[?${+=})_-|/<>".split('')
    domain = @attributes.domain.toLowerCase()
    [host, tld] = domain.split(".")
    tld = 'com' unless tld
    
    hash = Crypto.SHA256("#{@attributes.master}:#{host}.#{tld}")
    hash = Crypto.SHA256("#{hash}#{config.key}").substr(0, config.length)
    
    nums = 0
    key_num = hash.match(/\d/)[0]
    secret = hash.split(//)
    this_upper = true

    for item in secret
      if item.match(/[a-zA-Z]/) # Letters
        if config.caps == true && !this_upper
          this_upper = true
          secret[_i] = item.match(/[a-zA-Z]/)[0].toUpperCase()
        else
          this_upper = false
      else # Numbers
        if config.symbols == true
          secret_idx = parseInt(_i + key_num / 3)
          sym_idx = nums + _i + (key_num * nums) + (1 * _i)
          unless  (secret[secret_idx] == null) or 
                  (secret_idx < 0) or 
                  (sym_idx < 0) or 
                  (symbols[sym_idx] == null) or
                  (symbols[sym_idx] == undefined)
            secret[secret_idx] += symbols[sym_idx]
        nums += 1
    
    secret = secret.join('').substr(0, config.length)
    @set(secret: secret)
)

window.AppView = Backbone.View.extend(
  el: $('#new_secret form')
  events:
    'change #master': 'toggle_master'
    'keyup input.required': 'render'
  
  initialize: ->
    self = this
    window.Swipe = new Swipe(
      document.getElementById('swipe'),
      startSlide: 1
      callback: ->
        $('#swipe').trigger('swipe.animated')
    )

    $('body').on 'swipe.animated', '#swipe', ->
      self.focus()
      
    ConfigView.model.bind('change', this.render, this);
    self = this
    
    @load_master()
    @focus()
    @render_domains()
    window.is_mobile = (navigator.userAgent.match(/mobile/i) != null ? true : false)
    
    $('#secret').bind('focus touchstart', ->
      
      @selectionStart = 0;
      @selectionEnd = @value.length;
      
      if self.mobile_user
        $('small.hint').fadeIn()
    ).blur(->
      if self.mobile_user
        $('small.hint').fadeOut()
    )    
  
  load_master: ->
    $('#master').val(ConfigView.model.get('master'))
    
  focus: ->
    $('input.required:visible', @el).each((index) ->
      if @value.length == 0
        $(this).focus()
        false
    ) 
    
  toggle_master: ->
    if ConfigView.model.get('save_master')
      ConfigView.saveMaster()
    
  render: ->
    self = this
    config = ConfigView.model.toJSON()
    
    hatchpass = new Secret
      master: $('#master').val()
      domain: $('#domain').val()
      config: config
        
    if hatchpass
      $('#secret').val(hatchpass.get('secret'))
      if window.is_mobile
        if $('#secret').val().length > 0
          $('#secret').show().attr('readonly', false)
        else
          $('#secret').hide().attr('readonly', true)
      
      $('#secret').off('focus').focus (e) ->
        self.save_domain($('#domain').val())
        
  save_domain: (domain) ->
    recent_domains = []
    if localStorage.recent_domains
      recent_domains = JSON.parse(localStorage.recent_domains)
    
    total = recent_domains.length
    if total >= 10
      recent_domains.splice(0, 1)
      
    recent_domains.push(domain)
    localStorage.recent_domains = JSON.stringify(recent_domains.unique())
    @render_domains()
  
  render_domains: ->
    recent_domains = []
    if localStorage.recent_domains
      recent_domains = JSON.parse(localStorage.recent_domains)
    
    total = recent_domains.length
    $recent_domains = $('#recent_domains ul')
    $recent_domains.empty()
    
    if total > 0
      i = 0
      while i < total
        html = "<li> \
                  <a href='##{recent_domains[i]}' class='domain'>
                    #{recent_domains[i]}
                  </a> \
                  <a href='#remove' class='remove' data-id='#{i}'>&times;</a>
                </li>"
        $recent_domains.append(html)
        i++
    else
      html = "<li class='no-results'>You have no recent domains</li>"
      $recent_domains.append(html)
)

window.ConfigView = new ConfigView
window.AppView = new AppView