var BaseDialogView = window.BaseDialogView = window.Backbone.View.extend({

    events: {
        'click .dialog-execute-button': 'execute'
    },

    initialize: function (options) {
        this.options = options || {};
    },

    open: function()
    {
        this.$dialog.modal({ backdrop: 'static', keyboard: false, show: true});
    },

    close: function()
    {
        try {
            if (this.$dialog) {
                this.$dialog.modal('hide');
                this.$dialog.data('modal', null);
            }
        } catch (ex) {
            console.log(ex);
        }
    },

    render: function () {

        var template = TemplateStore.get(this.template_name);

        this.$el.html(template());

        this.$dialog = $("#" + this.options.dialog_id, this.$el);
        this.$message = $(".dialog-message", this.$el).first();
        this.$execute_button = $(".dialog-execute-button", this.$el).first();

        if (this.render_details) {
            this.render_details();
        }

        return this;
    },

    execute: function() {

    }

});

var AcceptOrRejectView = window.AcceptOrRejectView = window.BaseDialogView.extend({

    getUrl: function()
    {
        return "api/submission/" + this.options.submission_id.toString() + "/" + this.call_action;
    },

    execute: function (e) {

        e.preventDefault();

        utils.set_disabled_state(this.$execute_button, true);

        var self = this;
        var url = this.getUrl();

        $.ajax({ type: "GET", url: url, dataType: "json"})
            .done(
            function(data) {
                self.trigger("execute-success", data);
                self.close();
            }
        ).fail(
            function (jqXHR, message, errorThrown ){
                self.trigger("execute-failure", message);
                self.close();
                console.log(jqXHR.responseText);
            }
        );
    }

});

var AcceptView = window.AcceptView = window.AcceptOrRejectView.extend({

    template_name:  "template_AcceptView",
    call_action:    "accept"

});

var RejectView = window.RejectView = window.AcceptOrRejectView.extend({

    template_name: "template_RejectView",
    call_action:    "reject"

});

var ErrorView = window.ErrorView = window.BaseDialogView.extend({

    template_name: "template_ErrorView",

    render_details: function ()
    {
        this.$message.html(this.options.error_message);
        return this;
    },

    execute: function (e) {
        this.close();
        SEAD.Router.navigate("", { trigger: true });
    }

});

var LoginView = window.LoginView = Backbone.View.extend({

    initialize: function (options) {
        this.options = options || {};
        this.template = TemplateStore.get("template_LoginView");
    },

    events: {
        'click #login-button': 'login'
    },

    render: function () {

        $(this.el).html(this.template());

        this.$dialog = $("#login-dialog", this.$el);
        this.$login_button = $("#login-button", this.$el);
        this.$message = $("#login-message", this.$el);

        window.utils.setEnterHandler($("#LoginView",this.el), "keypress", $.proxy(this.login, this));

        return this;
    },

    open: function()
    {
        this.$dialog.modal({ backdrop: 'static', keyboard: false, show: true});
    },

    close: function()
    {
        try {
            if (this.$dialog) {
                this.$dialog.modal('hide');
                this.$dialog.data('modal', null);
            }
        } catch (ex) {
            console.log(ex);
        }
    },

    login: function (e) {

        if (e && e.preventDefault) {
            e.preventDefault();
        }

        var username = $("#user_username", this.$el).val();
        var password = $("#user_password", this.$el).val();

        if (username === "" || password === "") {
            this.$message.text("Please enter username and password");
            return;
        }

        var self = this;

        this.$message.text( "Logging in..." );

        this.$login_button.prop("disabled", true);

        $.ajax({
            type: "GET",
            url: "api/login",
            dataType: "json",
            data: { "username": username, "password":  password }
        }).done(
            function(data){
                if (data.error) {
                    self.$message.text(data.error);
                    self.$login_button.prop("disabled", false);
                    return;
                }
                SEAD.User = data.user;
                SEAD.Session = data.session;
                $.extend(SEAD.Security, data.security);
                self.trigger("login-success", data.user);
            }
        ).fail(
            function ( jqXHR, message, errorThrown ){
                self.$message.html(jqXHR.responseText);
                self.$login_button.prop("disabled", false);
                console.log(jqXHR.responseText);
            }
        );

    }

});

var LogoutView = window.LogoutView = Backbone.View.extend({

    initialize: function (options) {
        this.options = options || {};
        this.template = TemplateStore.get("template_LogoutView");
    },

    events: {
        'click #logout-button': 'logout'
    },

    render: function () {

        $(this.el).html(this.template());

        this.$dialog = $("#logout-dialog", this.$el);
        this.$logout_button = $("#logout-button", this.$el);
        this.$message = $("#logout-message", this.$el);

        window.utils.setEnterHandler(this.$dialog, "keydown", $.proxy(this.logout, this));

        return this;
    },

    open: function()
    {
        this.$dialog.modal({ backdrop: 'static', keyboard: false, show: true});
    },

    close: function()
    {
        try {
            if (this.$dialog) {
                this.$dialog.modal('hide');
                this.$dialog.data('modal', null);
            }
        } catch (ex) {
            console.log(ex);
        }
    },

    logout: function (e) {

        var self = this;

        if (e && e.preventDefault) {
            e.preventDefault();
        }

        utils.set_disabled_state(this.$logout_button, true);

        $.ajax({ type: "GET", url: "api/logout", dataType: "json"})
            .done(
                function(data){
                    SEAD.User = null;
                    SEAD.Session = null;
                    self.trigger("logout-success");
            }).fail(
                function (jqXHR, message, errorThrown ){
                    SEAD.User = null;
                    SEAD.Session = null;
                    self.$message.html(jqXHR.responseText);
                    console.log(jqXHR.responseText);
                    self.trigger("logout-success");
                }
            );

    }

});

export {
    BaseDialogView, AcceptOrRejectView, AcceptView, RejectView, ErrorView, LoginView, LogoutView
};
