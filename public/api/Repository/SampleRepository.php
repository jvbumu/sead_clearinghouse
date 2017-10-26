<?php

namespace Repository {
        
    class SampleRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            // TODO: Use some sort of view instead...?
            parent::__construct($conn, "tbl_physical_samples", array("submission_id", "physical_sample_id"), $schema_name);
        }
       
 
        function getSampleModel($submission_id, $sample_id)
        {

            $sample = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_client_data", array($submission_id, $sample_id), \InfraStructure\DatabaseConnection::Execute_GetFirst);
            $alternative_names = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_alternative_names_client_data", array($submission_id, $sample_id));
            $features = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_features_client_data", array($submission_id, $sample_id));
            $notes = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_notes_client_data", array($submission_id, $sample_id));
            $dimensions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_dimensions_client_data", array($submission_id, $sample_id));
            $descriptions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_descriptions_client_data", array($submission_id, $sample_id));
            $horizons = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_horizons_client_data", array($submission_id, $sample_id));
            $colours = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_colours_client_data", array($submission_id, $sample_id));
            $images = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_images_client_data", array($submission_id, $sample_id));
            $locations = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_sample_locations_client_data", array($submission_id, $sample_id));

            return array(

                "local_db_id" => $this->getKeyValueIfExistsOrDefault($sample, "local_db_id", 0),
                "entity_type_id" => $this->getKeyValueIfExistsOrDefault($sample, "entity_type_id", 0),
                
                "sample" => $sample,
                
                "alternative_names" => $alternative_names,
                "features" => $features,
                "notes" => $notes,
                "dimensions" => $dimensions,
                "descriptions" => $descriptions,
                "horizons" => $horizons,
                "colours" => $colours,
                "images" => $images,
                "locations" => $locations
                
            );
            
        }
        
        function NotImplemented()
        {
            return array();
        }
        
    }


}

?>