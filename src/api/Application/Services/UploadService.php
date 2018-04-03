<?php

namespace Application\Services {
    
    class UploadService extends \Services\ServiceBase
    {

        function upload($user, $password, $file, $dataTypes = 'ALL') {
            
            if (!isset($file) || $file == "") {
                return "<data>0</data>";
            }

            if (!isset($dataTypes) || $dataTypes == "") {
                $dataTypes = "Updates";
                //throw new \InfraStructure\SEAD_Internal_Error_Exception("Datatypes cannot be undefined");
            }

            $session = $this->locator->getSessionService()->login_user($user, $password, null);
            
            // add check for uploadability.
            if($session['user']['is_readonly']){
                throw new \InfraStructure\SEAD_Access_Denied_Exception("upload not allowed");
            }

            $submission = \Model\SubmissionFactory::createNew($dataTypes, $file, $session["user_id"]);

            $this->registry->getSubmissionRepository()->save($submission);

            if ($submission["submission_id"] == 0) {
                throw new \InfraStructure\SEAD_Internal_Error_Exception("Upload failed");
            }

            /* commented out currently since this function does not exist when 
             * running php as a module in Apache. This can be changed with running 
             * php in CGI mode. No time currently to set that up though. Solve this 
             * by having a pgAgent task, or a cron job do the same work (or trigger ).
             * */
            if (function_exists('pcntl_fork') && pcntl_fork() == 0) {
                $this->locator->getProcessor()->process($submission);
            //    return "";
            }
            
            return "<data>" . $submission["submission_id"] . "</data>";

        }
        
    }
    
}
