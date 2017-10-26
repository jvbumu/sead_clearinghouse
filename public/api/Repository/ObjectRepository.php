<?php

/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Repository {
    
    class ObjectRepository {
        
        private static $objectMap = array();
        
        public static function getObject($objectId) {
            if(!array_key_exists($objectId, self::$objectMap) ||
               !isset(self::$objectMap[$objectId])){
                $object = self::initObject($objectId);
                if($object === null){
                    throw new \InfraStructure\SEADException('not identified object type: ' . $objectId);
                }
                self::$objectMap[$objectId] = $object;
            }
            return self::$objectMap[$objectId];
        }
        
        private static function initObject($objectKey){
            switch($objectKey){
                case 'RepositoryRegistry':
                    return new \Repository\RepositoryRegistry();
                case 'Locator':
                    return new \Services\Locator();
            }
            return null;
        }
        
    }
}
