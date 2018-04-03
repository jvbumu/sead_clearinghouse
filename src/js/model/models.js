export var Submission = window.Submission = Backbone.Model.extend({

    initialize: function () {
        this.validators = {};
        //        this.validators.name = function (value) {
        //            return value.length > 0 ? {isValid: true} : {isValid: false, message: "You must enter a name"};
        //        };
    },

    defaults: {
        id: null,
        data_provider_name: "",
        proxy_type: "",
        status: "",
        data_provider_grade: "",
        submission_date: null
    }

});

export var SubmissionCollection = window.SubmissionCollection = Backbone.Collection.extend({
    model: Submission,
    url: "api/submissions_report"
});

export var Site = window.Site = Backbone.Model.extend({
    initialize: function () {
        this.validators = {};
        //        this.validators.submission_id = function (value) {
        //            return submissionId != 0 ? {isValid: true} : {isValid: false, message: "Submission ID cannot be null"};
        //        };
    },

    defaults: {
        id: null,
        submissionId: 0,
        name: "",
    }
});

export var SiteCollection = window.SiteCollection = Backbone.Collection.extend({
    model: Site,
    url: "api/sites"
    //url: function () { return "api/sites/" + this.submissionId + "/" + sites; }
});

export var SubmissionSiteCollection = window.SubmissionSiteCollection = Backbone.Collection.extend({
    model: Site,
    initialize: function(models, options) {
        options = $.extend({}, options);
        this.submission_id = (options.submission_id || 0);
    },

    url: function () {
        return "api/submissions/" + this.submission_id.toString() + "/sites";
    }
});

export var Report = window.Report = Backbone.Model.extend({
});

export var ReportCollection = window.ReportCollection = Backbone.Collection.extend({
    model: Report,
    url: "api/reports/toc"
});

export var ReportResultRow = window.ReportResultRow = Backbone.Model.extend({

});

export var ReportResultCollection = window.ReportResultCollection = Backbone.Collection.extend({
    model: ReportResultRow,

    initialize: function(models, options) {
        options = $.extend({}, options);
        this.report_id = (options.report_id || 0);
        this.submission_id = (options.submission_id || 0);
    },

    url: function () {
        return "api/reports/execute/" + this.report_id.toString() + "/" + this.submission_id.toString();
    }
});

export var XmlTableCollection = window.XmlTableCollection = Backbone.Collection.extend({
    initialize: function(models, options) {
        this.options = $.extend({ submission_id: 0}, options);
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString()+ "/tables";
    }
});

export var XmlTableRow = window.XmlTableRow = Backbone.Model.extend({

});

export var XmlTableRowCollection = window.XmlTableRowCollection = Backbone.Collection.extend({
    model: XmlTableRow,

    initialize: function(models, options) {
        this.options = $.extend({ table_id: 0, submission_id: 0}, options);
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString()+ "/table/" + this.options.table_id.toString();
    }
});

export var SiteDataModel = window.SiteDataModel = Backbone.Model.extend({

    initialize: function (options) {
        this.options = options || (options = {});
    },

    defaults: {
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString() +
                        "/site/" + this.options.site_id.toString();
    }
});

export var SampleGroupDataModel = window.SampleGroupDataModel = Backbone.Model.extend({

    initialize: function (options) {
        this.options = options || (options = {});
    },

    defaults: {
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString() +
                        "/site/" + this.options.site_id.toString() +
                 "/sample_group/" + this.options.sample_group_id.toString();
    }

});

export var SampleDataModel = window.SampleDataModel = Backbone.Model.extend({

    initialize: function (options) {
        this.options = options || (options = {});
    },

    defaults: {
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString() +
                        "/site/" + this.options.site_id.toString() +
                 "/samplegroup/" + this.options.sample_group_id.toString() +
                      "/sample/" + this.options.sample_id.toString();
    }

});

export var DataSetDataModel = window.DataSetDataModel = Backbone.Model.extend({

    initialize: function (options) {
        this.options = options || (options = {});
    },

    defaults: {
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString() +
                        "/site/" + this.options.site_id.toString() +
                 "/samplegroup/" + this.options.sample_group_id.toString() +
                     "/dataset/" + this.options.dataset_id.toString();
    }

});

export var SubmissionMetaDataModel = window.SubmissionMetaDataModel = Backbone.Model.extend({

    initialize: function (options) {
        this.options = options || (options = {});
    },

    defaults: {
    },

    url: function () {
        return "api/submission/" + this.options.submission_id.toString() + "/metadata";
    },

    getSiteName: function(id)
    {
        try {
            var sites = this.get("sites");
            for (var i = 0; i < sites.length;i++) {
                if (sites[i].site_id === id) {
                    return sites[i].site_name;
                }
            }
        } catch (ex) { // eslint-disable-line no-unused-vars
        }
        return "Site " + id.toString();
    }

});

