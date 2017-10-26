<?php

namespace Services {
    
    class ServiceBase {
        
        protected $registry = null;
        protected $locator = null;
        
        function __construct() {
            $this->registry = \Repository\ObjectRepository::getObject('RepositoryRegistry');
            $this->locator = \Repository\ObjectRepository::getObject('Locator');
        }

        // TODO Remove. Only used in SubmissionService & TransferService (use injection instead).
        function getCurrentUser()
        {
            return \Application\Session::getCurrentUser();
        }

    }
    

}

?>
