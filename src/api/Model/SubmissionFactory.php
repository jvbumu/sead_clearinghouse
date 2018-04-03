<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Model {

    /**
     * Description of Submission
     *
     * @author roma0050
     */
    class SubmissionFactory {

        public static function createNew($data_types, $data, $user_id)
        {
            return array(
                "submission_id" => 0,
                "submission_state_id" => \Model\Submission::State_New,
                "data_types" => $data_types,
                "upload_user_id" => $user_id,
                "upload_date" => \InfraStructure\Utility::Now(),
                "upload_content" => $data,
                "xml" => null,
                "status_text" => "",
                "claim_user_id" => null,
                "claim_date_time" => null
                );
        }
    }
}