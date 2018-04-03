<?php

namespace Services {
    
    class DataSetService extends ServiceBase {

        public function getDataSetModel($submission_id, $dataset_id)
        {
            $model = $this->registry->getDataSetRepository()->getDataSetModel($submission_id, $dataset_id);
            
            foreach ($this->getTransformServices() as $item) {
                if (isset($model[$item["data_key"]]) && is_array($model[$item["data_key"]])) {
                    $model[$item["data_key"]] = $item["service"]->transform($model[$item["data_key"]]);
                }
            }
            
            return $model;
        }
        
        function getTransformServices()
        {
            return array(
                array("data_key" => "measured_values", "service" => new MeasuredValueTransposeService()),
                array("data_key" => "abundance_values", "service" => new AbundanceValueTransposeService())
            );
        }
        
    }
    
    class MeasuredValueTransposeService extends ServiceBase
    {
        public function transform($measured_values)
        {
            $samples = $this->getUniqueSamples($measured_values);
            $methods = $this->getUniqueMethods($measured_values);
            
            $entity_type_id = count($measured_values) > 0 ? $measured_values[0]["entity_type_id"] : 0;
            $data_matrix = $this->buildMatrix($samples, $methods, $entity_type_id);
            
            $this->collectValues($data_matrix, $measured_values);
            
            $columns = $this->createColumns($samples, $methods);
            
            return array("data" => array_values($data_matrix), "columns" => $columns);
        }
        
        function getUniqueSamples($measured_values)
        {
            $samples = array();
            foreach ($measured_values as $value) {
                if (!array_key_exists($value["local_db_id"], $samples)) {
                    $samples[$value["local_db_id"]] = array(
                        "physical_sample_id" => $value["local_db_id"],
                        "sample_name" => $value["sample_name"]
                    );
                }
            }
            return $samples;
        }
        
        function getUniqueMethods($measured_values)
        {
            $methods = array();
            foreach ($measured_values as $value) {
                $key = $value["method_id"] . "_" . ($value["prep_method_id"] ?: "0");
                if (!array_key_exists($key, $methods)) {
                    $methods[$key] = array(
                        "key" => $key,
                        "method_id" => $value["method_id"],
                        "method_name" => $value["method_name"],
                        "prep_method_id" => $value["prep_method_id"],
                        "prep_method_name" => $value["prep_method_name"]
                    );
                }
            }
            return $methods;
        }
        
        function buildMatrix($samples, $methods, $entity_type_id)
        {
            $result = array();
            foreach ($samples as $sample) {
                $row = array();
                $row["local_db_id"] = $sample["physical_sample_id"];
                $row["physical_sample_id"] = $sample["physical_sample_id"];
                $row["sample_name"] = $sample["sample_name"];
                $row["entity_type_id"] = $entity_type_id;
                foreach ($methods as $method) {
                    $row["local_" . $method["key"]] = null;
                    $row["public_" . $method["key"]] = null;
                }
                
                $result[$sample["physical_sample_id"]] = $row;
            }           
            return $result;
        }
        
        function collectValues(&$data, $measured_values)
        {
            foreach ($measured_values as $value) {
                $key = $value["method_id"] . "_" . ($value["prep_method_id"] ?: "0");
                $data[$value["local_db_id"]]["local_" . $key] = $value["measured_value"];
                $data[$value["local_db_id"]]["public_" . $key] = $value["public_measured_value"];
            }
        }
        
        function createColumns($samples, $methods)
        {
            $columns = array();
            
            $columns[] = array("column_name" => "Id", "column_field" => "physical_sample_id");
            $columns[] = array("column_name" => "Sample", "column_field" => "sample_name");
 
            foreach ($methods as $method) {
                $columns[] = array(
                    "column_name" => $method["method_name"],
                    "column_field" => "local_" . $method["key"],
                    "column_tooltip" => $method["prep_method_name"],
                    "public_column_field" => "public_" . $method["key"],
                    "class" => "sead-number"
                );
            }
            return $columns;
        }
    }
    
