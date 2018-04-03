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

        function getJson($id, $longivity = 2 * 60 * 60 ) {

            $cache_file = $this->cache_dir . '/cache-' . $id . '.json';

            if (!file_exists($cache_file))
                return NULL;

            $now = time();
            $death = filemtime($cache_file) + $longivity;
            if ($now > $death) {
               unlink($cache_file);
               return NULL;
            }
            $json_data = file_get_contents($cache_file);
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