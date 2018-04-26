import { default as CollectionDropdownView } from './utility_views.js';

export var UsersView = window.UsersView = Backbone.View.extend({

    users: null,

    initialize: function (options) {

        this.options = options || {};
        this.template = TemplateStore.get("template_UsersView");

        this.users = this.options.users;
        this.role_types = this.options.role_types;
        this.data_provider_grade_types = this.options.data_provider_grade_types;

        this.userView = new UserView({
            role_types: this.role_types,
            data_provider_grade_types: this.data_provider_grade_types
        });

        this.listenTo(this.userView, "user-saved", this.userSaved );

        this.tableView = new UserListView({
            users: this.users,
            role_types: this.role_types
        });

        this.listenTo(this.tableView, "user-selected", this.userSelected);
        this.listenTo(this.tableView, "paging-occurred", this.pagingOccurred);

    },

    events: {
        'click #button-new-user': 'addUser',
    },

    render: function () {

        $(this.el).html(this.template());

        $('#user_list_container', this.$el).html(this.tableView.render().el);
        $("#modal_view_container").html(this.userView.render().el);

        return this;
    },

    userSelected: function(id, index)                   // eslint-disable-line no-unused-vars
    {
        this.openUser(id);
    },

    pagingOccurred: function()
    {
    },

    addUser: function (user_id)                         // eslint-disable-line no-unused-vars
    {
        var user = this.users.create_new_user();
        this.userView.open(user);
    },

    openUser: function (user_id)
    {
        var user = this.users.findWhere({ user_id: user_id });
        this.userView.open(user);
    },

    userSaved: function (e, user)
    {
        if (!this.users.contains(user)) {
            this.users.add_user(user);
        } else
            this.userView.refresh(user);
        console.log("user is saved");
    },

});

export var UserListView = window.UserListView = Backbone.View.extend({

    users : null,
    table: null,

    initialize: function (options) {
        this.options = options || {};
        this.users = options.users;
        this.role_types = this.options.role_types;
        this.listenTo(this.users, "reset", this.render);
        //this.listenTo(this.users, "change", this.render);
    },

    render: function () {

        /*if (!SEAD.User.is_administrator) {
            return this;
        }*/

        var data = this.users.toJSON();

        var placeholder = $("<table>", {
            class: "display table table-sm sead-smaller-font-size",
            id: "users-list",
            cellpadding: "0",
            cellspacing: "0",
            border: "0"
        });

        this.$el.html(placeholder);

        this.table = this.create_table(data);

        return this;
    },

    create_table: function(data)
    {
        var self = this;

        var table =
            $("#users-list", this.$el)
                .bind('page',   function () { self.trigger("paging-occurred"); })
                .dataTable(
                    {
                        "sDom": "T<'clear'><'toolbar'>frtip<'row-fluid'<'span6'l><'span6'f>r>",
                        "aaData": data,
                        "aoColumns": [
                            { "sTitle": "ID", "mData": "user_id", "bVisible": true },
                            { "sTitle": "Username", "mData": "user_name", "sClass": "text-left" },
                            { "sTitle": "Name", "mData": "full_name", "sClass": "text-left" },
                            { "sTitle": "Role", "mData": "role_id", "sClass": "text-center" },
                        ],
                        "aaSorting": [[ 1, "asc" ]],
                        "bPaginate": true,
                        "bLengthChange": false,
                        "bFilter": false,
                        "bSort": true,
                        "bInfo": true,
                        "bAutoWidth": true,
                        "fnCreatedRow": function(row, data, index ) {
                            $(row).attr("id", "rowid_" + data["user_id"].toString());
                            $(row).attr("rowindex", index.toString());
                        },
                        "aoColumnDefs": [ { "aTargets": [ 3 ], "mRender": this._get_role_name(self) } ],
                        select: true

                    }).on('select', function ( e, dt, type, indexes ) {
                    if ( type === 'row' && indexes.length > 0) {
                        var rowData = table.rows( indexes ).data().toArray();
                        self.trigger("user-selected", rowData[0].user_id, indexes[0]);
                    }
                } );

        $(this.el).find("div.toolbar").html(TemplateStore.get("template_user_list_toolbar")());
    },

    _get_role_name: function(self)
    {
        return function (role_id, t, f) {                   // eslint-disable-line no-unused-vars
            return self.role_types.get_role_name(role_id);
        };
    },

    refresh: function(user)
    {
        try {
            var data = user.toJSON();
            this.this.users.findWhere({ user_id: data.user_id}).set(data);
            this.table.fnUpdate(data, this.table.$("#" + "rowid_" + data.user_id.toString())[0]);
        } catch (ex) {
            console.log(ex);
            this.table.fnDraw();
        }
    }

});

