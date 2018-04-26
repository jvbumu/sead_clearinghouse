<?php
namespace Application;

require_once __DIR__ . '/../../vendor/autoload.php';
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\ResponseInterface;
//use Slim\Slim;


    class Router {

        public $application = null;
        public $router = null;
        public $config = null;

        function __construct($application) {
            //Slim::registerAutoloader();
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

            $router = new \Slim\App($this->config);
            $container = $router->getContainer();
            $container['application'] = function($c) { return $this->application; };

            // $router->contentType('application/json');

            $router->get('/helloworld', function(ServerRequestInterface $request, ResponseInterface $response)
            {
                $this->application->getHelloWorld();
            });

            $router->get('/bootstrap', function(ServerRequestInterface $request, ResponseInterface $response) {
                $this->application->getBootstrapData();
            });

            $router->get('/login', function(ServerRequestInterface $request, ResponseInterface $response) {
                $this->application->login($request, $response);
            });

            $router->get('/logout', function(ServerRequestInterface $request, ResponseInterface $response) {
                $this->application->logout();
            });

            $router->get('/users', function(ServerRequestInterface $request, ResponseInterface $response) {
                $this->application->getUsers();
            });

            $router->get('/users/{user_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getUser($request, $response, $args);
            });

            $router->post('/users', function() {
                $this->application->saveUser();
            });

            $router->put('/users', function() {
                $this->application->saveUser();
            });

            $router->delete('/users/{user_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->deleteUserById($request, $response, $args);
            });

            $router->get('/sites', function() {
                $this->application->getSites();
            });

            $router->get('/submissions_report', function() {
                $this->application->getSubmissionsReport();
            });

            $router->get('/submissions', function() {
                $this->application->getSubmissions();
            });

            $router->get('/submissions/{submission_id}/process', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->processSubmission($request, $response, $args);
            });

            $router->get('/submissions/process_queue', function() {
                $this->application->processSubmissionQueue();
            });

            $router->get('/submissions/{submission_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmission($request, $response, $args);
            });

            $router->get('/submissions/{submission_id}/sites', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmissionSites($request, $response, $args);
            });

            $router->get('/reject_entity_types', function() {
                $this->application->getRejectTypes();
            });

            $router->get('/submissions/{submission_id}/rejects', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmissionRejects($request, $response, $args);
            });

            $router->post('/submissions/{submission_id}/rejects', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->saveSubmissionReject($request, $response, $args);
            });

            $router->put('/submissions/{submission_id}/rejects', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->saveSubmissionReject($request, $response, $args);
            });

            $router->put('/submissions/{submission_id}/rejects/{reject_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->saveSubmissionReject($request, $response, $args);
            });

            $router->delete('/submissions/{submission_id}/rejects/{reject_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->deleteSubmissionReject($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/metadata", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmissionMetaData($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/site/{site_id}", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSiteModel($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/site/{site_id}/sample_group/{sample_group_id}", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSampleGroupModel($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/site/{site_id}/sample_group/{sample_group_id}/sample/{sample_id}",
                function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                    $this->application->getSampleModel($request, $response, $args);
                });

            $router->get("/submission/{submission_id}/site/{site_id}/sample_group/{sample_group_id}/dataset/{dataset_id}",
                function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                    $this->application->getDataSetModel($request, $response, $args);
                });

            $router->get('/reports/toc', function() {
                $this->application->getReports();
            });

            $router->get('/reports/execute/{submission_id}/{report_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->executeReport($request, $response, $args);
            });

            $router->get('/submission/{submission_id}/tables', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmissionTables($request, $response, $args);
            });

            $router->get('/submission/{submission_id}/table/{table_id}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->getSubmissionTableContent($request, $response, $args);
            });

            $router->get('/copydata', function() { $this->application->copyData(); });

            $router->get('/unittest/{testcase}/{a}/{b}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->runUnitTest($request, $response, $args);
            });

            $router->get('/unittest/{testcase}/{a}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->runUnitTest($request, $response, $args);
            });

            $router->get('/unittest/{testcase}', function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->runUnitTest($request, $response, $args);
            });

            $router->get('/mailtest', function() {
                $this->application->mailTest();
            });

            /* services */
            $router->get("/submission/{submission_id}/claim", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->claimSubmission($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/unclaim", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->unclaimSubmission($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/transfer", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->transferSubmission($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/reject", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->rejectSubmission($request, $response, $args);
            });

            $router->get("/submission/{submission_id}/accept", function(ServerRequestInterface $request, ResponseInterface $response, $args) {
                $this->application->acceptSubmission($request, $response, $args);
            });

            $router->get('/nag', function() {
                $this->application->nag();
            });

            return $router;

        }

    }

?>