    class AbundanceValueTransposeService extends ServiceBase
    {
        public function transform($abundance_values)
        {
            
            $entity_type_id = count($abundance_values) > 0 ? $abundance_values[0]["entity_type_id"] : 0;

            $taxons = $this->getUniqueTaxons($abundance_values);
            $samples = $this->getUniqueSamples($abundance_values);
            
            $data = $this->buildMatrix($taxons, $samples, $entity_type_id);
            
            $this->collectValues($data, $abundance_values);
            
            $columns = $this->createColumns($taxons, $samples);
            
            return array("data" => array_values($data), "columns" => $columns);
        }

        function getUniqueTaxons($abundance_values)
        {
            $taxons = array();
            foreach ($abundance_values as $value) {
                if (!array_key_exists($value["taxon_id"], $taxons)) {
                    $taxons[$value["taxon_id"]] = array(
                        "taxon_id" => $value["taxon_id"],
                        "genus_name" => $value["genus_name"],
                        "species" => $value["species"],
                        "author_name" => $value["author_name"],
                        "element_name" => $value["element_name"],
                        "modification_type_name" => $value["modification_type_name"],
                        "identification_level_name" => $value["identification_level_name"]
                    );
                }
            }
            return $taxons;
        }
        
        function getUniqueSamples($abundance_values)
        {
            $samples = array();
            foreach ($abundance_values as $value) {
                if (!array_key_exists($value["physical_sample_id"], $samples)) {
                    $samples[$value["physical_sample_id"]] = array(
                        "physical_sample_id" => $value["physical_sample_id"],
                        "sample_name" => $value["sample_name"]
                    );
                }
            }
            return $samples;
        }

        function buildMatrix($taxons, $samples, $entity_type_id)
        {
            $result = array();
            foreach ($taxons as $taxon) {
                $row = array();
                $row["local_db_id"] = $taxon["taxon_id"];
                $row["taxon_id"] = $taxon["taxon_id"];
                $row["taxon"] = ($taxon["species"] ?: "") . " " . ($taxon["genus_name"] ?: "") . " " . ($taxon["author_name"] ?: "");
                $row["element_name"] = $taxon["element_name"];
                $row["modification_type_name"] = $taxon["modification_type_name"];
                $row["identification_level_name"] = $taxon["identification_level_name"];
                $row["entity_type_id"] = $entity_type_id;
                foreach ($samples as $key => $sample) {
                    $row["abundance_" . $sample["physical_sample_id"]] = "";
                    $row["public_" . $sample["physical_sample_id"]] = "";
                }
                
                $result[$taxon["taxon_id"]] = $row;
            }           
            return $result;
        }
        
        function collectValues(&$data, $abundance_values)
        {
            foreach ($abundance_values as $value) {
                $data[$value["taxon_id"]]["abundance_" . $value["physical_sample_id"]] = $value["abundance"];
                $data[$value["taxon_id"]]["public_abundance_" . $value["physical_sample_id"]] = $value["public_abundance"];
            }
        }
        
        function createColumns($species, $samples)
        {
            $columns = array();
            
            $columns[] = array("column_name" => "Id", "column_field" => "local_db_id");
            $columns[] = array("column_name" => "Taxon", "column_field" => "taxon", "class" => "nobr");
            $columns[] = array("column_name" => "Element Name", "column_field" => "element_name");
            $columns[] = array("column_name" => "Modification Type", "column_field" => "modification_type_name");
            $columns[] = array("column_name" => "Identitification Level", "column_field" => "identification_level_name");
 
            foreach ($samples as $sample) {
                $columns[] = array(
                    "column_name" => $sample["sample_name"],
                    "column_field" => "abundance_" . $sample["physical_sample_id"],
                    //"column_tooltip" => $sample["sample_name"],
                    "public_column_field" => "public_abundance_" . $sample["physical_sample_id"],
                    "class" => "sead-number"
                );
            }
            return $columns;
        }
        
    }
    
}

?>