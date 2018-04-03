var AboutView = window.AboutView = Backbone.View.extend({

    initialize:function (options) {
        this.options = options || {};
        this.render();
    },

    render:function () {
        $(this.el).html(this.template({ sead_twitter: "@seadtwitter" }));
        return this;
    }

});

export default AboutView;