export var UserView = window.UserView = Backbone.View.extend({

    initialize: function (options) {

        this.options = options || {};
        this.template = TemplateStore.get("template_UserView");

        this.data_provider_grade_types = this.options.data_provider_grade_types;

        this.user = null;

    },

    events: {
        'change textarea': 'update',
        'change input': 'update',
        'change #password': 'update',
        'change select': 'update',
        'click #edit-user-save-button': 'save',
        'click #edit-user-cancel-button': 'cancel'
    },

    update:  function (event) {
        var data = {};
        if (event.target.type === "checkbox")
            data[event.target.name] = event.target.checked;
        else
            data[event.target.name] = event.target.value;
        if (this.user != null) {
            this.user.set(data);
            this.$save_button.prop("disabled", false);
        }
    },

    render: function () {

        $(this.el).html(this.template());

        this.renderGradeTypes();

        this.$dialog = $("#edit-user-dialog", this.$el);
        this.$save_button = $("#edit-user-save-button", this.$el);
        this.$cancel_button = $("#edit-user-cancel-button", this.$el);

        this.$save_button.prop("disabled", true);

        return this;
    },

    renderGradeTypes: function()
    {
        var view = new CollectionDropdownView({
            collection: this.data_provider_grade_types,
            element_id: "data_provider_grade_id",
            select_class: "form-control",
            item_value_field: "grade_id",
            item_text_field: "description"
        });

        $("#data_provider_grade_select_container", this.$el).html(view.el);

        return this;

    },

    renderModel: function()
    {
        if (!this.user) {
            return;
        }

        var user = this.user.toJSON();

        $("#user_id", this.$el).val((user.user_id || "(new)").toString());
        $("#user_name", this.$el).val((user.user_name || "").toString());
        $("#password", this.$el).val((user.password || "").toString());
        $("#full_name", this.$el).val((user.full_name || "").toString());
        $("#email", this.$el).val((user.email || "").toString());
        $("#signal_receiver", this.$el).prop('checked', user.signal_receiver);

        $("#role_id1", this.$el).prop('checked', (user.role_id || 0) == 1);
        $("#role_id2", this.$el).prop('checked', (user.role_id || 0) == 2);
        $("#role_id3", this.$el).prop('checked', (user.role_id || 0) == 3);

        $("#is_data_provider", this.$el).prop('checked', user.is_data_provider);

        $("#data_provider_grade_id", this.$el).val((user.data_provider_grade_id || 0).toString());

        this.$save_button.prop("disabled", true);

        return this;
    },

    open: function(user)
    {
        this.user = user;

        if (this.user == null) {
            this.user = this.users.create_new_user();
        }

        if (this.user.submission_reject_id > 0) {
            this.user.save_revert_point();
        }
        this.renderModel();

        this.$dialog.modal({ backdrop: 'static', keyboard: true, show: true});

    },

    cancel: function()
    {
        if (this.user.user_id != 0) {
            this.user.revert_to_save_point();
        }
        this.user = null;
        this.$dialog.modal('hide');
    },

    save: function (e) {

        e.preventDefault();

        var self = this;

        this.user.save(null, {
            success: function(model, response, options) {       // eslint-disable-line no-unused-vars

                self.trigger("user-saved", model);
                self.$dialog.modal('hide');

            },
            error: function(model, xhr, options) {
                alert("save failed: " + options);
            }
        });
    }
});

// export {  UserView as UserView, UserListView as UserListView, UsersView as UsersView };