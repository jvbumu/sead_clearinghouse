// MOVED TO main.js
 _.extend(Backbone.View.extend({

    set_disabled_state: function ($button, disabled)
    {
        $button.prop("disabled", disabled);
        if (disabled)
            $button.addClass("disabled");
        else
            $button.removeClass("disabled");
    }

}));
