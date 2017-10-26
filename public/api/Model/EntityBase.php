<?php

namespace Model {
    
    class EntityBase {

        public $propertyBag = null;
        
        function __construct($values) {
            global $application;
            $this->registry = $application->registry;
            $this->propertyBag = $values;
        }

    }

}

?>