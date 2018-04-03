// The in-memory Store. Encapsulates logic to access wine data.
window.global_data_store = {

    store: {},

    populate: function () {
        this.populateSubmission();
        this.populateSites();
        this.populateReports();
    },

    populateSites: function () {

        this.store["api/sites"] = { };
        this.store["api/sites"][1] = { site_id:1, altitude:20.0000000000, latitude_dd:56.8663888889, longitude_dd:12.6683333337, national_site_identifier:'Slöinge 114', site_description:null, site_name:'Slöinge Raä 114', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][2] = { site_id:2, altitude:null, latitude_dd:56.5849999997, longitude_dd:12.5974999997, national_site_identifier:'Skrea 194:1', site_description:null, site_name:'Skrea Raä 194', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][3] = { site_id:3, altitude:20.0000000000, latitude_dd:56.8805555559, longitude_dd:12.6169444448, national_site_identifier:'Skrea 177:1', site_description:null, site_name:'Skrea Raä 177', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][4] = { site_id:4, altitude:10.0000000000, latitude_dd:57.3805833337, longitude_dd:12.0180333334, national_site_identifier:'Onsala 327:1', site_description:null, site_name:'Onsala Raä 327', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][5] = { site_id:5, altitude:30.0000000000, latitude_dd:57.4763888892, longitude_dd:11.9980555552, national_site_identifier:'Vallda 293:1', site_description:null, site_name:'Vallda Raä 293', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][6] = { site_id:6, altitude:null, latitude_dd:56.9213888892, longitude_dd:12.4922222219, national_site_identifier:'Stafsinge 116:1', site_description:null, site_name:'Stafsinge Raä 116', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][7] = { site_id:7, altitude:55.0000000000, latitude_dd:56.9327777781, longitude_dd:12.6849999997, national_site_identifier:'Årstad 3:1', site_description:null, site_name:'Årstad Raä 3', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][8] = { site_id:8, altitude:30.0000000000, latitude_dd:56.5583333333, longitude_dd:13.0566666667, national_site_identifier:'Tjärby 59:1', site_description:null, site_name:'Tjärby Raä 59', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][9] = { site_id:9, altitude:null, latitude_dd:56.9218694448, longitude_dd:12.4882222219, national_site_identifier:'Stafsinge 120:1', site_description:null, site_name:'Stafsinge Raä 120', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][10] = { site_id:10, altitude:null, latitude_dd:56.8250000003, longitude_dd:12.7105555556, national_site_identifier:'Getinge 93:1', site_description:null, site_name:'Getinge Raä 93', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][11] = { site_id:11, altitude:10.0000000000, latitude_dd:57.3363888886, longitude_dd:12.1658333333, national_site_identifier:'Landa 35:3', site_description:null, site_name:'Landa Raä 35', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][12] = { site_id:12, altitude:null, latitude_dd:57.4072222222, longitude_dd:12.0111111111, national_site_identifier:'Onsala 369:1', site_description:null, site_name:'Onsala Raä 369', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][13] = { site_id:13, altitude:null, latitude_dd:57.4261111114, longitude_dd:12.2163888889, national_site_identifier:'Fjärås 504:1', site_description:null, site_name:'Fjärås Raä 504', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][14] = { site_id:14, altitude:20.0000000000, latitude_dd:56.6758333337, longitude_dd:12.8111111111, national_site_identifier:'Söndrum 100:1', site_description:null, site_name:'Söndrum Raä 100', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][15] = { site_id:15, altitude:null, latitude_dd:56.6747222226, longitude_dd:12.8575000000, national_site_identifier:'Halmstad 44_1', site_description:null, site_name:'Halmstad Raä 44', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][16] = { site_id:16, altitude:null, latitude_dd:56.8358333330, longitude_dd:12.7061111111, national_site_identifier:'Slöinge 115:1', site_description:null, site_name:'Slöinge Raä 115', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][17] = { site_id:17, altitude:null, latitude_dd:56.5197222226, longitude_dd:13.0077777778, national_site_identifier:'Laholm 205:1', site_description:null, site_name:'Laholm Raä 205', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][18] = { site_id:18, altitude:null, latitude_dd:57.2836111108, longitude_dd:12.1686111114, national_site_identifier:'Värö 323:1', site_description:null, site_name:'Värö Raä 323', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][19] = { site_id:19, altitude:null, latitude_dd:56.9025000000, longitude_dd:12.5800000003, national_site_identifier:'Skrea 77:1', site_description:null, site_name:'Skrea Raä 77', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][20] = { site_id:20, altitude:20.0000000000, latitude_dd:56.9240694448, longitude_dd:12.4817361114, national_site_identifier:'Stafsinge 122:1', site_description:null, site_name:'Stafsinge Raä 122', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][21] = { site_id:21, altitude:null, latitude_dd:57.4294444448, longitude_dd:12.1652777778, national_site_identifier:'Fjärås 499:1', site_description:null, site_name:'Fjärås Raä 499', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][22] = { site_id:22, altitude:null, latitude_dd:56.8759861114, longitude_dd:12.6260916670, national_site_identifier:'Skrea 191:1', site_description:null, site_name:'Skrea Raä 191', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][23] = { site_id:23, altitude:10.0000000000, latitude_dd:56.4213888892, longitude_dd:13.0200000000, national_site_identifier:'Hasslöv 86:2', site_description:null, site_name:'Hasslöv Raä 86', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][24] = { site_id:24, altitude:null, latitude_dd:56.9208333337, longitude_dd:12.4938888886, national_site_identifier:null, site_description:null, site_name:'Hallagård, Stomma kulle', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][25] = { site_id:25, altitude:null, latitude_dd:56.9208333337, longitude_dd:12.5150000000, national_site_identifier:null, site_description:null, site_name:'Tröinge 4:9', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][26] = { site_id:26, altitude:20.0000000000, latitude_dd:56.6391666663, longitude_dd:12.9308333337, national_site_identifier:'Snöstorp 106', site_description:null, site_name:'Snöstorp Raä 106', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][27] = { site_id:27, altitude:null, latitude_dd:56.7941666663, longitude_dd:12.8505555556, national_site_identifier:'Kvibille 131:1', site_description:null, site_name:'Kvibille Raä 131', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][28] = { site_id:28, altitude:null, latitude_dd:56.8330555559, longitude_dd:12.6577777778, national_site_identifier:'Eftra 110:1', site_description:null, site_name:'Eftra Raä 110', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][29] = { site_id:29, altitude:20.0000000000, latitude_dd:56.9038888889, longitude_dd:12.5733333337, national_site_identifier:'Skrea 106:1', site_description:null, site_name:'Skrea Raä 106', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][30] = { site_id:30, altitude:null, latitude_dd:57.0547222222, longitude_dd:12.2905555552, national_site_identifier:'Tvååker 193:1', site_description:null, site_name:'Tvååker Raä 193', site_preservation_status_id:null, date_updated:'2013-05-13 11:29:56.070308+02', ch_submission_id:0 };
        this.store["api/sites"][53] = { site_id:53, altitude:30.0000000000, latitude_dd:57.7143527778, longitude_dd:11.7620833333, national_site_identifier:'Raä 108:1', site_description:null, site_name:'Torslanda 108:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][54] = { site_id:54, altitude:null, latitude_dd:59.0056055556, longitude_dd:11.2326555559, national_site_identifier:'443:1', site_description:null, site_name:'Hogdal 443', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][55] = { site_id:55, altitude:20.0000000000, latitude_dd:57.7142361111, longitude_dd:11.7782888892, national_site_identifier:'Raä 110:1', site_description:null, site_name:'Torslanda 110:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][56] = { site_id:56, altitude:null, latitude_dd:56.9213500003, longitude_dd:12.4920999997, national_site_identifier:'Raä 118', site_description:null, site_name:'Stafsinge 118', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][57] = { site_id:57, altitude:null, latitude_dd:null, longitude_dd:null, national_site_identifier:null, site_description:null, site_name:'Skrea Raä 162', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][58] = { site_id:58, altitude:null, latitude_dd:58.3318277781, longitude_dd:12.0645000000, national_site_identifier:'Raä 133:1', site_description:null, site_name:'Uddevalla Raä 133:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][59] = { site_id:59, altitude:null, latitude_dd:null, longitude_dd:null, national_site_identifier:null, site_description:null, site_name:'Ytterby 4', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][60] = { site_id:60, altitude:null, latitude_dd:null, longitude_dd:null, national_site_identifier:'Raä 327:1', site_description:null, site_name:'Hogstorp 327:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][61] = { site_id:61, altitude:null, latitude_dd:58.4077861111, longitude_dd:11.4299000003, national_site_identifier:'Raä 195:1', site_description:null, site_name:'Dammen Raä 195:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][62] = { site_id:62, altitude:null, latitude_dd:58.9202277781, longitude_dd:11.2086750000, national_site_identifier:'Raä 1486', site_description:null, site_name:'Stare 1:13', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][63] = { site_id:63, altitude:null, latitude_dd:58.4911111108, longitude_dd:11.6144444444, national_site_identifier:null, site_description:null, site_name:'Håby 6:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][64] = { site_id:64, altitude:40.0000000000, latitude_dd:58.3026027778, longitude_dd:11.8598250000, national_site_identifier:'Raä 140', site_description:null, site_name:'Forshälla Raä 140', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][65] = { site_id:65, altitude:null, latitude_dd:57.9128194444, longitude_dd:11.8302222226, national_site_identifier:'Raä 130:1', site_description:null, site_name:'Hålta Raä 130', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][66] = { site_id:66, altitude:30.0000000000, latitude_dd:58.0485222222, longitude_dd:11.8583972222, national_site_identifier:'Raä 285', site_description:null, site_name:'Norum Raä 285', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][67] = { site_id:67, altitude:null, latitude_dd:58.9640361111, longitude_dd:11.2347166663, national_site_identifier:'Raä 1593:1', site_description:null, site_name:'Skee 1593:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][68] = { site_id:68, altitude:20.0000000000, latitude_dd:57.7151388889, longitude_dd:11.7701222226, national_site_identifier:'Raä 99:1', site_description:null, site_name:'Torslanda 99:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][69] = { site_id:69, altitude:65.0000000000, latitude_dd:58.4054722222, longitude_dd:11.7384916663, national_site_identifier:'Raä 426:1', site_description:null, site_name:'Kallsås 426:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][70] = { site_id:70, altitude:70.0000000000, latitude_dd:58.4019527778, longitude_dd:11.7438138886, national_site_identifier:'430:1', site_description:null, site_name:'Kallsås 430:1', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][71] = { site_id:71, altitude:30.0000000000, latitude_dd:59.0023750000, longitude_dd:11.2316055559, national_site_identifier:'Raä 444 + 445', site_description:'', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][72] = { site_id:72, altitude:null, latitude_dd:null, longitude_dd:null, national_site_identifier:null, site_description:null, site_name:'Låssby ny 2', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][73] = { site_id:73, altitude:25.0000000000, latitude_dd:57.7193583337, longitude_dd:11.7625138889, national_site_identifier:'Raä 96', site_description:null, site_name:'Torslanda Raä 96', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        this.store["api/sites"][74] = { site_id:74, altitude:20.0000000000, latitude_dd:58.0103000000, longitude_dd:11.8138583333, national_site_identifier:'Raä 184', site_description:null, site_name:'Jörlanda Raä 184', site_preservation_status_id:null, date_updated:'2013-05-16 10:39:58.584644+02', ch_submission_id:0 };
        
    },
            
    populateSubmission: function () {

        this.store["api/submissions"] = { };
        
        this.store["api/submissions"][1] = {
            id: 1,
            data_provider_name: "Kurt Ohlsson",
            proxy_type: "Cheramic",
            status: "Pending",
            data_provider_grade: "Normal",
            submission_date: '2014-01-14',
            testdata: [ { id: 1, name: "testing"} ]
        };
        this.store["api/submissions"][2] = {
            id: 2,
            data_provider_name: "Lena Svensson",
            proxy_type: "Proxy 2",
            status: "Pending",
            data_provider_grade: "Normal",
            submission_date: '2014-01-14'
        };
        this.store["api/submissions"][3] = {
            id: 3,
            data_provider_name: "Karl Karlsson",
            proxy_type: "Proxy 3",
            status: "In progress",
            data_provider_grade: "Normal",
            submission_date: '2014-01-09'
        };
        this.store["api/submissions"][4] = {
            id: 4,
            data_provider_name: "Sven Andersson",
            proxy_type: "Proxy 5",
            status: "Pending",
            data_provider_grade: "Normal",
            submission_date: '2014-01-07'
        };
        this.store["api/submissions"][5] = {
            id: 5,
            data_provider_name: "Arne Svensson Andersson",
            proxy_type: "Proxy 5",
            status: "Pending",
            data_provider_grade: "Normal",
            submission_date: '2014-01-07'
        };
        this.store["api/submissions"][6] = {
            id: 6,
            data_provider_name: "Kurt Knutsson",
            proxy_type: "Proxy 5",
            status: "Pending",
            data_provider_grade: "Normal",
            submission_date: '2014-01-07'
        };
        
    },
            
    populateReports: function () {

        this.store["api/reports/toc"] = { };

        this.store["api/reports/toc"][1] = {
            list_id: 1,
            list_name: "Locations"
        };

        this.store["api/reports/toc"][2] = {
            list_id: 2,
            list_name: "Bibliography entries"
        };

        this.store["api/reports/toc"][3] = {
            list_id: 3,
            list_name: "Data sets"
        };
        
        this.store["api/reports/toc"][4] = {
            list_id: 4,
            list_name: "List taxonomic data"
        };

        this.store["api/reports/toc"][5] = {
            list_id: 5,
            list_name: "Ecological reference data"
        };
 
        this.store["api/reports/toc"][6] = {
            list_id: 6,
            list_name: "Methods"
        };
        
        this.store["api/reports/toc"][7] = {
            list_id: 7,
            list_name: "Relative ages"
        };
    },

    find: function (model) {
        return this.store[model.url][model.id];
    },

    findAll: function (model) {
        return _.values(this.store[model.url]);
    },

    create: function (model) {
        var newId = this.nextId(model);
        model.set('id', newId);
        this.store[model.url][newId] = model;
        return model;
    },

    update: function (model) {
        this.store[model.url][model.id] = model;
        return model;
    },

    destroy: function (model) {
        delete this.store[model.url][model.id];
        return model;
    },
            
    nextId: function (model) {
        var data = this.store[model.url];
        var currentId = 0;
        for (i = 0; i < data.length; i++) {
            if (data[i].id > currentId)
                currentId = data[i];
        }
        return currentId + 1;
    }

};

global_data_store.populate();

Backbone.sync = function (method, model, options) {

    var result;

    switch (method) {
        case "read":
            result = model.id ? global_data_store.find(model) : global_data_store.findAll(model);
            break;
        case "create":
            result = global_data_store.create(model);
            break;
        case "update":
            result = global_data_store.update(model);
            break;
        case "delete":
            result = global_data_store.destroy(model);
            break;
    }

    if (result) {
        options.success(result);
    } else {
        options.error("Record not found");
    }
};