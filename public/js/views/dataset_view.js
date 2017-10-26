window.DataSetView = window.ReviewBaseView.extend({
 
    get_store: function() {
        return DataSet_Column_Store;
    },
    
    render_root: function(model)
    {
        $("#dataset_id", this.$el).text(model.dataset.local_db_id);
        utils.set_review_value($("#dataset_name", this.$el), model.dataset.dataset_name, model.dataset.public_dataset_name);
        utils.set_review_value($("#data_type_name", this.$el), model.dataset.data_type_name, model.dataset.public_data_type_name);
        utils.set_review_value($("#master_name", this.$el), model.dataset.master_name, model.dataset.public_master_name);
        utils.set_review_value($("#previous_dataset_name", this.$el), model.dataset.previous_dataset_name, model.dataset.public_previous_dataset_name);
        utils.set_review_value($("#method_name", this.$el), model.dataset.method_name, model.dataset.public_method_name);
        utils.set_review_value($("#project_stage_name", this.$el), model.dataset.project_stage_name, model.dataset.public_project_stage_name);
        return this;
    }
});

window.DataSet_Column_Store = {
                
    data_type: "dataset",

    data_keys: [ "contacts", "submissions", "measured_values", "abundance_values" ],

    columns: utils.toArray({

         contacts: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "First name", column_field: "first_name", public_column_field: "public_first_name" },
            { column_name: "Last name", column_field: "last_name", public_column_field: "public_last_name" },
            { column_name: "Contact type", column_field: "contact_type_name", public_column_field: "public_contact_type_name" },
            { column_name: "Updated", column_field: "date_updated" }
        ],
        
        submissions: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "First name", column_field: "first_name", public_column_field: "public_first_name" },
            { column_name: "Last name", column_field: "last_name", public_column_field: "public_last_name" },
            { column_name: "Submission type", column_field: "submission_type", public_column_field: "public_submission_type" },
            { column_name: "Notes", column_field: "notes", public_column_field: "public_notes" },
            { column_name: "Updated", column_field: "date_updated" }
        ],
        
        measured_values: null,
        
        abundance_values: null
        

    })
};


