<?php

namespace Services {
    
    class SiteService extends ServiceBase {

        static function __classLoad() {
        }
        
        function getSites()
        {
            return $this->registry->getSiteRepository()->findAll();
        }

        function getSite($id)
        {
            return $this->registry->getSiteRepository()->find($id);
        }
        
        function getSiteModel($submission_id, $site_id)
        {
            return $this->registry->getSiteRepository()->getSiteModel($submission_id, $site_id);
        }

    }
    
}

?>