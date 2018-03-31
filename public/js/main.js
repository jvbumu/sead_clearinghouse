

var AppRouter = Backbone.Router.extend({

    path: {},

    setPath: function(submission_id, site_id, sample_group_id, sample_id) {
        this.path = {
            submission_id: parseInt(submission_id),
            site_id: parseInt(site_id),
            sample_group_id: parseInt(sample_group_id),
            sample_id: parseInt(sample_id)
        };
    },

    routes: {
        ""                                                                                              : "home",
        "submission/:id/open"                                                                           : "openSubmission",
        "signon"                                                                                        : "login",
        "logout"                                                                                        : "logout",
        "about"                                                                                         : "about",
        "submission/:submission_id/site/:site_id"                                                       : "openSite",
        "submission/:submission_id/site/:site_id/sample_group/:sample_group_id"                         : "openSampleGroup",
        "submission/:submission_id/site/:site_id/sample_group/:sample_group_id/sample/:sample_id"       : "openSample",
        "submission/:submission_id/site/:site_id/sample_group/:sample_group_id/dataset/:dataset_id"     : "openDataSet",
        "reports/execute/:report_id/:submission_id"                                                     : "openReport",
        "submission/:submission_id/table/:table_id"                                                     : "openTable",
        "users"                                                                                         : "editUsers"

    },

    initialize: function () {

        this.headerView = new HeaderView();
        $('.header').html(this.headerView.el);

        this.footerView = new FooterView();
        $('.footer').html(this.footerView.el);

        var genericErrorCallback = this.displayError;

        $(document).ajaxError(function(e, jqxhr, settings, exception) {
            if (jqxhr.status == 500) {
                genericErrorCallback(jqxhr.responseText);
            }
            console.log(e);
        });

        this.initialize_spinner("spinner_center", "spinner");

        this.submissions = new SubmissionCollection();

    },

    initialize_spinner: function(spinnerId, spinnerClass)
    {
        var opts = {
           lines: 13, // The number of lines to draw
           length: 7, // The length of each line
           width: 4, // The line thickness
           radius: 10, // The radius of the inner circle
           rotate: 0, // The rotation offset
           color: '#efefef', // #rgb or #rrggbb
           speed: 0.75, // Rounds per second
           trail: 50, // Afterglow percentage
           shadow: true, // Whether to render a shadow
           hwaccel: false, // Whether to use hardware acceleration
           className: spinnerClass, // The CSS class to assign to the spinner
           zIndex: 2e9, // The z-index (defaults to 2000000000)
           top: 'auto', // Top position relative to parent in px
           left: 'auto' // Left position relative to parent in px
        };
        var spinner = new Spinner({ }, $("#" + spinnerId));

        $(document).ajaxStart(function() {
           $("<div/>", { id: spinnerId, class: spinnerClass }).appendTo('body');
           spinner.spin($("#" + spinnerId)[0]);
        });

        $(document).ajaxStop(function() {
            spinner.stop();
            $("#" + spinnerId).remove();
        });
    },

    home: function() {

        this.setPath(0,0,0,0);

        if (SEAD.User == null) {
            SEAD.Router.navigate("signon", {trigger: true});
            return;
        }

        var submissions = this.submissions;

        this.submissions.fetch({
            success: function() { $("#content").html(new HomeView({ items: submissions }).el); }
       });

        this.headerView.selectMenuItem('home-menu');
    },

    login: function()
    {
        this.setPath(0,0,0,0);

        var loginView = new LoginView();

        $("#modal_view_container").html(loginView.render().el);

        var self = this;
        this.listenTo(loginView, "login-success",
            function (e, u) {
                loginView.close();
                self.headerView.setName(SEAD.User.user_name);
                SEAD.Router.navigate("", {trigger: true});
            }
        );
        loginView.open();
    },

    logout: function()
    {
        var logoutView = new LogoutView();
        $("#logout_modal_view_container").html(logoutView.render().el);
        this.listenTo(logoutView, "logout-success",
            function (e, u) {
                logoutView.close();
                SEAD.Router.navigate("", {trigger: true});
            }
        );
        logoutView.open();
    },

    about: function () {

        if (!this.aboutView) {
            this.aboutView = new AboutView();
        }

        $('#content').html(this.aboutView.el);
        this.headerView.selectMenuItem('about-menu');
    },

    openSubmission: function(id) {

        var submission_id = parseInt(id);

        this.setPath(submission_id,0,0,0);

        this.current_path = { submission_id: submission_id };

        this.submission_metadata_model = new SubmissionMetaDataModel({ submission_id: submission_id });
        this.rejects = new SubmissionRejectCollection([], { submission_id: submission_id });
        this.reject_entity_types = new RejectEntityTypesCollection();

        this.reports = new ReportCollection();
        this.xml_tables_list = new XmlTableCollection([], { submission_id: submission_id });

        $("#content").html(new SubmissionView({
            submission: this.submissions.findWhere({ submission_id: submission_id }),
            submission_metadata_model: this.submission_metadata_model,
            rejects: this.rejects,
            reject_entity_types: this.reject_entity_types,
            reports: this.reports,
            xml_tables_list: this.xml_tables_list
        }).el);

        this.submission_metadata_model.fetch({ reset: true });
        this.rejects.fetch({ reset: true });
        this.xml_tables_list.fetch({ reset: true });

        this.reject_entity_types.reset(SEAD.BootstrapData.Lookup.RejectTypes);
        this.reports.reset(SEAD.BootstrapData.Reports);

    },

    openReport: function(report_id, submission_id) {

        this.current_path = { submission_id: submission_id };

        this.report_data = new ReportResultCollection([], { report_id: parseInt(report_id), submission_id: parseInt(submission_id) });

        $("#data_container").html(new ReportView({
            report_id: parseInt(report_id),
            submission_id: parseInt(submission_id),
            report_data: this.report_data,
            rejects: this.rejects
        }).render().el);

        this.report_data.fetch({
                reset: true,
                complete: function(xhr, textStatus) {
                  console.log(textStatus);
                }
        });

    },

    openTable: function(submission_id, table_id) {

        this.setPath(submission_id,0,0,0);

        this.table_data = new XmlTableRowCollection([], { table_id: parseInt(table_id), submission_id: parseInt(submission_id) });

        $("#data_container").html(new ReportView({
            report_id: parseInt(table_id),
            submission_id: parseInt(submission_id),
            report_data: this.table_data,
            rejects: null
        }).render().el);

        this.table_data.fetch({ reset: true });

    },

    openSite: function(submission_id, site_id) {

        this.setPath(submission_id, site_id, 0, 0);

        var self = this;

        this.site_data = new SiteDataModel({
            submission_id: parseInt(submission_id),
            site_id: parseInt(site_id)
        });

        var view = new SiteView({
            model: this.site_data,
            rejects: this.rejects,
            target: "#data_container"
        });

        $("#data_container").html(view.render().el);

        $.ajax({
            url: "api/submission/" + submission_id + "/site/" + site_id,
            dataType: "json"
        }).done(
            function (data) {
                self.site_data.set(data, {reset: true});
            }
        );

    },

    openSampleGroup: function(submission_id, site_id, sample_group_id) {

        this.setPath(submission_id, site_id, sample_group_id, 0);

        this.sample_group_data = new SampleGroupDataModel({
            submission_id: parseInt(submission_id),
            site_id: parseInt(site_id),
            sample_group_id: parseInt(sample_group_id)
        });

        var view = new SampleGroupView({
            model: this.sample_group_data,
            rejects: this.rejects,
            target: "#data_container"
        });

        $("#data_container").html(view.render().el);

        var model = this.sample_group_data;

        $.ajax({
            url: "api/submission/" + submission_id.toString() +
                    "/site/" + site_id.toString() +
                    "/sample_group/" + sample_group_id.toString(),
            dataType: "json"
        }).done(
            function (data) {
                model.set(data, {reset: true});
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ){
                console.log(jqXHR.responseText);
            }
        );
    },

    openSample: function(submission_id, site_id, sample_group_id, sample_id) {

        this.setPath(submission_id, site_id, sample_group_id, sample_id);

        this.sample_data = new SampleDataModel({
            submission_id: parseInt(submission_id),
            site_id: parseInt(site_id),
            sample_group_id: parseInt(sample_group_id),
            sample_id: parseInt(sample_id)
        });

        var view = new SampleView({
            model: this.sample_data,
            rejects: this.rejects,
            target: "#data_container"
        });

        $("#data_container").html(view.render().el);

        //this.sample_data.fetch({ reset: true });

        var model = this.sample_data;

        $.ajax({
            url: "api/submission/" + submission_id.toString() +
                    "/site/" + site_id.toString() +
                    "/sample_group/" + sample_group_id.toString() +
                    "/sample/" + sample_id.toString(),
            dataType: "json"
        }).done(
            function (data) {
                model.set(data, {reset: true});
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ){
                console.log(jqXHR.responseText);
            }
        );

    },

    openDataSet: function(submission_id, site_id, sample_group_id, dataset_id) {

        this.setPath(submission_id, site_id, sample_group_id, 0);

        this.dataset_data = new DataSetDataModel({
            submission_id: parseInt(submission_id),
            site_id: parseInt(site_id),
            sample_group_id: parseInt(sample_group_id),
            dataset_id: parseInt(dataset_id)
        });

        $("#data_container").html(new DataSetView({
            model: this.dataset_data,
            rejects: this.rejects,
            target: "#data_container"
        }).render().el);

        var model = this.dataset_data;

        $.ajax({
            url: "api/submission/" + submission_id.toString() +
                    "/site/" + site_id.toString() +
                    "/sample_group/" + sample_group_id.toString() +
                    "/dataset/" + dataset_id.toString(),
            dataType: "json"
        }).done(
            function (data) {
                model.set(data, {reset: true});
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ){
                console.log(jqXHR.responseText);
            }
        );

    },

    editUsers: function()
    {

        this.setPath(0, 0, 0, 0);

        var users = new UserCollection();

        var role_types = new RoleTypeCollection();
        var data_provider_grade_types = new DataProviderGradeTypeCollection();

        role_types.reset(SEAD.BootstrapData.Lookup.RoleTypes);
        data_provider_grade_types.reset(SEAD.BootstrapData.Lookup.DataProviderGradeTypes);

        var usersView = new UsersView({
            users: users,
            role_types: role_types,
            data_provider_grade_types: data_provider_grade_types
        });

        $('#content').html(usersView.render().el);

        users.fetch({reset: true});
    },

    displayError: function(text)
    {
        var view = new ErrorView({ dialog_id: "error-dialog", error_message: text });
        $("#error_modal_view_container").html(view.render().el);
        view.open();
    }

});

var SEAD = {
    Router: null,
    BootstrapData: null,
    User: null,
    Session: null,
    Security: SecurityFunctions
};

$(function() {

    fetch('/api/bootstrap')
    .then(function(response) { return response.json(); })
    .then(function(json) {
        SEAD.BootstrapData = json;
    });

    TemplateStore.preload([
            { name: 'HeaderView', type: "view" },
            { name: 'FooterView', type: "view" },
            { name: 'HomeView', type: "view" },
            { name: 'SubmissionView', type: "view" },
            { name: 'AboutView', type: "view" },
            { name: 'SiteView', type: "view" },
            { name: 'SampleView', type: "view" },
            { name: 'DataSetView', type: "view" },
            { name: 'SampleGroupView', type: "view" },
            { name: 'RejectCauseView', type: "view" },
            { name: 'Templates', type: "templates" }
        ], function() {
        SEAD.Router = new AppRouter();
        Backbone.history.start();
    });


});
