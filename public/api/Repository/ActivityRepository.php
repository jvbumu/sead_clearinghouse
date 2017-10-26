<?php

namespace Repository {
         
    class ActivityRepository extends RepositoryBase {

        Const Generic_Entity_Type = 0;
        Const User_Entity_Type = 1;
        Const Submission_Entity_Type = 2;
        
        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_activity_log", array("activity_log_id"), $schema_name, "activity_log_id");
        }
        
        function findByEntityId($entity_type_id, $entity_id)
        {
            return $this->find(array("entity_type_id" => $entity_type_id, "entity_id" => $entity_id));
        }
        
        function findBySubmissionId($submission_id)
        {
            return $this->findByEntityId(self::Submission_Entity_Type, $submission_id);
        }
    }

}
   
?>