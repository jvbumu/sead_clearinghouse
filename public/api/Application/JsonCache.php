<?php

namespace Application {
    
    class JsonCache {

        public $cache_dir = null;

        function __construct() {
            //$this->cache_dir = dirname(__FILE__) . '/../../api-cache';
            $this->cache_dir = './api-cache';
        }       
        
        // function getConfig()
        // {
        //     return \InfraStructure\ConfigService::getConfig();
        // }

        function getJson($id, $expires = NULL ) {
        
            $cache_file = $this->cache_dir . '/cache-' . $id . '.json';

            if (!$expires) $expires = time() - 2*60*60;
        
            if (!file_exists($cache_file))
                return NULL;

            $json_data = file_get_contents($cache_file);

            if (filectime($cache_file) < $expires || $json_data == '') {
               unlink($cache_file);
               return NULL;
            }

            return $json_data;
        }

        function putJson($id, $json_data) {
            $cache_file = $this->cache_dir . '/cache-' . $id . '.json';
            if (file_exists($cache_file)) {
                unlink($cache_file);
            }
            file_put_contents($cache_file, $json_data);
        }
        
    }
 
}

?>