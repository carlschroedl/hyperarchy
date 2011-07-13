_.constructor("Views.Components.Avatar", View.Template, {
  content: function() { with(this.builder) {
    div({'class': "avatar"});
  }},

  viewProperties: {
    initialize: function() {
      if (!this.imageSize) throw new Error("No image size");
      this.css('height', this.imageSize);
      this.css('width', this.imageSize);
    },

    user: {
      change: function(user) {
        this.removeClass("valid-avatar");
        this.empty();
        this.img = $(new Image());
        this.img.height(this.imageSize);
        this.img.width(this.imageSize);
        this.img
          .load(this.hitch('imageLoaded'))
          .attr('src', user.avatarUrl(this.imageSize));
      }
    },

    imageLoaded: function() {
      this.addClass("valid-avatar")
      this.append(this.img);
    }
  }
});