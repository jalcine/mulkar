(function() {
  var Mulkar;

  Mulkar = {
    View: Backbone.View.extend({
      el: 'section[role=page]',
      initialize: function() {
        this.listenTo(Mulkar.Tumblr.images, 'add', this.addImage);
        return this.listenTo(Mulkar.Tumblr.images, 'reset', this.clearImages);
      },
      addImage: function(image) {
        var elem, text, v;
        v = new Mulkar.Tumblr.ImageView({
          model: image
        });
        elem = v.render();
        elem.css('background-image', "url(" + (elem.find('figcaption').attr('data-src')) + ")");
        text = elem.find('span');
        text.html(text.text());
        return this.$el.append(elem);
      },
      clearImages: function() {}
    }),
    scrollToRow: function(row) {
      var minHeight, movingHeight, rowHeight;
      minHeight = $('header').height();
      rowHeight = row * $('section > .item').height();
      movingHeight = rowHeight + minHeight;
      return document.body.scrollTop = movingHeight;
    },
    bind: function() {
      console.log('[mlk] booting...');
      Mulkar.Tumblr.bind();
      new Mulkar.View();
      Mulkar.Leap.bind();
      return console.log('[mlk] booted, baby!');
    }
  };

  Mulkar.Leap = {
    controller: null,
    obtainCoordinates: function(frame) {
      var pointable;
      if (frame.pointables.length !== 1) {
        return null;
      }
      pointable = frame.pointables[0];
      return [$(window).width() / 2 + 6 * pointable.tipPosition[0], $(window).height() - 4 * pointable.tipPosition[1] + $('header[role=page]').height() + 150, pointable.tipPosition[2]];
    },
    setPointer: function(frame) {
      var coords, max_width;
      coords = Mulkar.Leap.obtainCoordinates(frame);
      if (coords == null) {
        return;
      }
      max_width = $(window).width() - ($('#pointer').width() / 2);
      if (coords[0] >= max_width) {
        coords[0] = max_width;
      }
      if (coords[1] <= $('header').height()) {
        coords[1] = $('header').height();
      }
      return $('#pointer').css({
        left: coords[0],
        top: coords[1]
      });
    },
    isPointing: function(frame) {
      return frame.pointables.length === 1 && frame.hands.length === 1;
    },
    isGesturing: function(frame) {
      return frame.gestures.length;
    },
    toggleImageUnderFinger: function(frame) {
      var view;
      return view = Mulkar.Leap.findElementForFinger(frame);
    },
    invokeGestureMovement: function(frame) {
      var gesture;
      console.log(frame);
      gesture = frame.gestures[0];
      if (gesture.type === 'swipe') {
        console.log('swipe', Curtsy.direction(gesture));
        return console.log(Curtsy.direction(gesture).type);
      }
    },
    findElementForFinger: function(frame) {
      var $el, coords;
      coords = Mulkar.Leap.obtainCoordinates(frame);
      $el = $(document.elementFromPoint(coords[0], coords[1]));
      $('.item').removeClass('active');
      $el.parents('.item').addClass('active');
      console.log($el);
      return $el.data('view');
    },
    checkFingerInput: function(frame) {
      if (Mulkar.Leap.isPointing(frame)) {
        Mulkar.Leap.toggleImageUnderFinger(frame);
      }
      if (Mulkar.Leap.isGesturing(frame)) {
        return Mulkar.Leap.invokeGestureMovement(frame);
      }
    },
    bind: function() {
      console.log('[mlk] booting leap...');
      Mulkar.Leap.controller = new Leap.Controller();
      Mulkar.Leap.controller.on('animationFrame', Mulkar.Leap.checkFingerInput);
      Mulkar.Leap.controller.on('animationFrame', Mulkar.Leap.setPointer);
      return Mulkar.Leap.controller.connect();
    }
  };

  Mulkar.Tumblr = {
    images: null,
    bind: function() {
      Mulkar.Tumblr.images = new Mulkar.Tumblr.ImageCollection();
      console.log('[mlk] booting tumblr...');
      Mulkar.Tumblr.images.fetch();
      return console.log('[mlk] booted tumblr, baby!');
    },
    addImage: function(image) {
      var v;
      return v = new Mulkar.Tumblr.ImageView({
        model: image
      });
    },
    ImageModel: Backbone.Model.extend({
      defaults: {
        image: 'the_man.jpg',
        link: 'https://en.wikipedia.org/wiki/Martin_Luther_King,_Jr.',
        user: 'algorithmicalexpansion',
        text: 'Martin Luther King, Jr. was an American pastor, activist, humanitarian, and leader in the African-American Civil Rights Movement'
      }
    }),
    ImageCollection: Backbone.Collection.extend({
      url: '/images'
    }),
    ImageView: Backbone.View.extend({
      tagName: 'div',
      className: 'item',
      tmpl: _.template($('#image-template').html()),
      events: {
        'leap:point': 'expand',
        'leap:leave': 'leave'
      },
      initialize: function() {
        this.listenTo(this.model, 'img load', this.paint);
        return this.listenTo(this.$el, 'click', this.scrollTO);
      },
      paint: function() {
        console.log("[mlk] painting " + (this.model('image').url) + "..");
        return this.$el.css('background-image', "url(" + (this.model('image').url) + ")");
      },
      expand: function() {
        console.log("[mlk] visualing " + (this.model('image').url) + "..");
        return this.$el.addClass('active');
      },
      leave: function() {
        console.log("[mlk] leaving " + (this.model.get('image').url) + "..");
        return this.$el.removeClass('active');
      },
      scrollTo: function() {
        var row;
        row = Math.ceil(this.$el.index() / 5);
        return Mulkar.scrollToRow(row);
      },
      render: function() {
        console.log(this.model);
        this.$el.html(this.tmpl({
          link: this.model.get('link'),
          user: this.model.get('user'),
          text: this.model.get('text'),
          image: this.model.get('image')
        }));
        this.$el.data('view', this);
        return this.$el;
      }
    })
  };

  window.Mulkar = Mulkar;

  $(function() {
    return setTimeout(function() {
      Mulkar.bind();
      return $('body').css('background-image', 'none');
    }, 500);
  });

}).call(this);
