<?php

namespace Services {
    
    
    /**
     * Decodeds and decompresses data received from data provider.
     *
     * Content is decoded and uncompressed as plain xml (xml type).
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
    class DecodeService {

        public function decode($content)
        {

            try {
                $compressed_content = base64_decode($content);
                return gzdecode($compressed_content);
            } catch (Exception $ex) {
                error_log($ex.getMessage());
            }
        }

        // public function encode($content)
        // {
        //     try {
        //         return base64_encode(\gzencode($content));
        //     } catch (Exception $ex) {
        //         error_log($ex.getMessage());
        //     }
        // }
    }
    
    
}

?>