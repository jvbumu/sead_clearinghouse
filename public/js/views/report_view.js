import { ReviewTableView } from './review_table_view.js';

var ReportView = window.ReportView = Backbone.View.extend({

    initialize: function (options) {
        this.options = options || {};
        this.template = TemplateStore.get("template_ReportResultView");
        this.report_id = this.options.report_id;
        this.submission_id = this.options.submission_id;
        this.report_data = this.options.report_data;
        this.listenTo(this.report_data, 'reset', this.renderData);
    },

    render: function () {
        $(this.el).html(this.template());
        return this;
    },

    renderData: function()
    {
        var report_data = this.report_data.toJSON();
        var data = report_data[0].data;
        var columns = report_data[0].columns;

        if (!data || data.length == 0) {
            return;
        }

        var data_type = "report";
        var data_key = this.options.report_id.toString();
        var table_options = Table_Template_Store.template(data_type, data_key, columns);

        var view = new ReviewTableView($.extend(table_options.options, { rejects: this.options.rejects, data: data }));
        $('#report_result_container', this.$el).html(view.render().el);

        return this;
    }

});

export default ReportView;
