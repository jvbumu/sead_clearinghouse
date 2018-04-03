<?php

namespace Repository {
        
    class SubmissionRejectRepository extends RepositoryBase {

        protected $child_repository = NULL;
        
        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_submission_rejects", array("submission_reject_id"), 'clearing_house', 'submission_reject_id');
            $this->child_repository = new SubmissionRejectEntityRepository($conn, 'clearing_house');
        }
       
        function findBySubmissionId($submission_id)
        {
            return $this->find(array("submission_id" => $submission_id));
        }
 
        function find($filter)
        {
            $rejects = parent::find($filter);
            $reject_entities = $this->child_repository->findByRejectIds(array_map(function ($x) { return $x["submission_reject_id"]; }, $rejects));
            foreach ($rejects as &$reject) {
                $subset = array_filter($reject_entities, function($x) use($reject) { return $x["submission_reject_id"] == $reject["submission_reject_id"]; });
                $reject["reject_entities"] = $subset;
            }
            return $rejects;
        }
        
        public function save(&$reject, $affected_columns = NULL)
        {   
            try {
                $ok = parent::save($reject, $affected_columns);
                if (isset($reject["reject_entities"])) {
                    $reject_entities = $reject["reject_entities"];
                    $submission_reject_id = $reject["submission_reject_id"];
                    foreach ($reject_entities as &$reject_entity) {
                        $reject_entity->submission_reject_id = $submission_reject_id;
                        $a_entity = (array)$reject_entity;
                        $ok = $ok && $this->child_repository->save($a_entity);
                        $reject_entity->reject_entity_id = $a_entity["reject_entity_id"];
                    }
                }
                return $ok;
            } catch (Exception $ex) {
                throw $ex;
            }
        }
        
        protected $RejectTypes = null;
        function getRejectTypes()
        {
            if ($this->RejectTypes == null) {
                $this->RejectTypes = $this->getAdapter()->fetch_table("clearing_house.tbl_clearinghouse_reject_entity_types");
            }
            
            return $this->RejectTypes;
        }

        function getRejectTypeName($entity_type_id)
        {
            foreach ( $this->getRejectTypes() as $entity) {
                if ($entity["entity_type_id"] == $entity_type_id)
                    return $entity["entity_type"];
            }
            return "?";
        }
        
        // TODO : Read from DB
        function getRejectScopes()
        {
            return array(0 => "Unknown", 1 => "Specific", 2 => "General");
        }
    }

    class SubmissionRejectEntityRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            // TODO: Use some sort of view instead...?
            parent::__construct($conn, "tbl_clearinghouse_submission_reject_entities", array("reject_entity_id"), 'clearing_house', 'reject_entity_id');
        }
       
        function findByRejectIds($value_or_array)
        {
            if (is_array($value_or_array) && count($value_or_array) == 0)
                return array();
            return $this->find(array("submission_reject_id" => $value_or_array) );
        }
    }
}

?>