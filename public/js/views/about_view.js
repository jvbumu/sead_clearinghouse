window.AboutView = Backbone.View.extend({

    initialize:function () {
        this.render();
    },

    render:function () {
        $(this.el).html(this.template({ sead_twitter: "@seadtwitter" }));
        return this;
    }

});