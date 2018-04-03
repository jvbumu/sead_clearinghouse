import { default as CollectionDropdownView } from './utility_views.js';

var RejectCauseView = window.RejectCauseView = Backbone.View.extend({

    initialize: function (options) {
        this.options = options || {};

        this.rejects = this.options.rejects;
        this.reject_entity_types = this.options.reject_entity_types;

        this.model = null;

        this.listenTo(this.reject_entity_types, 'reset', this.renderTypes);
        this.listenTo(this.reject_entity_types, 'change', this.renderTypes);

    },

    events: {
        'change textarea': 'update',
        'change input': 'update',
        'change select': 'update',
        'click #reject-save-button': 'save',
        'click #reject-delete-button': 'delete',
        'click #reject-cancel-button': 'cancel'
    },

    update:  function (event) {

        var data = {};

        data[event.target.name] = event.target.value;

        this.model.set(data);

        utils.set_disabled_state(this.$save_button, false);

    },

    render: function () {

        $(this.el).html(this.template());

        this.$dialog = $("#reject-cause-edit-dialog", this.$el);
        this.$save_button = $("#reject-save-button", this.$el);
        this.$delete_button = $("#reject-delete-button", this.$el);
        this.$cancel_button = $("#reject-cancel-button", this.$el);
        this.$message = $(".dialog-message", this.$el).first();

        utils.set_disabled_state(this.$save_button, true);
        utils.set_disabled_state(this.$delete_button, true);

        return this;
    },

    renderModel: function()
    {
        if (!this.model) {
            return;
        }

        $("#reject_entities", this.$el).html(this.model.get_reject_entity_ids().join(","));
        $("#entity_type_id", this.$el).val((this.model.get("entity_type_id") || 0).toString());
        $("#reject_cause_scope1", this.$el).prop('checked', (this.model.get("reject_scope_id") || 0) == 1);
        $("#reject_cause_scope2", this.$el).prop('checked', (this.model.get("reject_scope_id") || 0) == 2);
        $("#reject_description").val((this.model.get("reject_description") || ""));

        utils.set_disabled_state($("#entity_type_id", this.$el), (this.model.get("submission_reject_id") || 0) > 0);
        utils.set_disabled_state(this.$save_button, true);
        utils.set_disabled_state(this.$delete_button, (this.model.get("submission_reject_id") || 0) == 0);

    },

    renderTypes: function()
    {
        var view = new CollectionDropdownView({
            collection: this.reject_entity_types,
            element_id: "entity_type_id",
            select_class: "form-control",
            item_value_field: "entity_type_id",
            item_text_field: "entity_type"
        });

        $("#entity_type_select_container").html(view.el);

        //view.remove();

        return this;
    },

    open: function(options)
    {

        this.$message.html("");

        this.model = null;

        options = $.extend({ }, this.default_open_options(), options);

        if (options.submission_id && options.submission_id != this.rejects.submission_id) {
            throw "Submission ID mismatch encountered";
        }

        // TODO: Move to controller...
        if (options.reject_cause) {
            this.model = options.reject_cause;
        } else if (options.submission_reject_id > 0) {
            this.model = this.rejects.findWhere( { "submission_reject_id": options.submission_reject_id });
        }

        if (this.model == null) {
            this.model = this.rejects.addReject(options);
        }

        if (this.model.get("submission_reject_id") > 0) {
            this.model.save_revert_point();
        }

        this.renderModel();

        this.$dialog.modal({ keyboard: true, show: true});

    },

    cancel: function()
    {
        if (this.model.get("submission_reject_id") == 0) {
            this.rejects.remove(0);
            //this.rejects.remove({ submission_reject_id: 0 });
        } else {
            this.model.revert_to_save_point();
            this.model = null;
        }
        this.$dialog.modal('hide');
    },

    save: function (e) {

        if (e && e.preventDefault)
            e.preventDefault();

        var self = this;

        this.trigger("save-reject", this.model);

        this.model.save(null, {
            success: function(model, jqXHR, options) {
                self.trigger("reject:saved", model);
                self.$dialog.modal('hide');
            },
            error: function(model, jqXHR, options) {
                self.$message.html(jqXHR.responseText);
            }
        });

    },

    delete: function (e) {

        if (this.model.get("submission_reject_id") === 0) {
            throw "delete on un-saved entity not allowed";
        }

        var self = this;

        this.model.destroy({
            success: function(model, jqXHR, options) {
                self.rejects.remove(model.get("submission_reject_id"));
                self.$dialog.modal('hide');
                self.trigger("reject:deleted", model);
            },
            error: function(model, jqXHR, options) {
                self.$message.html(jqXHR.responseText);
            }
        });

    },

    default_open_options: function() {
        return {
            submission_reject_id: 0,
            submission_id: this.rejects ? (this.rejects.submission_id || 0): 0,
            site_id: SEAD.Router.path.site_id,
            entity_type_id: 0,
            reject_scope_id: 1,
            reject_description: "",
            reject_entities: []
        };
    }

});

