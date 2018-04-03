<?php

namespace Repository {
         
    class AcceptedQueueRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_accepted_submissions", array("accepted_submission_id"), "clearing_house", "accepted_submission_id");
        }
        
        public function createNew()
        {
            return array(
                'accepted_submission_id' => 0,
                'process_state_id' => 0,
                'submission_id' => 0,
                'upload_file' => null,
                'accept_user_id' => 0
            );
        }
    }

}
   
?>