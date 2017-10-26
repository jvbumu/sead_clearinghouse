<?php

namespace Repository {
        
    class SampleGroupRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            // TODO: Use some sort of view instead...?
            parent::__construct($conn, "tbl_sample_groups", array("submission_id", "sample_group_id"), $schema_name);
        }
       
        function findBySiteId($submission_id, $site_id)
        {
            return $this->find(array("submission_id" => $submission_id, "site_id" => $site_id) );
        }
        
        // Return all SampleGroups in submission. Used in navigation tree
        function findBySubmissionId($submission_id)
        {
            return $this->find(array("submission_id" => $submission_id) );
        }
 
        function getSampleGroupModel($submission_id, $site_id, $sample_group_id)
        {
            $sample_group = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_client_data", array($submission_id, $sample_group_id), \InfraStructure\DatabaseConnection::Execute_GetFirst);
            $lithologys = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_lithology_client_data", array($submission_id, $sample_group_id));
            $references = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_references_client_data", array($submission_id, $sample_group_id));
            $notes = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_notes_client_data", array($submission_id, $sample_group_id));
            $dimensions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_dimensions_client_data", array($submission_id, $sample_group_id));
            $descriptions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_descriptions_client_data", array($submission_id, $sample_group_id));
            $positions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_group_positions_client_data", array($submission_id, $sample_group_id));
            
            return array(
                
                "local_db_id" => $this->getKeyValueIfExistsOrDefault($sample_group, "local_db_id", 0),
                "entity_type_id" => $this->getKeyValueIfExistsOrDefault($sample_group, "entity_type_id", 0),
                
                "sample_group" => $sample_group,
                
                "lithologys" => $lithologys,
                "references" => $references,
                "notes" => $notes,
                "dimensions" => $dimensions,
                "descriptions" => $descriptions,
                "positions" => $positions
            );
        }
        
        function NotImplemented()
        {
            return array();
        }
        
    }


}

?>