window.RejectCauseIndicatorView = Backbone.View.extend({

    events: {
        "click input.reject-checkbox": "clicked"
    },

    template: null,

    initialize: function (options) {

        this.options = options || {};

        _.bindAll(this, "clicked");

        this.template = TemplateStore.get("template_RejectIndicator");
        this.local_db_id = this.options.local_db_id;
        this.entity_type_id = this.options.entity_type_id;
        this.indicator_id_prefix = this.options.indicator_id_prefix;
        this.rejects = this.options.rejects;
        this.checkbox_id = "checkbox_reject_cause_" + this.entity_type_id.toString() + "_" + this.local_db_id.toString();
        this.span_indicator_id = this.indicator_id_prefix + "_" + this.local_db_id.toString();

        this.listenTo(this.rejects, 'sync reset add remove change', this.update_state);

        RejectCauseIndicatorView_Store.add(this);


    },

    clicked: function(e)
    {
        this.trigger('indicator:clicked', this);
    },

    render: function () {

        this.$el.append(
            this.template({
                local_db_id: this.local_db_id,
                entity_type_id: this.entity_type_id,
                indicator_id: this.span_indicator_id,
                checkbox_id: this.checkbox_id
            })
        );

        this.$checkbox= $("#" + this.checkbox_id, this.$el);
        this.$indicator = $("#" + this.span_indicator_id, this.$el);
        this.update_state();

        return this;
    },

    clear_checkbox: function()
    {
         this.$checkbox.prop('checked', false);
    },

    is_checked: function()
    {
         return this.$checkbox.prop('checked');
    },

    set_indicator_state: function(value)
    {
        if (value) {
            this.$indicator.html($("<i/>", { class: "fa fa-minus-sign"}));
        } else {
            this.$indicator.empty();
        }
    },

    update_state: function()
    {
        this.set_indicator_state(this.rejects.contains_entity_id(this.entity_type_id, this.local_db_id));
    }

});

window.RejectCauseIndicatorView_Store = _.extend({

    view_cache: [],

    clear: function() {
        try {
            this.stopListening();
            for (var key in this.view_cache) {
                //this.view_cache[key].undelegateEventsundelegateEvents();
                this.view_cache[key].remove();
                //this.view_cache[key].destroy();
            }
            this.view_cache = [];
        } catch (ex) {
        }
    },

    add: function(view) {
        this.view_cache.push(view);
        this.listenTo(view, "indicator:clicked", this.indicatorClicked);
    },

    indicatorClicked: function(view)
    {
        this.clear_other_entity_type_checkboxes(view.entity_type_id);
        this.trigger('indicator:clicked', view);
    },

    update_states: function()
    {
        try {
            for (var key in this.view_cache) {
                this.view_cache[key].update_state();
            }
        } catch (ex) {
        }
    },

    get_selection: function()
    {
        try {
            var values = [];
            for (var i = 0, x = this.view_cache.length; i < x; i++) {
                if (this.view_cache[i].is_checked()) {
                    values.push({
                        local_db_id: this.view_cache[i].local_db_id,
                        entity_type_id: this.view_cache[i].entity_type_id
                    });
                }
            }
            return values;
            // return _map(
            //     _.filter(this.view_cache,
            //         function (x) { return x.is_checked(); }),
            //     function (x) { return parseInt(x.prop("local_db_id")); }
            // );
        } catch (ex) {
            console.log("RejectCauseIndicatorView_Store.get_selection: " + (ex.message || ex));
            return [];
        }
    },

    has_selection: function()
    {
        for (var i = 0, x = this.view_cache.length; i < x; i++) {
            if (this.view_cache[i].is_checked())
                return true;
        }
        return false;
    },

    clear_checkboxes: function()
    {
        for (var i = 0, x = this.view_cache.length; i < x; i++) {
            if (this.view_cache[i].is_checked()) {
                this.view_cache[i].clear_checkbox();
            }
        }
    },

    clear_other_entity_type_checkboxes: function(entity_type_id_to_keep)
    {
        for (var i = 0, x = this.view_cache.length; i < x; i++) {
            if (this.view_cache[i].is_checked() && this.view_cache[i].entity_type_id != entity_type_id_to_keep) {
                this.view_cache[i].clear_checkbox();
            }
        }
    }

}, Backbone.Events);

var RejectCauseView = window.RejectCauseView,
    RejectCauseIndicatorView = window.RejectCauseIndicatorView,
    RejectCauseIndicatorView_Store = window.RejectCauseIndicatorView_Store;

export { RejectCauseView, RejectCauseIndicatorView, RejectCauseIndicatorView_Store };