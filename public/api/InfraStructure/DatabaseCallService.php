<?php

namespace InfraStructure {

    // Source: http://pgedit.com/resource/php/pgfuncall
    
    class DatabaseCallService
    {
        private $prepared = array();
        private $conn;

        // The contructor takes an existing connection, or a string to create a connection
        function __construct($connection_or_string) {
            if (is_string($connection_or_string)) $this->conn = pg_connect($c);
            else $this->conn = $connection_or_string;
        }

        // Kill all the prepared statements.
        function __destruct() {
            foreach($this->prepared as $statement) {
                $res = pg_query($this->conn, 'deallocate '  . $statement);
            }
        }

        // The __call magic method is called whenever an unknown method for the instance is called.
        function __call($fname, $fargs) {
            $statement = $fname . '__' . count($fargs);
            if (!in_array($statement, $this->prepared)) { // first time, not prepared yet
                $alist = array();            
                for($i = 1; $i <= count($fargs); $i++) {
                    $alist[$i] = '$' . $i;
                }
                $sql = 'select * from ' . $fname . '(' . implode(',', $alist) . ')';
                $prep = pg_prepare($this->conn, $statement, $sql);
                $this->prepared[] = $statement;
            }

            if ($res = pg_execute($this->conn, $statement, $fargs)) {
                $rows = pg_num_rows($res);
                $cols = pg_num_fields($res);
                if ($cols > 1) return $res; // return the cursor if more than 1 col
                else if ($rows == 0) return null;
                else if ($rows == 1) return pg_fetch_result($res, 0); // single result
                else return pg_fetch_all_columns($res, 0); // get column as an array
            }
        }
    }

}

?>