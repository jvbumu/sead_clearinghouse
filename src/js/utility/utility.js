
var TemplateStore = window.TemplateStore = {

    template_cache: { },

    process_template: function(file, data) {

        var cache = this.template_cache;

        if (file.type === "view") {

            var compiled_template = _.template(data);
            window[file.name].prototype.template = compiled_template;
            cache[file.name] = compiled_template;

        } else if (file.type === "templates") {

            $(data).find("div.template_item").each(
                function (index) { // eslint-disable-line no-unused-vars
                    cache[$(this).attr("id")] = _.template($(this).html().replace(/&lt;%/gi, '<%').replace(/%&gt;/gi, '%>'));
                });

            $(data).find("script").each(
                function (index) { // eslint-disable-line no-unused-vars
                    cache[$(this).attr("id")] = _.template($(this).html());
                });

        }
    },

    // Deprecated (webpack is used instead): Asynchronously load view templates located in separate .html files
    preload: function(files, callback) {

        var deferreds = [];
        // var cache = this.template_cache;
        var self = this;

        $.each(files, function(index, file) {

            deferreds.push($.get('templates/' + file.name + '.html', function(data) { self.process_template(file, data); } /*function(data) {

                if (file.type === "view") {

                    var compiled_template = _.template(data);
                    window[file.name].prototype.template = compiled_template;
                    cache[file.name] = compiled_template;

                } else if (file.type === "templates") {

                    $(data).find("div.template_item").each(
                        function (index) {
                            cache[$(this).attr("id")] = _.template($(this).html().replace(/&lt;%/gi, '<%').replace(/%&gt;/gi, '%>'));
                    });

                    $(data).find("script").each(
                        function (index) {
                            cache[$(this).attr("id")] = _.template($(this).html());
                    });

                }
            }*/));

        });

        $.when.apply(null, deferreds).done(callback);
    },

    load:  function(template_name) {
        var div = $("#" + template_name);
        return _.template(div !== undefined ? div.html() : "");
    },

    get: function(template_name) {
        var cache = this.template_cache;
        if (cache[template_name] === undefined) {
            cache[template_name] = this.load(template_name);
        }
        return cache[template_name];
    }

};

var utils = window.utils = {

    showAlert: function(title, text, klass) {
        $('.alert').removeClass("alert-error alert-warning alert-success alert-info");
        $('.alert').addClass(klass);
        $('.alert').html('<strong>' + title + '</strong> ' + text);
        $('.alert').show();
    },

    hideAlert: function() {
        $('.alert').hide();
    },

    log_status: function(msg)
    {
        $("#logger").html(msg);
    },

    set_disabled_state: function ($button, disabled)
    {
        $button.prop("disabled", disabled);
        if (disabled)
            $button.addClass("disabled");
        else
            $button.removeClass("disabled");
    },

    getEntityTypeOf: function(x)
    {
        if (Array.isArray(x) && x.length > 0 && x[0].entity_type_id)
            return x[0].entity_type_id;
        if (x && x.entity_type_id)
            return x.entity_type_id;
        return 0;
    },

    // ex: toggle_collapsable_view_port($viewport, $sidebar, "col-sm-4", "col-sm-8", "col-sm-12")
    toggle_collapsable_view_port:  function($sidebar, $viewport, sidebar_class, viewport_class, viewport_class_full) {

        if ($viewport.hasClass(viewport_class)) {
            $sidebar.removeClass(sidebar_class);
            $viewport.removeClass(viewport_class).addClass(viewport_class_full);
        } else {
            $sidebar.addClass(sidebar_class);
            $viewport.removeClass(viewport_class_full).addClass(viewport_class);
        }
        $sidebar.toggle();
    },

    toArray: function(_object) {
        var array = [];
        for (var name in _object){
            array[name] = _object[name];
        }
        return array;
    },

    toObject: function(_Array) {
        var _Object = {};
        for (var key in _Array){
            _Object[key] = _Array[key];
        }
        return _Object;
    },

    setEnterHandler: function ($el, eventname, callback) {
        $el.on(eventname, function(e) {
            if (e.keyCode == 13) {
                e.preventDefault();
                callback();
            }
        });
    },

};

if (typeof String.prototype.startsWith != 'function') {
    String.prototype.startsWith = function (str){
        return this.lastIndexOf(str, 0) == 0;
    };
}

if (typeof String.prototype.pascalCase != 'function') {
    String.prototype.pascalCase = function () {
    //return this.replace(/([A-Za-z0-9])([A-Za-z0-9]*)/g, function(g0,g1,g2){return g1.toUpperCase() + g2.toLowerCase();}  );
    //return this.replace(/[A-Za-z0-9]+/g, function(w){return w[0].toUpperCase() + w.slice(1).toLowerCase();});
        try {
            return this.replace (/(?:^|[-_])(\w)/g, function (_, c) {  return c ? c.toUpperCase () : '';  });
        } catch (ex) {
            return this;
        }
    };
}

if (typeof String.prototype.pascalCaseToWords != 'function') {
    String.prototype.pascalCaseToWords = function (){
        return this.replace(/([A-Z])/g, ' $1').replace(/^./, function(str){ return str.toUpperCase(); });
    };
}

if (typeof String.prototype.threeDotify != 'function') {
    String.prototype.threeDotify = function (max_length){
        if (max_length < 3) {
            return "...";
        }
        if (this.length > max_length) {
            return this.substring(0,max_length-3) + "...";
        }
        return this;
    };
}

export { TemplateStore, utils };