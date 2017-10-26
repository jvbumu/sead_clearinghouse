window.XClaimView = Backbone.View.extend({
    
    initialize: function (options) {
        this.action = options.action;
        this.submission = options.submission;
        this.template = TemplateStore.get("template_XClaimSubmissionView");
        this.render();
    },
            
    events: {
        'click #xclaim-submission-button': 'xclaim'
    },
    
    render: function () {
        
        $(this.el).html(this.template({ claim: this.action }));
        
        this.$dialog = $("#xclaim-submission-dialog", this.$el);
        this.$xclaim_button = $("#xclaim-submission-button", this.$el);
        this.$xclaim_message = $("#xclaim-message", this.$el);

        this.$xclaim_button.prop("disabled", false);

        return this;
    },
 
    open: function()
    {  
        this.$dialog.modal({ backdrop: 'static', keyboard: true, show: true});   
    },

    xclaimed: function(data)
    {  
        this.$xclaim_message.text("Claimed!");
        this.$dialog.modal('hide');
        this.$dialog.data('modal', null);
        this.trigger("submission-xclaimed", data, this.action);
    },
    
    xclaim: function (e) {

        this.$xclaim_button.prop("disabled", true);
        
        e.preventDefault();
        
        var url = "api/submission/" + this.submission.get("submission_id").toString() + "/" + this.action;
        var self = this;
        
        this.$xclaim_message.text("Executing...");
        
        $.ajax({
            type: "GET",
            url: url,
            dataType: "json",
            data: { "submission_id": this.submission.get("submission_id")}
        }).done(
            function(submission, textStatus, jqXHR ) {
                self.xclaimed(submission);
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ){
                self.$xclaim_message.text(
                    "Action failed [" + (textStatus || "") + "] " + (errorThrown || "").toString()
                );
                console.log(jqXHR.responseText);
            }
        );

    }
    
});
