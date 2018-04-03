<?php

namespace InfraStructure {
     
    use PDO;

    class ConnectionFactory {

        public static function Create($options)
        {
            $hostname = $options["hostname"];
            $port = $options["port"];
            $username = $options["username"];
            $password = $options["password"];
            $database = $options["database"];
            return new DatabaseConnection("pgsql:dbname=$database;host=$hostname;port=$port", $username, $password, array(PDO::ATTR_PERSISTENT => true));
        }
        
        public static function CreateDefault()
        {
            return ConnectionFactory::Create(DatabaseConfig::getConfig());
        }       
        
        
    }
    
    class DatabaseConfig {
        
        public static function GetConfig()
        {
            return \InfraStructure\ConfigService::getDatabaseConfig();
        }
    }
 
    
}

?>
