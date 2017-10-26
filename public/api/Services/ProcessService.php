<?php

namespace Services {

   
    /**
     * Transfers NEW submission to PENDING state.
     *
     * Submission in state NEW are processed in the following way:
     * 1) Content is decoded and uncompressed and stored as plain xml (xml type).
     *
     * @category   Submission state transfer
     * @package    Services
     * @author     Roger Mähler <roger.mahler@umu.se>
     * @copyright  2013 SEAD
     * @license    
     * @version    Release: @package_version@
     * @link       
     * @see        
     * @since      
     * @deprecated 
     */
    class ProcessService extends ServiceBase {

        public function findAllNew() {
            return $this->registry->getSubmissionRepository()->findAllNew();
        }       

        public function process($submission)
        {
            
            if (!$this->locator->getCanProcessSubmissionSpecification()->IsSatisfiesBy($submission))
                throw new \Exception("ProcessSubmissionSpecification policy not satisfied");

            if ($submission["upload_content"] != null) {
                $content = $submission["upload_content"];
                $submission["xml"] = $this->locator->getXmlDecoder()->decode($content);
                $this->registry->getSubmissionRepository()->save($submission, array("xml"));            
            }

            if ($submission["xml"] != null) {
                $this->locator->getXmlExploder()->explode($submission["submission_id"]);
            }

            $submission["submission_state_id"] = \Model\Submission::State_Pending;

            $this->registry->getSubmissionRepository()->save($submission, array("submission_state_id"));

            return;

        }

    }

    class ExplodeXmlSubmissionService extends ServiceBase {

        public function explode($submission)
        {          
            $this->registry->getSubmissionRepository()->processExplodeXML2RDB($submission["submission_id"]);
        }

    }


}