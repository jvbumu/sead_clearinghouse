window.HeaderView = Backbone.View.extend({

    initialize: function () {
        
        //this.loginView = new LoginView();
        //this.listenTo(this.loginView, "login_completed", this.login_completed);
        //this.listenTo(this.loginView, "login_failed", this.login_failed);
        this.render();
                
    },

    render: function () {

        $(this.el).html(this.template());

        //$(this.el).find("#login-container").html(this.loginView.render().el);
        
        $(this.el).find('.dropdown-toggle').dropdown();

        $(this.el).find('.dropdown input, .dropdown label').click(function(e) {
          e.stopPropagation();
        });

        return this;
    },

    selectMenuItem: function (menuItem) {
        $('.nav li').removeClass('active');
        if (menuItem) {
            $('.' + menuItem).addClass('active');
        }
    },
            
//    login_completed: function(user)
//    {
//        //alert("Signed " + user.name + " in!");
//        AppRouter.navigate("", {trigger: true});
//    },
//    
//    login_failed: function(reason)
//    {
//        alert("Sign on failed: " + reason );
//    },
    
    setName: function(name)
    {
        try {
            $("#login_user_name", this.$el).html(name || "");
        } catch (ex) {
        }
    }

});