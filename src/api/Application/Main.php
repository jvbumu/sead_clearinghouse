<?php
namespace Application;
//namespace Application {

    class Main {

        public $loader = null;
        public $config = null;
        public $registry = null;
        public $logger = null;
        public $locator = null;
        public $cache = null;

        protected $submission_service = null;
        private $magic_password = '**********';

        function __construct() {
            \InfraStructure\SEADException::assertLoaded();
            $this->registry = \Repository\ObjectRepository::getObject('RepositoryRegistry');
            $this->locator = \Repository\ObjectRepository::getObject('Locator');
            $this->cache = new \Application\JsonCache();
        }

        function isCommandLineInterface()
        {
            return (php_sapi_name() === 'cli');
        }

        protected function getSessionUser()
        {
            $user = \Application\Session::getCurrentUser();
            if ($user == null) {
                throw new \Exception("Session has expired");
            }
            return $user;
        }

        protected function getCurrentSession()
        {
            return \Application\Session::getCurrentSession();
        }

        public function run()
        {
            \Application\ClearingHouseCommand::assertLoad();

            if (!$this->isCommandLineInterface()) {
                session_start();
            }

            \InfraStructure\ErrorHandler::setup();

            $this->config = $this->getConfig();
            $this->logger = new \InfraStructure\Log($this->registry->getConnection(), $this->config['logger']);

            set_time_limit ($this->config["max_execution_time"]);

            return $this;
        }

        function getConfig()
        {
            return \InfraStructure\ConfigService::getConfig();
        }

        function getHelloWorld() {
            echo "Hello, World!";
        }

        function login($request, $response) {
            //$request = \Slim\Slim::getInstance()->request();
            $payload = array(
                "username" => $request->getQueryParam("username"),
                "password" => $request->getQueryParam("password"), //$this->locator->getEncryptPasswordService()->encode($request->params("password")),
                "ip" => \InfraStructure\Utility::getServerIP()
            );
            echo json_encode((new CH_Login_Command())->execute(0, $payload));
        }

        function logout() {
            $user = \Application\Session::getCurrentUser();
            echo json_encode((new CH_Logout_Command())->execute($user ? $user["user_id"] : 0, $user));
        }

        function nag()
        {
            echo json_encode((new CH_Nag_Command())->execute(0, null));
        }

        public function getUsers() {
            echo json_encode($this->locator->getUserService()->getUsers());
        }

        public function getUser($request, $response, $args) {
            $id = $args['user_id'];
            $user = $this->locator->getUserService()->getUser($user_id);
            $user["password_hash"] = $user["password"];
            $user["password"] =  $this->magic_password; //$this->locator->getEncryptPasswordService()->decode($entity["password"]);
            echo json_encode($user);
        }

        public function deleteUserById($request, $response, $args) {
            $user_id = $args['user_id'];
            echo json_encode($this->locator->getUserService()->deleteById($user_id));
        }

        public function saveUser($request, $response) {
            $user = $request->getParsedBody();
            $user["password"] = $user["password"] ==  $this->magic_password ? $user["password_hash"] : password_hash($user["password"], PASSWORD_BCRYPT);
            // $user["password"] = $this->locator->getEncryptPasswordService()->encode($user["password"]);
            echo json_encode((new CH_Save_User_Command())->execute(0, $user));
        }

        function getSubmissionsReport() {
            echo json_encode($this->locator->getSubmissionService()->getSubmissionsReport());
        }

        function getSubmissions() {
            echo json_encode($this->locator->getSubmissionService()->getSubmissions());
        }

        function getSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode($this->locator->getSubmissionService()->getSubmission($submission_id));
        }

        function getSubmissionSites($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode($this->locator->getSubmissionService()->getSubmissionSites($submission_id));
        }

        function getSubmissionRejects($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode($this->locator->getSubmissionService()->getSubmissionRejects($submission_id));
        }

        function claimSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode((new CH_Claim_Command())->execute($submission_id, null));
        }

        function unclaimSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode((new CH_Unclaim_Command())->execute($submission_id, null));
        }

        function rejectSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode((new CH_Reject_Command())->execute($submission_id, null));
        }

        function acceptSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode((new CH_Accept_Command())->execute($submission_id, null));
        }

        function transferSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $data = $request->getParsedBody();
            echo json_encode((new CH_Transfer_Command())->execute($submission_id, $data));
        }

        function saveSubmissionReject($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $reject_id = $args['reject_id'];
            $data = $request->getParsedBody();
            echo json_encode((new CH_Save_Reject_Cause_Command())->execute($submission_id, $data));
        }

        function deleteSubmissionReject($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $reject_id = $args['reject_id'];
            echo json_encode((new CH_Delete_Reject_Cause_Command())->execute($submission_id, $reject_id));
        }

        function processSubmission($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode((new CH_Process_Command())->execute($submission_id, null));
        }

        function getRejectTypes() {
            echo json_encode($this->locator->getSubmissionService()->getRejectTypes());
        }

        function processSubmissionQueue() {
            echo json_encode((new CH_Process_Queue_Command())->execute(0, null));
        }

        function getSubmissionMetaData($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $command = new CH_Open_Command();
            $json_data = $this->executeCommand($command, $submission_id, null);
            echo $json_data;
        }

        function getBootstrapData() {
            $command = new CH_Bootstrap_Command();
            $json_data = $this->executeCommand($command, 0, null);
            echo $json_data;
        }

        function getSiteModel($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $site_id = $args['site_id'];
            echo json_encode($this->locator->getSiteService()->getSiteModel($submission_id, $site_id));
        }

        function getSampleGroupModel($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $site_id = $args['site_id'];
            $sample_group_id = $args['sample_group_id'];
            echo json_encode($this->locator->getSampleGroupService()->getSampleGroupModel($submission_id, $site_id, $sample_group_id));
        }

        function getSampleModel($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $site_id = $args['site_id'];
            $sample_group_id = $args['sample_group_id'];
            $sample_id = $args['sample_id'];
            echo json_encode($this->locator->getSampleService()->getSampleModel($submission_id, /* $site_id, $sample_group_id, */ $sample_id));
        }

        function getDataSetModel($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $site_id = $args['site_id'];
            $sample_group_id = $args['sample_group_id'];
            $dataset_id = $args['dataset_id'];
            echo json_encode($this->locator->getDataSetService()->getDataSetModel($submission_id, /* $site_id, $sample_group_id, */ $dataset_id));
        }

        function getSites() {
            echo json_encode($this->locator->getSiteService()->getSites());
        }

        function getReports() {
            echo json_encode($this->locator->getReportService()->getReports());
        }

        function executeReport($request, $response, $args)
        {
            $report_id = $args['report_id'];
            $submission_id = $args['submission_id'];
            echo json_encode($this->locator->getReportService()->executeReport($report_id, intval($submission_id)));
        }

        function getSubmissionTables($request, $response, $args) {
            $submission_id = $args['submission_id'];
            echo json_encode($this->locator->getReportService()->getSubmissionTables(intval($submission_id)));
        }

        function getSubmissionTableContent($request, $response, $args) {
            $submission_id = $args['submission_id'];
            $table_id = $args['table_id'];
            echo json_encode($this->locator->getReportService()->getSubmissionTableContent(intval($submission_id), intval($table_id)));
        }

        function copyData()
        {
            (new \Test\CopyTestUploads())->copyData();
        }

        function runUnitTest()
        {
            (new \Test\UnitTestService())->run(func_get_args());
        }

        function mailTest() {
            echo json_encode($this->locator->getMailService()->send($this->getSessionUser(), "SEAD TEST SIGNAL", "TEST BODY"));
        }

        function executeCommand($command, $submission_id, $argument)
        {
            $name_parts = explode("\\", get_class($command));
            $cache_id = end($name_parts) . "_{$submission_id}";
            $json_data = $this->cache->getJson($cache_id);
            if ($json_data != null) {
                return $json_data;
            }
            $json_data = json_encode($command->execute($submission_id, $argument));
            $this->cache->putJson($cache_id, $json_data);
            return $json_data;
        }

        function executeService($closure, $cache_id)
        {
            $json_data = $this->cache->getJson($cache_id);
            if ($json_data != null) {
                return json_decode($json_data);
            }
            $data = $closure();
            $json_data = json_encode($data);
            $this->cache->putJson($cache_id, $json_data);
            return $data;
        }
    }

//}
?>