export var SubmissionRejectModel = window.SubmissionRejectModel = Backbone.Model.extend({

    idAttribute: "submission_reject_id",

    initialize: function (options) {

        this.options = options || (options = {});
        this.validators = {};

        this.validators.reject_description = function (value) {
            return value.length > 0 ? {isValid: true} : {isValid: false, message: "You must enter a description"};
        };

    },

    validateItem: function (key) {
        return (this.validators[key]) ? this.validators[key](this.get(key)) : {isValid: true};
    },

    validateAll: function () {

        var messages = {};

        for (var key in this.validators) {
            if(this.validators.hasOwnProperty(key)) {
                var check = this.validators[key](this.get(key));
                if (check.isValid === false) {
                    messages[key] = check.message;
                }
            }
        }

        return _.size(messages) > 0 ? {isValid: false, messages: messages} : {isValid: true};
    },

    save_revert_point: function()
    {
        this._saved_attributes  = _.clone(this.attributes);
    },

    revert_to_save_point: function()
    {
        if (this._saved_attributes) {
            this.set(this._saved_attributes, { silent : true });
        }
    },

    get_reject_entity_ids: function()
    {
        return _.pluck(this.get("reject_entities"), "local_db_id");
    },

    add_reject_entity_id: function(local_db_id)
    {
        this.get("reject_entities").push({
            "reject_entity_id":  0,
            "submission_reject_id": this.get("submission_reject_id"),
            "local_db_id": local_db_id
        });
    },

    contains_entity_id: function(entity_type_id, local_db_id)
    {
        // TODO Remove abs - Sort out sign of ID's - seems as if they sometimes are stored as negative values...?
        return this.get("entity_type_id") == entity_type_id &&
            _.some(this.get("reject_entities"), function(x) { return Math.abs(x.local_db_id) == Math.abs(local_db_id)});
    }

});

export var SubmissionRejectCollection = window.SubmissionRejectCollection = Backbone.Collection.extend({

    model: SubmissionRejectModel,

    initialize: function(models, options) {
        options = $.extend({}, { submission_id: 0 }, options);
        this.submission_id = options.submission_id;
    },

    url: function () {
        return "api/submissions/" + this.submission_id.toString() + "/rejects";
    },

    findByLocalId: function(id)
    {
        var matches = this.find(function(item) {
            return item.get("reject_entities") && $.inArray(id, item.get("reject_entities"));
        });
        if (matches.length > 0) {
            return matches[0];
        }
        return null;
    },

    addReject: function(options)
    {
        var model = new SubmissionRejectModel(_.extend({}, { submission_id: this.submission_id }, options));
        this.add(model);
        return model;
    },
    /* not used */
    getUniqueEntityIds: function(entity_type_id)
    {
        return  _.uniq(
            _.flatten(
                _.pluck(
                    _.pluck(this.where({ entity_type_id: entity_type_id }),
                        "reject_entities"),
                    "local_db_id"
                )
            )
        );
    },

    contains_entity_id: function(entity_type_id, local_db_id)
    {
        return this.some(function (x) { return x.contains_entity_id(entity_type_id, local_db_id); });
    },

    contains_site_id: function(id)
    {
        return this.findWhere({ site_id: id }) != null;
    }
});

export var SubmissionRejectEntityModel = window.SubmissionRejectEntityModel = Backbone.Model.extend({
    defaults: {
        "reject_entity_id":  0,
        "submission_reject_id": 0,
        "local_db_id": 0
    }
});

export var RejectEntityEntityCollection = window.RejectEntityEntityCollection = Backbone.Collection.extend({

    model: SubmissionRejectEntityModel

});

export var RejectEntityTypeModel = window.RejectEntityTypeModel = Backbone.Model.extend({

});

export var RejectEntityTypesCollection = window.RejectEntityTypesCollection = Backbone.Collection.extend({

    model: RejectEntityTypeModel,

    url: "api/reject_entity_types",

    lookup_name: function(entity_type_id)
    {
        try {
            return this.findWhere({ entity_type_id: entity_type_id}).get("entity_type");
        } catch (ex) {
            return "Entity type " + entity_type_id.toString();
        }
    }

});

export var UserModel = window.UserModel = Backbone.Model.extend({

    idAttribute: "user_id",

    url: "api/users",

    initialize: function () {
        // TODO: Add validation
    },

    save_revert_point: function()
    {
        this._saved_attributes  = _.clone(this.attributes);
    },
    // TODO: Use previousAttributes instead!

    revert_to_save_point: function()
    {
        if (this._saved_attributes) {
            this.set(this._saved_attributes, { silent : true });
        }
    }

});

export var UserCollection = window.UserCollection = Backbone.Collection.extend({

    model: UserModel,
    url: "api/users",

    initialize: function(models, options) {
        options = $.extend({}, { submission_id: 0 }, options);
        this.submission_id = options.submission_id;
    },

    create_new_user: function()
    {
        return new UserModel(_.extend({}, this.default_attributes()));
    },

    add_user: function(model)
    {
        this.add(model);
        return model;
    },

    default_attributes: function() {
        return {
            user_id: 0,
            user_name: "",
            password: "",
            email: "",
            signal_receiver: false,
            role_id: 0,
            is_data_provider: false,
            data_provider_grade_id: 1,
            create_date: Date.now(),
            full_name: ""
        };
    }

});

export var RoleTypeModel = window.RoleTypeModel = Backbone.Model.extend({

});

export var RoleTypeCollection = window.RoleTypeCollection = Backbone.Collection.extend({
    model: RoleTypeModel,

    get_role_name: function(role_id)
    {
        try {
            return this.findWhere({ role_id: role_id}).get("role_name");
        } catch (ex) {
            return "Role " + role_id.toString();
        }
    }
});

export var DataProviderGradeTypeModel = window.DataProviderGradeTypeModel = Backbone.Model.extend({

});

export var DataProviderGradeTypeCollection = window.DataProviderGradeTypeCollection = Backbone.Collection.extend({
    model: DataProviderGradeTypeModel
});

