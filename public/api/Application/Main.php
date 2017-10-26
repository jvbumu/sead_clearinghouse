<?php

namespace Application {
    
    class Main {

        public $loader = null;
        public $config = null;
        public $registry = null;
        public $logger = null;
        public $locator = null;
        
        protected $submission_service = null;
        private $magic_password = '**********';

        function __construct() {
            \InfraStructure\SEADException::assertLoaded();
            $this->registry = \Repository\ObjectRepository::getObject('RepositoryRegistry');
            $this->locator = \Repository\ObjectRepository::getObject('Locator');
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
        
        public function getRequest()
        {
            return \Slim\Slim::getInstance()->request();;
        }
        
        public function getRequestData()
        {
            $request = \Slim\Slim::getInstance()->request();
            $entity = json_decode($request->getBody());
            if (is_object($entity)) {
                $entity = get_object_vars($entity);
            }
            return $entity;
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
        
        function login() {
            $request = \Slim\Slim::getInstance()->request();
            $payload = array(
                "username" => $request->params("username"),
                "password" => $request->params("password"), //$this->locator->getEncryptPasswordService()->encode($request->params("password")),
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
        
        public function getUser($id) {
            $user = $this->locator->getUserService()->getUser($id);
            $user["password_hash"] = $user["password"];
            $user["password"] =  $this->magic_password; //$this->locator->getEncryptPasswordService()->decode($entity["password"]);
            echo json_encode($user);
        }

        public function deleteUserById($id) {
            echo json_encode($this->locator->getUserService()->deleteById($id));
        }

        public function saveUser() {
            $user = $this->getRequestData();
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

        function getSubmission($id) {
            echo json_encode($this->locator->getSubmissionService()->getSubmission($id));
        }

        function getSubmissionSites($id) {
            echo json_encode($this->locator->getSubmissionService()->getSubmissionSites($id));
        }
        
        function getSubmissionRejects($id) {
            echo json_encode($this->locator->getSubmissionService()->getSubmissionRejects($id));
        }
        
        function claimSubmission($submission_id)
        {
            echo json_encode((new CH_Claim_Command())->execute($submission_id, null));
        }
        
        function unclaimSubmission($submission_id)
        {
            echo json_encode((new CH_Unclaim_Command())->execute($submission_id, null));
        }

        function rejectSubmission($submission_id)
        {
            echo json_encode((new CH_Reject_Command())->execute($submission_id, null));
        }
        
        function acceptSubmission($submission_id)
        {
            echo json_encode((new CH_Accept_Command())->execute($submission_id, null));
        }
        
        function transferSubmission($submission_id)
        {
            echo json_encode((new CH_Transfer_Command())->execute($submission_id, $this->getRequestData()));
        }
        
        function saveSubmissionReject($submission_id, $reject_id) {
            echo json_encode((new CH_Save_Reject_Cause_Command())->execute($submission_id, $this->getRequestData()));
        }

        function deleteSubmissionReject($submission_id, $submission_reject_id) {
            echo json_encode((new CH_Delete_Reject_Cause_Command())->execute($submission_id, $submission_reject_id));
        }

        function processSubmission($submission_id) {
            echo json_encode((new CH_Process_Command())->execute($submission_id, null));
        }
        
        function getRejectTypes() {
            echo json_encode($this->locator->getSubmissionService()->getRejectTypes());
        }

        function processSubmissionQueue() {
            echo json_encode((new CH_Process_Queue_Command())->execute(0, null));
        }

        function getSubmissionMetaData($submission_id)
        {
            echo json_encode((new CH_Open_Command())->execute($submission_id, null));
        }
        
        function getSiteModel($submission_id, $site_id)
        {
            echo json_encode($this->locator->getSiteService()->getSiteModel($submission_id, $site_id));
        }
 
        function getSampleGroupModel($submission_id, $site_id, $sample_group_id)
        {
            echo json_encode($this->locator->getSampleGroupService()->getSampleGroupModel($submission_id, $site_id, $sample_group_id));
        }

        function getSampleModel($submission_id, $site_id, $sample_group_id, $sample_id)
        {
            echo json_encode($this->locator->getSampleService()->getSampleModel($submission_id, /* $site_id, $sample_group_id, */ $sample_id));
        }

        function getDataSetModel($submission_id, $site_id, $sample_group_id, $dataset_id)
        {
            echo json_encode($this->locator->getDataSetService()->getDataSetModel($submission_id, /* $site_id, $sample_group_id, */ $dataset_id));
        }

        function getSites() {
            echo json_encode($this->locator->getSiteService()->getSites());
        }

        function getReports() {
            echo json_encode($this->locator->getReportService()->getReports());
        }

        function executeReport($id, $sid)
        {
            echo json_encode($this->locator->getReportService()->executeReport($id, intval($sid)));
        }
        
        function getSubmissionTables($sid)
        {
            echo json_encode($this->locator->getReportService()->getSubmissionTables(intval($sid)));
        }

        function getSubmissionTableContent($sid, $tableid)
        {
            echo json_encode($this->locator->getReportService()->getSubmissionTableContent(intval($sid), intval($tableid)));
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
        
    }
 
}
?>