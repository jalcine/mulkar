# Connect Leap Motion actions.
# TODO Only handle work when focused.

openImageUnderFinger = (frame) ->
  # Get bounding box of finger.
  pointable = frame.pointables[0]
  position = [
    $(window).width()/2 + 6*pointable.tipPosition[0],
    $(window).height() - 4*pointable.tipPosition[1] + $('header[role=page]').height() + 150,
    pointable.tipPosition[2]
  ]

  # Move the pointer.

  # Find the dude under the element.
  elem = document.elementFromPoint position[0], position[1]
  $elem = $(elem)
  $elem.parent().find('.active').removeClass('.active')
  $elem.addClass 'active' unless $elem.hasClass 'active'
$ ->
  # Load the mason!
  $ct = $('section[role=page]')
  #$ct.imagesLoaded ->
    #$ct.masonry {
      #itemSelector: '.item'
      #isFitWidth: true
    #}

Mulkar =
  View : Backbone.View.extend {
    el: 'section[role=page]'
    initialize: () =>
      @listenTo Mulkar.Tumblr.images, 'add', @addImage
      @listenTo Mulkar.Tumblr.images, 'reset', @clearImages
    addImage: (image) =>
      v = new Mulkar.Tumblr.ImageView {model: image}
      console.log image
      @$el.appendTo v.render().el
    clearImages: () =>
      @$el.find('div.item').remove()
  }
  bind : ->
    console.log '[mlk] booting...'
    Mulkar.Tumblr.bind()
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
    coords = [$(window).width() / 2, $(window).height() / 2] unless coords?
    $('#pointer').css({
      left: coords[0],
      top:  coords[1]
    })

  isPointing: (frame) ->
    frame.pointables.length == 1 and frame.hands.length == 1

  isGesturing: (frame) ->
    true

  toggleImageUnderFinger: (frame) ->
    view = Mulkar.Leap.findElementForFinger(frame)
    console.log view

  invokeGestureMovement: (frame) ->
    true

  findElementForFinger: (frame) ->
    coords = Mulkar.Leap.obtainCoordinates(frame)
    $el = $ document.elementFromPoint coords[0], coords[1]
    console.log $el.data('view')
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

Mulkar.Tumblr = {}
Mulkar.Tumblr =
  images: null
  bind: ->
    console.log '[mlk] booting tumblr...'
    Mulkar.Tumblr.images = new Mulkar.Tumblr.ImageCollection()
    Mulkar.Tumblr.images.fetch
      success: (collection, response) ->
        _.each collection.models, (model) ->
          console.log model.toJSON()
    console.log '[mlk] booted tumblr, baby!'

  ImageModel : Backbone.Model.extend({
    defaults:
      image: 'the_man.jpg'
      link: 'https://en.wikipedia.org/wiki/Martin_Luther_King,_Jr.'
      user: 'algorithmicalexpansion'
      text: 'Martin Luther King, Jr. was an American pastor, activist, humanitarian, and leader in the African-American Civil Rights Movement'
  })

  ImageCollection : Backbone.Collection.extend({
    model: Mulkar.Tumblr.ImageModel
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
      @listenTo @model, 'tumblr:load:finished', @paint
      console.log @
      @$el.data 'view', @
    paint: ->
      console.log "[mlk] painting #{@model.image}.."
      @$el.css 'background-image', "url(#{@model.image})"
    expand: ->
      console.log "[mlk] visualing #{@model.image}.."
      @$el.addClass 'active'
    leave: ->
      console.log "[mlk] leaving #{@model.image}.."
      @$el.removeClass 'active'
    render: ->
      console.log @
      @$el.html(@tmpl({link: @get('link'), user: @get('user'), text: @get('text'), image: @get('image')}))
  })

window.Mulkar = Mulkar

$ ->
  Mulkar.bind()
