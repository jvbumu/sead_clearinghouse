<?php

/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Application\Services {
    
    class SubmissionResultService extends \Services\ServiceBase {
        
        function getSubmissionResult($user, $password, $submissionId){
            
            if(!isset($submissionId) || $submissionId == 0){
                throw new \InfraStructure\SEAD_Invalid_State_For_Operation_Exception('submission');
            }
            
            $session = $this->locator->getSessionService()->login_user($user, $password, null);
            
            $rejects = $this->registry->getSubmissionRejectRepository()->findBySubmissionId($submissionId);
            
            $submission = $this->registry->getSubmissionRepository()->findByIdX($submissionId);
            
            if($submission === null){
                throw new \InfraStructure\SEAD_No_Such_Submission();
            }
            
            if(intval($submission["upload_user_id"]) != $session["user"]["user_id"]){
                throw new \InfraStructure\SEAD_Access_Denied_Exception('Access is denied'); // this the wrong user for the submission.
            }
            
            if(intval($submission["submission_state_id"]) < \Model\Submission::State_Accepted){
                throw new \InfraStructure\SEAD_Submission_Not_Validated();
            }
            
            
        }
    }
}