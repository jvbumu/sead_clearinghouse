window.TransferView = Backbone.View.extend({
    
    initialize: function (options) {
        this.users = options.users;
        this.submission = options.submission;
        this.template = TemplateStore.get("template_TransferSubmissionView");
        this.listenTo(this.users, "reset", this.renderUsers);
        //this.render();
    },
            
    events: {
        'click #transfer-submission-button': 'transfer',
        'change #transfer_user_id': 'update'
    },
    
    render: function () {
        
        $(this.el).html(this.template());
        
        this.$dialog = $("#transfer-submission-dialog", this.$el);
        this.$transfer_button = $("#transfer-submission-button", this.$el);
        this.$message = $("#transfer-message", this.$el);

        this.$transfer_button.prop("disabled", false);

        //this.renderUsers();

        utils.set_disabled_state(this.$transfer_button, true);
                
        return this;
    },

    renderUsers: function()
    {
        var view = new CollectionDropdownView({
            collection: this.users,
            element_id: "transfer_user_id",
            select_class: "form-control",
            item_value_field: "user_id",
            item_text_field: "full_name",
            auto_update: true,
            extra: { text: "(select user)", value: 0 }
        });
        
        $("#transfer_user_id_select_container", this.$el).html(view.el);
        
        return this;
        
    },
    
    update: function()
    {
        utils.set_disabled_state(this.$transfer_button, event.target.value == 0);
    },
    
    open: function()
    {  
        this.$dialog.modal({ keyboard: true, show: true});   
    },

    transfered: function(data)
    {  
        this.$message.text("Transfered!");
        this.$dialog.modal('hide');
        this.$dialog.data('modal', null);
        this.trigger("submission-transfered", data);
    },
    
    transfer: function (e) {

        utils.set_disabled_state(this.$transfer_button, true);
        
        e.preventDefault();
        
        var url = "api/submission/" + this.submission.get("submission_id").toString() + "/transfer";
        var self = this;
        
        var transfer_user_id = $("#transfer_user_id", this.$el).val();
        
        if (transfer_user_id != 0) {
            this.$message.text("Please select user...");
            return;
        }
        
        this.$message.text("Executing...");
        
        $.ajax({
            type: "GET",
            url: url,
            dataType: "json",
            data: { "submission_id": this.submission.get("submission_id"), user_id: transfer_user_id }
        }).done(
            function(submission, textStatus, jqXHR ) {
                self.transfered(submission);
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ){
                self.$message.text(
                        "Action failed [" + (textStatus || "") + "] " + (errorThrown || "").toString()
                );
                console.log(jqXHR.responseText);
            }
        );

    }
});
