window.ReviewView = Backbone.View.extend({

    initialize: function (options) {
        this.options = _.extend(this.options || {}, options || {});
    },

    set_review_value: function ($id, local_value, public_value) {
        $id.text(local_value || "");
        if (public_value !== null) {
            if ((local_value || "") != (public_value || "")) {
                $id.attr("data-content", public_value);
                $id.addClass("sead-tooltip");
                $id.addClass("sead-updated-value");
            } else {
                $id.addClass("sead-existing-value");
            }
        } else {
            $id.addClass("sead-new-value");
        }
    }

});

window.ReviewBaseView = window.ReviewView.extend({

    //initialize: function (options) {
    //    this.options = _.extend(this.options || {}, options || {});
    //},

    initialize: function (options) {

        this.options = _.extend(this.options || {}, options || {});
        this.model = this.options.model;
        this.rejects = this.options.rejects;

        this.listenTo(this.model, 'change', this.render_model);

        RejectCauseIndicatorView_Store.clear();

    },

    render_tables: function(model, store)
    {
        var table_options = Table_Template_Store.get_table_options(store);
        this.table_views = [];
        for (var key in table_options) {
            var data = model[table_options[key].data_key];
            var items = data ? (data.data || data) : [];
            if (items.length == 0) {
                $(table_options[key].container, this.$el).hide();
                continue;
            }

            var $panel = Bootstrap_Panel_Table_Container_Builder.build(store.data_type, table_options[key].data_key, table_options[key].data_key.pascalCase().pascalCaseToWords(), (data.data || data).length);

            $("#" + store.data_type + "_accordion", this.$el).append($panel);

            var view = new ReviewTableView($.extend(table_options[key].options, { rejects: this.rejects, data: data }));

            $(table_options[key].target, this.$el).html(view.render().el);

            this.table_views.push(view);

            var indicator_options = $.extend(table_options[key].indicator_option, {
                rejects: this.rejects,
                entity_type_id: utils.getEntityTypeOf(data)
            });
            $(indicator_options.target, this.$el).html(new RejectCauseIndicatorView(indicator_options).render().el);

        }
        return this;
    },

    render: function () {

        this.$el.html(this.template());

        return this;
    },

    render_model: function()
    {
        try {
            var model = this.model.toJSON();

            this.render_root(model);
            this.render_tables(model, this.get_store());
            this.render_indicator(model);

            $(".sead-tooltip").popover({
                trigger: "click",
                placement: "auto left",
                title: "Value in public SEAD database"
            });

        } catch (ex) {
            console.log(ex.message || ex);
        }

    },

    render_indicator: function(model)
    {
        if (!this.rejects) {
            return;
        }

        var $container = $("#" + this.get_store().data_type + "_indicator_container", this.$el);

        if ($container.length == 0) {
            return;
        }

        $container.html(new RejectCauseIndicatorView({
                local_db_id: model.local_db_id,
                entity_type_id: model.entity_type_id,
                indicator_id_prefix: "generic_" + this.get_store().data_type + "_indicator",
                rejects: this.rejects
            }).render().el
        );

    }

});

window.Bootstrap_Panel_Table_Container_Builder = {

    default_collapse_state: "", /* use "in" for default open state */

    build: function(data_type, data_key, title, count)
    {
        var collapse_id = data_type + "_" + data_key + "_collapse";
        var container_id = data_type + "-" + data_key + "-container";
        var indicator_container_id =  data_type + "_" + data_key + "_generic_indicator_container";
        var table_container_id =  data_type + "_" + data_key + "_table_container";

        var $heading = $("<div/>", { class: "panel-heading" })
                .append($("<h4/>", { class: "panel-title row" })
                          .append($("<span>", { id: indicator_container_id, class: "col-md-1" }))
                          .append($("<a/>", { text: title, class: "accordion-toggle", "data-toggle": "collapse", "data-parent": "#accordion2", href: "#" + collapse_id }))
                          .append($("<span/>", {
                              class: "badge pull-right " + (count > 0 ? "sead-badge-data-exists" : ""),
                                 id: data_type + "_" + data_key + "_badge",
                               text: count,
                               style: "margin-right: 10px;"
                           }))
                );

        var $body = $("<div/>", { id: collapse_id, class: "panel-collapse collapse " + this.default_collapse_state })
            .append($("<div/>", { class: "panel-body" })
                .append($("<div/>", { id: table_container_id }))
          );

        return $("<div/>", { id: container_id,class: "panel panel-default" })
            .append($heading)
            .append($body);

    }
};

