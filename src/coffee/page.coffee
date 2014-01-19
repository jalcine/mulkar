# Connect Leap Motion actions.
# TODO Only handle work when focused.

#$ ->
  # Load the mason!

Mulkar =
  View : Backbone.View.extend {
    el: 'section[role=page]'
    initialize: () ->
      this.listenTo Mulkar.Tumblr.images, 'add', @addImage
      this.listenTo Mulkar.Tumblr.images, 'reset', @clearImages

    addImage: (image) ->
      v = new Mulkar.Tumblr.ImageView {model: image}
      elem = v.render()
      elem.css 'background-image', "url(#{elem.find('figcaption').attr('data-src')})"
      text = elem.find('span')
      text.html(text.text())
      @$el.append elem
    clearImages: () ->
  }
  scrollToRow: (row) ->
    minHeight = $('header').height()
    rowHeight = row * $('section > .item').height()
    movingHeight = rowHeight + minHeight
    document.body.scrollTop = movingHeight
  bind : ->
    console.log '[mlk] booting...'
    Mulkar.Tumblr.bind()
    new Mulkar.View()
    Mulkar.Leap.bind()
    console.log '[mlk] booted, baby!'

Mulkar.Leap =
  controller: null,
  obtainCoordinates: (frame) ->
    return null if frame.pointables.length != 1
    pointable = frame.pointables[0]
    [
      $(window).width()/2 + 6*pointable.tipPosition[0],
      $(window).height() - 4*pointable.tipPosition[1] + $('header[role=page]').height() + 150,
      pointable.tipPosition[2]
    ]
  setPointer: (frame) ->
    coords = Mulkar.Leap.obtainCoordinates(frame)
    #coords = [$(window).width() / 2, $(window).height() / 2] unless coords?
    return unless coords?
    max_width = $(window).width() - ($('#pointer').width() / 2)
    coords[0] = max_width if coords[0] >= max_width
    coords[1] = $('header').height() if coords[1] <= $('header').height()
    $('#pointer').css({
      left: coords[0],
      top:  coords[1]
    })

  isPointing: (frame) ->
    frame.pointables.length == 1 and frame.hands.length == 1

  isGesturing: (frame) ->
    frame.gestures.length

  toggleImageUnderFinger: (frame) ->
    view = Mulkar.Leap.findElementForFinger(frame)

  invokeGestureMovement: (frame) ->
    console.log frame
    gesture = frame.gestures[0]
    if gesture.type == 'swipe'
      console.log 'swipe', Curtsy.direction(gesture)
      console.log Curtsy.direction(gesture).type

  findElementForFinger: (frame) ->
    coords = Mulkar.Leap.obtainCoordinates(frame)
    $el = $ document.elementFromPoint coords[0], coords[1]
    $('.item').removeClass('active')
    $el.parents('.item').addClass 'active'
    console.log $el
    #console.log $el.data('view')
    return $el.data('view')

  checkFingerInput: (frame) ->
    Mulkar.Leap.toggleImageUnderFinger(frame) if Mulkar.Leap.isPointing(frame)
    Mulkar.Leap.invokeGestureMovement(frame) if Mulkar.Leap.isGesturing(frame)

  bind : ->
    console.log '[mlk] booting leap...'
    Mulkar.Leap.controller = new Leap.Controller()
    Mulkar.Leap.controller.on 'animationFrame', Mulkar.Leap.checkFingerInput
    Mulkar.Leap.controller.on 'animationFrame', Mulkar.Leap.setPointer
    Mulkar.Leap.controller.connect()

Mulkar.Tumblr =
  images: null
  bind: ->
    Mulkar.Tumblr.images = new Mulkar.Tumblr.ImageCollection()
    console.log '[mlk] booting tumblr...'
    Mulkar.Tumblr.images.fetch()
    console.log '[mlk] booted tumblr, baby!'

  addImage: (image) ->
    v = new Mulkar.Tumblr.ImageView({model: image})

  ImageModel : Backbone.Model.extend({
    defaults:
      image: 'the_man.jpg'
      link: 'https://en.wikipedia.org/wiki/Martin_Luther_King,_Jr.'
      user: 'algorithmicalexpansion'
      text: 'Martin Luther King, Jr. was an American pastor, activist, humanitarian, and leader in the African-American Civil Rights Movement'
  })

  ImageCollection : Backbone.Collection.extend({
    url: '/images'
  })

  ImageView : Backbone.View.extend({
    tagName: 'div'
    className: 'item'
    tmpl: _.template($('#image-template').html())
    events:
      'leap:point': 'expand'
      'leap:leave': 'leave'
    initialize: ->
      @listenTo @model, 'img load', @paint
      @listenTo @$el, 'click', @scrollTO
    paint: ->
      console.log "[mlk] painting #{@model('image').url}.."
      @$el.css 'background-image', "url(#{@model('image').url})"
    expand: ->
      console.log "[mlk] visualing #{@model('image').url}.."
      @$el.addClass 'active'
    leave: ->
      console.log "[mlk] leaving #{@model.get('image').url}.."
      @$el.removeClass 'active'
    scrollTo: ->
      row = Math.ceil(@$el.index() / 5)
      Mulkar.scrollToRow row
    render: ->
      console.log @model
      @$el.html @tmpl {
        link: @model.get('link')
        user: @model.get('user')
        text: @model.get('text')
        image: @model.get('image')
      }
      @$el.data 'view', @
      @$el
  })

window.Mulkar = Mulkar
$ ->
  setTimeout ->
    Mulkar.bind()
    $('body').css 'background-image', 'none'
  , 500
