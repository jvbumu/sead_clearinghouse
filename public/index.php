<!DOCTYPE html>
<html lang="en">
<?php
try {
require_once __DIR__ . '/api/class_loader.php';
$loader = new ClassLoaderService();
$loader->setup();
} catch(Exception $ex){
 echo $ex->getMessage();
}

?>

<head>
    <meta charset="utf-8">
    <title>SEAD Clearing House</title>
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        body {
            padding-top: 60px; /* 60px to make the container go all the way to the bottom of the topbar */
        }
    </style>


    <link href="css/bootstrap.css" rel="stylesheet" media="screen">
    <!--<link href="css/bootstrap.min.css" rel="stylesheet" media="screen">-->

    <link href="css/toggle-switch.css" rel="stylesheet" media="screen">

    <!-- <link href="//cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css" rel="stylesheet" media="screen"> -->
    <link href="lib/datatables/css/jquery.dataTables.css" rel="stylesheet" media="screen">
    <link href="lib/datatables/css/dataTables.custom.css" rel="stylesheet" media="screen">
    <link href="lib/datatables/css/TableTools.css" rel="stylesheet" media="screen">
    <link href="lib/datatables/css/dataTables.bootstrap.css" rel="stylesheet" media="screen">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="lib/html5shiv.js"></script>
      <script src="lib/respond.min.js"></script>
    <![endif]-->

    <link href="css/styles.css" rel="stylesheet">

    <script language="javascript">
    <?php
        $service = new \Application\BootstrapService();
     ?>
    var BootstrapData = {
        Users: <?= $service->getUsersModel() ?>,
        Lookup: {
            RoleTypes: <?= $service->getUserRoleTypes() ?>,
            RejectTypes: <?= $service->getRejectTypes() ?>,
            DataProviderGradeTypes: <?= $service->getDataProviderGradeTypes() ?>,
            LatestSites: <?= $service->getLatestUpdatedSites() ?>,
            References: <?= $service->getInfoReferences() ?>,
            Dummy: "dummy"
        },
        Reports: <?= $service->getReports() ?>,
        Dummy: "dummy"
    }
    </script>
</head>

<body data-spy="scroll" data-target=".subnav" data-offset="50">

<div class="header"></div>
<div id="wrap" class="fill-height">

    <div class="sead-fluid-container fill-height">
        <div id="content" class="fill-height">THIS IS MAIN WORKSPACE AREA</div>
    </div>

</div>
<div class="footer"></div>

<div id="modal_view_container"></div>
<div id="logout_modal_view_container"></div>
<div id="error_modal_view_container"></div>

<div id="logger" class="warning pull-left"></div>
<div id="progress-pane"></div>

<div id="buzy_inidcator"></div>

<script src="//ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/backbone.js/1.3.3/backbone-min.js"></script>

<script src="lib/bootstrap.min.js"></script>

<!-- <script src="//cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"></script> -->
<script src="lib/datatables/js/jquery.dataTables.min.js"></script>
<script src="lib/datatables/js/TableTools.min.js"></script>
<script src="lib/datatables/js/dataTables.bootstrap.js"></script>
<script src="lib/spin.min.js"></script>

<!-- NOTE: memorystore.js will set up an in-memory datastore to allow you to experience the app without setting up
back-end infrastructure. All the changes you make to the data will be lost the next time you access the app or hit Refresh.
To use the app with a persistent RESTful back-end (provided in the GitHub repo), simply comment out the line below. -->
<!-- script src="js/data/memorystore.js"></script -->

<script src="js/utility/utility.js"></script>
<script src="js/model/models.js"></script>

<!--<script src="js/views/paginator.js"></script>-->

<script src="js/views/header_view.js"></script>
<script src="js/views/footer_view.js"></script>
<script src="js/views/dialog_view.js"></script>

<script src="js/views/utility_views.js"></script>
<script src="js/views/review_base_view.js"></script>
<script src="js/views/review_table_view.js"></script>
<script src="js/views/home_view.js"></script>
<script src="js/views/navigation_view.js"></script>
<script src="js/views/site_view.js"></script>
<script src="js/views/samplegroup_view.js"></script>
<script src="js/views/sample_view.js"></script>
<script src="js/views/dataset_view.js"></script>
<script src="js/views/submission_view.js"></script>
<script src="js/views/report_view.js"></script>
<script src="js/views/reject_cause_view.js"></script>
<script src="js/views/claim_view.js"></script>
<script src="js/views/transfer_view.js"></script>
<script src="js/views/users_view.js"></script>
<script src="js/views/about_view.js"></script>

<script src="js/model/security.js"></script>
<script src="js/backbone-extend.js"></script>
<script src="js/main.js"></script>

</body>
</html>
