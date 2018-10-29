var DataSetView = window.DataSetView = window.ReviewBaseView.extend({

    get_store: function() {
        return DataSet_Column_Store;
    },

    render_root: function(model)
    {
        this.render_root_default(model.dataset, "dataset_id")
        // $("#dataset_id", this.$el).text(model.dataset.local_db_id);
        // this.set_review_value($("#dataset_name", this.$el), model.dataset.dataset_name, model.dataset.public_dataset_name);
        // this.set_review_value($("#data_type_name", this.$el), model.dataset.data_type_name, model.dataset.public_data_type_name);
        // this.set_review_value($("#master_name", this.$el), model.dataset.master_name, model.dataset.public_master_name);
        // this.set_review_value($("#previous_dataset_name", this.$el), model.dataset.previous_dataset_name, model.dataset.public_previous_dataset_name);
        // this.set_review_value($("#method_name", this.$el), model.dataset.method_name, model.dataset.public_method_name);
        // this.set_review_value($("#project_stage_name", this.$el), model.dataset.project_stage_name, model.dataset.public_project_stage_name);
        return this;
    }
});

var DataSet_Column_Store = window.DataSet_Column_Store = {

    data_type: "dataset",

    data_keys: [ "contacts", "submissions", "measured_values", "abundance_values", "ceramic_values" ],

    columns: utils.toArray({

        contacts: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Name", column_field: "full_name", public_column_field: "public_full_name" },
            { column_name: "Contact type", column_field: "contact_type_name", public_column_field: "public_contact_type_name" },
            { column_name: "Updated", column_field: "date_updated" }
        ],

        submissions: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Name", column_field: "full_name", public_column_field: "public_full_name" },
            { column_name: "Submission type", column_field: "submission_type", public_column_field: "public_submission_type" },
            { column_name: "Date submitted", column_field: "date_submitted", public_column_field: "public_date_submitted" },
            { column_name: "Notes", column_field: "notes", public_column_field: "public_notes" },
            { column_name: "Updated", column_field: "date_updated" }
        ],

        measured_values: [
            { column_name: "Id", column_field: "local_db_id" }
            // TODO: Add rest of columns
        ],
        abundance_values: [
            { column_name: "Id", column_field: "local_db_id" }
            // TODO: Add rest of columns
        ],
        ceramic_values: null /*[
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Sample name", column_field: "sample_name", public_column_field: "public_sample_name" },
            { column_name: "Method name", column_field: "method_name", public_column_field: "public_method_name" },
            { column_name: "Lookup name", column_field: "lookup_name", public_column_field: "public_lookup_name" },
            { column_name: "Value", column_field: "measurement_value", public_column_field: "public_measurement_value" }
        ]*/
    })
};

export { DataSetView, DataSet_Column_Store };
