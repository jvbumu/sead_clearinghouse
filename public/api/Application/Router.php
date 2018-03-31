<?php

namespace Application {

    class Router {

        public $application = null;
        public $router = null;
        public $config = null;

        function __construct($application) {
            \Slim\Slim::registerAutoloader();
            $this->application = $application;
            $this->config = $this->getConfig();
        }

        function getConfig()
        {
            return array(
//                'log.writer' => new \Slim\Extras\Log\DateTimeFileWriter(array(
//                    'path' => './logs',
//                    'name_format' => 'Y-m-d',
//                    'message_format' => '%label% - %date% - %message%'
//                )),
                'debug' => true
            );
        }

        function request()
        {
            try {
                return $this->router->request();
            } catch (Exception $x) {
                return null;
            }
        }

        public function run()
        {
            $this->router = $this->setup();
            $this->router->run();
            return $this;
        }


        function setup()
        {

            $router = new \Slim\Slim($this->config);

            $router->contentType('application/json');

            $router->get('/helloworld', function() { $this->application->getHelloWorld(); });
            $router->get('/bootstrap', function() { $this->application->getBootstrapData(); });

            $router->get('/login', function() { $this->application->login(); });

            $router->get('/logout', function() { $this->application->logout(); });

            $router->get('/users', function() { $this->application->getUsers(); });
            $router->get('/users/:id', function($id) { $this->application->getUser($id); });
            $router->post('/users', function() { $this->application->saveUser(); });
            $router->put('/users', function() { $this->application->saveUser(); });
            $router->delete('/users/:id', function($id) { $this->application->deleteUserById($id); });

            $router->get('/sites', function() { $this->application->getSites(); });

            $router->get('/submissions_report', function() { $this->application->getSubmissionsReport(); });
            $router->get('/submissions', function() { $this->application->getSubmissions(); });
            $router->get('/submissions/:id/process', function($id) { $this->application->processSubmission($id); });
            $router->get('/submissions/process_queue', function() { $this->application->processSubmissionQueue(); });
            $router->get('/submissions/:id', function($id) { $this->application->getSubmission($id); });
            $router->get('/submissions/:id/sites', function($id) { $this->application->getSubmissionSites($id); });

            $router->get('/reject_entity_types', function() { $this->application->getRejectTypes(); });

            $router->get('/submissions/:id/rejects', function($id) { $this->application->getSubmissionRejects($id); });
            $router->post('/submissions/:id/rejects', function($id) { $this->application->saveSubmissionReject($id); });
            $router->put('/submissions/:id/rejects', function($id) { $this->application->saveSubmissionReject($id); });
            $router->put('/submissions/:sid/rejects/:rid', function($sid, $rid) { $this->application->saveSubmissionReject($sid, $rid); });
            $router->delete('/submissions/:sid/rejects/:rid', function($sid, $rid) { $this->application->deleteSubmissionReject($sid, $rid); });

            $router->get("/submission/:submission_id/metadata", function($submission_id) { $this->application->getSubmissionMetaData($submission_id); });

            $router->get("/submission/:submission_id/site/:site_id", function($submission_id, $site_id) { $this->application->getSiteModel($submission_id, $site_id); });
            $router->get("/submission/:submission_id/site/:site_id/sample_group/:sample_group_id", function($submission_id, $site_id, $sample_group_id) { $this->application->getSampleGroupModel($submission_id, $site_id, $sample_group_id); });
            $router->get("/submission/:submission_id/site/:site_id/sample_group/:sample_group_id/sample/:sample_id", function($submission_id, $site_id, $sample_group_id, $sample_id) { $this->application->getSampleModel($submission_id, $site_id, $sample_group_id, $sample_id); });
            $router->get("/submission/:submission_id/site/:site_id/sample_group/:sample_group_id/dataset/:dataset_id", function($submission_id, $site_id, $sample_group_id, $dataset_id) { $this->application->getDataSetModel($submission_id, $site_id, $sample_group_id, $dataset_id); });

            $router->get('/reports/toc', function() { $this->application->getReports(); });
            $router->get('/reports/execute/:sid/:id', function($sid, $id) { $this->application->executeReport($sid, $id); });
            $router->get('/submission/:sid/tables', function($sid) { $this->application->getSubmissionTables($sid); });
            $router->get('/submission/:sid/table/:id', function($sid, $tableid) { $this->application->getSubmissionTableContent($sid, $tableid); });

            $router->get('/copydata', function() { $this->application->copyData(); });
            $router->get('/unittest/:testcase/:arg1/:arg2', function($a, $b, $c) { $this->application->runUnitTest($a, $b, $c); });
            $router->get('/unittest/:testcase/:arg1', function($a, $b) { $this->application->runUnitTest($a, $b); });
            $router->get('/unittest/:testcase', function($a) { $this->application->runUnitTest($a); });
            $router->get('/mailtest', function() { $this->application->mailTest(); });

            /* services */
            $router->get("/submission/:submission_id/claim", function($submission_id) { $this->application->claimSubmission($submission_id); });
            $router->get("/submission/:submission_id/unclaim", function($submission_id) { $this->application->unclaimSubmission($submission_id); });
            $router->get("/submission/:submission_id/transfer", function($submission_id) { $this->application->transferSubmission($submission_id); });

            $router->get("/submission/:submission_id/reject", function($submission_id) { $this->application->rejectSubmission($submission_id); });
            $router->get("/submission/:submission_id/accept", function($submission_id) { $this->application->acceptSubmission($submission_id); });

            $router->get('/nag', function() { $this->application->nag(); });

            return $router;

        }

    }

}
?>