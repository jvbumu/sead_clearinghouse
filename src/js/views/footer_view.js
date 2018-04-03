var FooterView = window.FooterView = Backbone.View.extend({

    initialize: function (options) {
        this.options = options || {};
        this.render();
    },

    render: function () {
        $(this.el).html(this.template());
        return this;
    }

});

export default FooterView;