<?php

namespace InfraStructure {
    
    use PDO;
       
    class DatabaseConnection extends PDO {
 
        public static function exception_handler($exception) {

            die('Uncaught exception: ' . $exception->getMessage());
        }
 
        public function __construct($dsn, $username='', $password='', $driver_options=array()) {

            set_exception_handler(array(__CLASS__, 'exception_handler'));

            parent::__construct($dsn, $username, $password, $driver_options);
            
            $this->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            restore_exception_handler();
        }

        public function fetch_all($sql)
        {
            try {               
                return $this->query($sql)->fetchAll(PDO::FETCH_ASSOC);
            } catch (PDOException $ex) {
                error_log($ex->getMessage());
                throw $ex;
//                //return null;
            }
        }
        
        public function fetch_first($sql)
        {
            try {               
                return $this->query($sql)->fetch(PDO::FETCH_ASSOC);
            } catch (PDOException $ex) {
                error_log($ex->getMessage());
                throw $ex;
            }
        }
        
        public function fetch_table($table_name)
        {
            $sql = "Select * From $table_name";                
            return $this->fetch_all($sql);

        }
        
        // TODO: Make more general i.e. allow complex keys
        public function save_record($table_name, $id_value_array, &$row, $affected_columns = NULL, $serial_id = NULL, $ignore_fields = NULL)
        {
            if ($table_name == NULL || $table_name == "") {
                throw new \Exception ("Table name mandatory upon row save");
            }
            
            if (!is_array($id_value_array) || count($id_value_array) == 0) {
                throw new \Exception ("Argument exception: id_colums must be a non-empty array");
            }
            
            if ($row == NULL || !is_array($row) || count($row) == 0) {
                throw new \Exception ("Argument exception: passed values must be an array");
            }
        
            $column_list = ConnectionStatementHelper::getAffectedColumns($row, $id_value_array, $affected_columns, $serial_id, $ignore_fields);

            $is_new = ConnectionStatementHelper::isNew($row, $id_value_array);
                    
            if ($is_new) {
                $sql = ConnectionStatementHelper::getInsertSqlStatement($table_name, $column_list);
       
            } else {
                $sql = ConnectionStatementHelper::getUpdateSqlStatement($table_name, $column_list, array_keys($id_value_array));
            }
            
            $arguments = ConnectionStatementHelper::getParameterValues($row, $column_list, $id_value_array);

            //echo $sql . "\n";
            
            $statement = $this->prepare($sql);
            //error_log(gettimeofday() . $sql . "\n", 3, '/var/tmp/php_log.log');

            $ok = $statement->execute($arguments);
            
            if ($ok) {
                //error_log(gettimeofday() . "execute is ok + is_new = $is_new & serial id = $serial_id\n", 3, '/var/tmp/php_log.log');
                if ($is_new && $serial_id <> NULL) {
                    $result = $statement->fetchAll();
                    //error_log(gettimeofday() .  "Result: $result\n", 3, '/var/tmp/php_log.log');
                    if (count($result) > 0) {
                        $id = $result[0][$serial_id]; //$this->lastInsertId();
                        $row[$serial_id] = $id;
                    }
                }
            } else {
                throw new \Exception("DB call failed: [$sql]");
            }    
            return $ok;

        }
        
        public function delete_record($table_name, $id_values)
        {
            try {
                $sql = ConnectionStatementHelper::getDeleteSqlStatement($table_name, array_keys($id_values));
                $statement = $this->prepare($sql);
                $ok = $statement->execute($id_values);            
                return $ok;
            } catch(PDOException $e) {
                echo '{"error":{"text":'. $e->getMessage() .'}}'; 
            }
        }
        
        Const Execute_GetAll = 0;
        Const Execute_GetFirst = 1;
        
        public function execute_procedure($procedure_name, $arguments, $execute_option = self::Execute_GetAll)
        {
            try {
                $parameters = count($arguments) > 0 ? implode(",", array_fill(0, count($arguments), "?")) : "";
                $statement = $this->prepare("Select * From $procedure_name(" . $parameters . ")");
                $statement->execute($arguments);
                $result = $statement->fetchAll(\PDO::FETCH_ASSOC);
                if ($execute_option == self::Execute_GetFirst) {
                    return count($result) > 0 ? $result[0] : null;
                }
                return $result;
            } catch (Exception $ex) {
                echo $ex->getMessage();
            }
        }
    } 
    
    class ConnectionStatementHelper
    {
        public static function isNew($assoc_array, $id_values)
        {
            foreach ($id_values as $column => $value) {
                if (!key_exists($column, $assoc_array))
                    continue;
                if ($value != 0)
                    return false;
            }
            return true;
        }
        
        public static function getAffectedColumns($row, $id_values, $include_columns, $serial_id, $ignore_fields)
        {
            /* Ignore array columns */
            $db_row = array_filter($row, function($x) { return !is_array($x); });
            
            $keys = array_keys($db_row);
            
            return array_filter($keys,
                function ($column) use ($id_values, $include_columns, $serial_id, $ignore_fields) {
                    if (array_key_exists($column, $id_values) || $column == $serial_id)
                        return false;
                    if ($ignore_fields != null && array_key_exists($column, $ignore_fields))
                        return false;
                    if (\InfraStructure\Utility::startsWith($column, "_"))
                        return false;
                    if ($include_columns != NULL && !in_array($column, $include_columns))
                        return false;
                    return true;
                }
            );
        }

        public static function getParameterValues($assoc_array, $column_list, $id_value_array = NULL)
        {
            $values = array();
            foreach ($column_list as $column) {
                $value = $assoc_array[$column];
                $values[":$column"] = is_bool($value) ?
                                    ($value ? 1 : 0) :
                                    $value;
            }
            // TODO : verify bugg
            if (!ConnectionStatementHelper::isNew($assoc_array, $id_value_array)) {
                foreach ($id_value_array as $key => $id) {
                    $values[":$key"] = $id; // <==> $assoc_array[$key]
                }
            }
            return $values;
        }
        
        public static function getDeleteKeyValues($id_values)
        {
            $values = array();
            foreach ($id_values as $key => $id) {
                $values[":$key"] = $id;
            }
            return $values;
        }
        
        public static function getInsertSqlStatement($table_name, $column_list)
        {

            $comma_column_list = implode(',', $column_list);
            $comma_parameter_list = implode(',', array_map(function ($x) { return ":$x"; }, $column_list));

            return "INSERT INTO $table_name ($comma_column_list) Values ($comma_parameter_list) RETURNING *";

        }
        
        public static function getUpdateSqlStatement($table_name, $column_list, $id_columns)
        {
            if ($id_columns == NULL || !is_array($id_columns) || count($id_columns) == 0)
                throw new \Exception ("getUpdateSqlStatement Argument exception: passed id_columns must be an array");

            $set_value_sql = implode(',', array_map(function ($x) { return "$x = :$x"; }, $column_list));
            $id_value_sql = implode(' AND ', array_map(function ($x) { return "$x = :$x"; }, $id_columns));
                
            return "UPDATE $table_name SET $set_value_sql WHERE $id_value_sql";
        }
        
        public static function getDeleteSqlStatement($table_name, $id_columns)
        {
            if ($id_columns == NULL || !is_array($id_columns) || count($id_columns) == 0)
                throw new \Exception ("getDeleteSqlStatement Argument exception: passed id_columns must be an array");

            $id_value_list = implode(' AND ', array_map(function ($x) { return "$x = :$x"; }, $id_columns));
                
            return "DELETE FROM $table_name WHERE $id_value_list";
        }
        
    }

    
}

?>