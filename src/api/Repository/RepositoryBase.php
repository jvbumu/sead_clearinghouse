<?php

// YODO : Replaxe impl with some kind of ORM framework...
namespace Repository {
         
    class  RepositoryBase {

        protected $con = null;
        protected $schema_name;
        protected $table_name;
        protected $key_column_names;
        protected $serial_column_name;
        protected $ignore_fields;
                
        function __construct(&$con, $tablename, $id_columns, $schema_name = "clearing_house", $serial_id = NULL, $ignore_fields = NULL) {
            $this->schema_name = $schema_name;
            $this->table_name = $tablename;
            $this->key_column_names = is_string($id_columns) ? array($id_columns) : $id_columns;
            $this->con =& $con;
            $this->serial_column_name = $serial_id;
            $this->ignore_fields = $ignore_fields;
            
            if (!is_array($this->key_column_names)) {
                throw new \Exception("Repository id_columns must be an array");
            }
        }
        
        public function getAdapter()
        {
            return $this->con;
        }
 
        public function getTablename()
        {
            return $this->schema_name . "." . $this->table_name;
        }
        
        public function findById()
        {   
            $key_values = QueryHelper::getArgKeyValues($this->key_column_names, func_num_args(), func_get_args());        
            $result = $this->find($key_values);
            return (count($result) == 1) ? $result[0] : null;  
        }
 
        public function save(&$entity, $affected_columns = NULL)
        {   
            $key_values = QueryHelper::getEntityKeyValues($this->key_column_names, $entity);        
            return $this->getAdapter()->save_record($this->getTablename(), $key_values, $entity, $affected_columns, $this->serial_column_name, $this->ignore_fields);
        }
        
        public function deleteById()
        {   
            $key_values = QueryHelper::getArgKeyValues($this->key_column_names, func_num_args(), func_get_args());        
            return $this->getAdapter()->delete_record($this->getTablename(), $key_values);
        }

        public function findAll()
        {   
            return $this->find(array());
        }

        public function find($filter)
        {           
            return $this->getAdapter()->fetch_all(QueryHelper::generateQuery($this->getTablename(), $filter));
        }

        public function getEntityTypeId()
        {
            $sql = "Select x.*
                    From clearing_house.tbl_clearinghouse_reject_entity_types x
                    Join clearing_house.tbl_clearinghouse_submission_tables t
                      On x.table_id = t.table_id
                    Where t.table_name_underscored = '" . $this->$table_name . "'";
            $row = $this->getAdapter()->fetch_first($sql);
            return ($row ? $row["entity_type_id"] : 0);
        }
        
        public function getKeyValueIfExistsOrDefault($values, $key, $default)
        {
            if ($values == null)
                return $default;
            return array_key_exists($key, $values) ? $values[$key] : $default;
        }
        
    }
    
    class  QueryHelper {
        
        public static function getArgKeyValues($key_column_names, $num_args, $args)
        {
            if ($num_args < count($key_column_names)) {
                throw new \Exception("RepositoryBase.generateKeyFilter Argument Exception (arg count)");
            }
            $values = array();
            for ($i = 0; $i < count($key_column_names); $i++) {
                $values[$key_column_names[$i]] = $args[$i];
            }
            return $values;
        }
        
        public static function getEntityKeyValues($key_column_names, $entity)
        {
            $values = array();
            for ($i = 0; $i < count($key_column_names); $i++) {
                if (!key_exists($key_column_names[$i], $entity))
                    continue;
                $values[$key_column_names[$i]] = $entity[$key_column_names[$i]];
            }
            return $values;
        }
        
        public static function generateQuery($source, $filter)
        {   
            return "Select * From " . $source . " Where 1 = 1 " . QueryHelper::generateWhere($filter) . " ";
        }
        
        public static function nullif($prefix, $column, $flag)
        {
            return $flag ? "$prefix.$column" : "null as $column";
        }

        public static function generateWhere($filter)
        {
            $where_clause = "";
            foreach ($filter as $column => $value) {
                if (is_array($value)) {
                    if (count($value) == 0) {
                        $where_clause .= " And 1 = 2 ";
                    } else {
                        $where_clause .= " And $column In (" . QueryHelper::stringify($value) . ") ";
                    }
                } else {
                    $where_clause .= " And $column = " . QueryHelper::stringify($value) . " ";
                }
            }
            return $where_clause;
        }
        
        public static function stringify($value)
        {
            if (is_string($value)) {
                return "'$value'";
            }
            if (is_array($value)) {
                return implode (",", array_map(
                    function ($s) { return QueryHelper::stringify($s); },
                    $value
                ));
            }
            return strval($value);
        }
        
    }

}
?>