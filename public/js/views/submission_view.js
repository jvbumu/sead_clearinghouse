window.SubmissionView = Backbone.View.extend({

    initialize: function (options) {
        
        this.options = options || {};
        this.submission = this.options.submission;
        
        if (!this.submission) {
            this.breakOut();
            return;
        }
        
        this.submission_metadata_model = this.options.submission_metadata_model;
        this.reports = this.options.reports;
        this.xml_tables_list = this.options.xml_tables_list;
        this.rejects = this.options.rejects;
        this.reject_entity_types = this.options.reject_entity_types;

        this.rejectView = new RejectCauseView({
            rejects: this.rejects,
            reject_entity_types: this.reject_entity_types
        });
        
        var entity_types = this.reject_entity_types;
        var submission_metadata_model = this.submission_metadata_model;
        
        this.rejectsView = new CollectionDropdownView({
            collection: this.rejects,
            element_id: "submission_rejects_select",
            select_class: "form-control input-md danger",
            item_value_field: "submission_reject_id",
            item_text_field: function(item) {
                return submission_metadata_model.getSiteName(item.get("site_id")) +
                        ", " + entity_types.lookup_name(item.get("entity_type_id")) + ": " +
                        item.get("reject_description").threeDotify(25);
            },
            auto_update: true,
            extra: { }, // value: "0", text: "(reject causes)"},
            select_style: "width:50%;"
        });

        this.navigationView = new SubmissionNavigationView( {
            submission_id: this.submission.get("submission_id"),
            submission_metadata_model: this.submission_metadata_model,
            reports: this.reports,
            xml_tables_list: this.xml_tables_list
        } );

        this.listenTo(this.rejectsView, "select:change", this.open_reject_cause);
        this.listenTo(this.rejects, "reset", this.renderButtonStates);
        this.listenTo(this.rejects, "change", this.renderSiteStatus);
        this.listenTo(this.rejects, "reset", this.renderSiteStatus);
        this.listenTo(this.submission, "change", this.renderButtonStatus);
        
        this.listenTo(RejectCauseIndicatorView_Store, "indicator:clicked", this.reject_check_clicked);
        
        this.listenTo(this.rejectView, "reject:saved", this.rejectSaved);
        this.listenTo(this.rejectView, "reject:deleted", this.rejectDeleted);
        
        this.render();   

    },
            
    events: {
        'click #button-accept-submission': 'accept',
        'click #button-reject-submission': 'reject',
        "click #button-add-reject-cause": "add_reject_cause",
        "click #button_tree_slider": "collapse_view_port"
    },
    
    breakOut: function () {
        SEAD.Router.navigate("", {trigger: true});
    },

    rejectSaved: function(e)
    {
        console.log("reject:saved");
        RejectCauseIndicatorView_Store.clear_checkboxes();
    },

    rejectDeleted: function()
    {
        console.log("reject:deleted");
    },

    render: function () {

        this.$el.html(this.template());

        this.$accept_button = $("#button-accept-submission", this.$el);
        this.$reject_button = $("#button-reject-submission", this.$el);
        this.$add_reject_button = $("#button-add-reject-cause", this.$el);

        $("#submission_navigation_tree_container", this.$el).html(this.navigationView.render().el);
        $("#reject_modal_view_container", this.$el).html(this.rejectView.render().el);
        $("#submission_rejects_container", this.$el).html(this.rejectsView.el);
        
        this.$sidebar = $("#submission_navigation_tree", this.$el);
        this.$viewport = $("#submission_navigation_viewport", this.$el);

        utils.set_disabled_state(this.$add_reject_button, true);
        //this.render_button_states();
        
        return this;
    },
    
    renderRejects: function()
    {
    },
    
    renderButtonStates: function()
    {
        try {
            utils.set_disabled_state(this.$accept_button, !SEAD.Security.fn_can_accept_submission(this.submission, this.rejects)); 
            utils.set_disabled_state(this.$reject_button, !SEAD.Security.fn_can_reject_submission(this.submission, this.rejects)); 
        } catch (ex) {
            console.log(ex.message || ex);
        }
    },
    
    renderSiteStatus: function()
    {
        this.navigationView.renderSiteStatus(this.rejects);
    },   
    
    collapse_view_port:  function() {
        utils.toggle_collapsable_view_port(this.$sidebar, this.$viewport, "col-sm-4", "col-sm-8", "col-sm-12");
    },
            
    accept: function()
    {
        var view = new AcceptView({
            template_name: "template_AcceptView",
            submission_id: this.submission.get("submission_id"),
            dialog_id: "accept-dialog"
        });
        $("#modal_view_container").html(view.render().el);
        view.open();
    },

    reject: function()
    {
         var view = new RejectView({
            submission_id: this.submission.get("submission_id"),
            dialog_id: "reject-dialog"
        });
        $("#modal_view_container").html(view.render().el);
        view.open();
    },
    
    reject_check_clicked: function(a,b)
    {
        if (!SEAD.Security.fn_can_add_reject_cause(this.submission)) {
            return;
        }
        utils.set_disabled_state(this.$add_reject_button, !RejectCauseIndicatorView_Store.has_selection()); 
    },
    
    add_reject_cause: function() {
        
        var selected_values = RejectCauseIndicatorView_Store.get_selection();
        
        if (selected_values.length === 0) {
            return;
        }
    
        var reject_entities = _.map(
            _.where(selected_values, { entity_type_id: selected_values[0].entity_type_id }),
            function (x) {
                return {
                    "reject_entity_id": 0,
                    "submission_reject_id": 0,
                    "local_db_id": x.local_db_id
                };
            }
         )
        
        this.rejectView.open({
            submission_id: this.submission.get("submission_id"),
            site_id: SEAD.Router.path.site_id,
            reject_entities: reject_entities,
            entity_type_id: selected_values[0].entity_type_id
        });
    },
    
    edit_reject_cause: function() {

        this.rejectView.open({ submission_id: this.submission.get("submission_id") });
        
    },
    
    open_reject_cause: function(submission_reject_id) {

        var reject_cause = this.rejects.findWhere({"submission_reject_id" : parseInt(submission_reject_id)});
        if (!reject_cause) {
            console.log("Error: Reject cause not found in collection!");
            return;
        }
        this.rejectView.open({ reject_cause: reject_cause });
        
    }

});



