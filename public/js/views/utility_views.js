
window.CollectionDropdownView = Backbone.View.extend({
 
    initialize: function () {

        var option = $.extend({}, {
            collection: null,
            element_id: "",
            select_class: "",
            select_style: "",
            item_value_field: "",
            item_text_field: "",
            auto_update: false,
            extra: null
        }, this.options);

        this.collection = option.collection;
        this.element_id = option.element_id;
        this.select_class = option.select_class;
        this.select_style = option.select_style;
        this.item_value_field = option.item_value_field;
        this.item_text_field = option.item_text_field;
        this.auto_update = option.auto_update;
        this.extra = option.extra;
        this.$select = null;
        this.render();

    },
    
    render: function() {
        
        var self = this;
        
        this.el = $("<select/>", {
            id: this.element_id,
            class: this.select_class,
            name: this.element_id,
            style: this.select_style
        });
        
        this.$select = $(this.el);
        
        this.$select.change(
            function () {
                self.trigger("select:change", $(this).val());
            }
        );

        if (this.collection != null) {
            this.listenTo(this.collection, 'reset', this.renderOptions);
            if (this.auto_update) {
                this.listenTo(this.collection, 'add remove sync change', this.renderOptions);
            }
            this.renderOptions();
        }        

        return this;  
    },
    
    renderOptions: function(e)
    {
        var target = this.$select;
        
        var value = null;
        
        if (!target) {
            return;
        }
        
        value = target.val();
        
        target.empty();
        
        if (this.extra && this.extra.value && this.extra.text) {
            target.append($("<option>", { value: this.extra.value }).text(this.extra.text));
        }
        
        var item_value_field = this.item_value_field;
        var item_text_field = this.item_text_field;
        
        this.collection.each(
            function(item) {
                //console.log(item);
                target.append(
                    $("<option>", { value: item.get(item_value_field) }).text(
                        typeof(item_text_field) === 'function' ? item_text_field(item) : item.get(item_text_field)
                    )
                );
            }
        );


        if (value) {
            target.val(value);
        }

        return this;
    }

});
