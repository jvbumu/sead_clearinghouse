var SampleGroupView = window.SampleGroupView = window.ReviewBaseView.extend({

    get_store: function() {
        return Sample_Group_Column_Store;
    },

    render_root: function(model)
    {
        $("#sample_group_id", this.$el).text(model.sample_group.local_db_id);
        this.set_review_value($("#sample_group_name", this.$el), model.sample_group.sample_group_name, model.sample_group.public_sample_group_name);
        this.set_review_value($("#sampling_context", this.$el),  model.sample_group.sampling_context, model.sample_group.public_sampling_context);
        this.set_review_value($("#sampling_method", this.$el),  model.sample_group.sampling_method, model.sample_group.public_sampling_method);
        return this;
    }

});

var Sample_Group_Column_Store = window.Sample_Group_Column_Store = {

    data_type: "sample_group",

    data_keys: ["lithology", "references", "notes", "dimensions", "descriptions", "positions" /*, "images" */],

    columns: utils.toArray({
        lithology: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Depth Top", column_field: "depth_top", public_column_field: "public_depth_top" },
            { column_name: "Depth Bottom", column_field: "depth_bottom", public_column_field: "public_location_type" },
            { column_name: "Description", column_field: "description", public_column_field: "public_description" },
            { column_name: "Boundry", column_field: "lower_boundary", public_column_field: "public_lower_boundary" } //,
            //{ column_name: "Updated", column_field: "date_updated" /*, fn_render: function(d) { return d; } */ } */
        ],
        references: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Reference", column_field: "reference", public_column_field: "public_reference" }
        ],
        notes: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Method", column_field: "note", public_column_field: "public_note" },
            { column_name: "Updated", column_field: "date_updated" }
        ],
        dimensions: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Value", column_field: "dimension_value", public_column_field: "public_dimension_value" },
            { column_name: "Name", column_field: "dimension_name", public_column_field: "public_dimension_name" },
            { column_name: "Updated", column_field: "date_updated" }
        ],
        descriptions: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Group desc.", column_field: "group_description", public_column_field: "public_group_description" },
            { column_name: "Type name", column_field: "type_name", public_column_field: "public_type_name" },
            { column_name: "Type desc.", column_field: "type_description", public_column_field: "public_type_description" },
            { column_name: "Updated", column_field: "date_updated" }
        ],
        positions: [
            { column_name: "Id", column_field: "local_db_id" },
            { column_name: "Position", column_field: "sample_group_position", public_column_field: "public_sample_group_position" },
            { column_name: "Accuracy", column_field: "position_accuracy", public_column_field: "public_position_accuracy" },
            { column_name: "Method", column_field: "method_name", public_column_field: "public_method_name" },
            { column_name: "Dimension", column_field: "dimension_name", public_column_field: "public_dimension_name" },
            { column_name: "Updated", column_field: "date_updated" }
        ]
    })
};

export { SampleGroupView, Sample_Group_Column_Store };
