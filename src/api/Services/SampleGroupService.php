<?php

namespace Services {
    
    class SampleGroupService extends ServiceBase {

        public function getSampleGroupModel($submission_id, $site_id, $sample_group_id)
        {
            return $this->registry->getSampleGroupRepository()->getSampleGroupModel($submission_id, $site_id, $sample_group_id);
        }

    }
    
}

?>