<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Model {

   
    /**
     * Description of User
     *
     * @author roma0050
     */
    class User extends \Model\EntityBase {

        Const Role_Undefined = 0;
        Const Role_Reader = 1;
        Const Role_Normal = 2;
        Const Role_Administrator = 3;

        function __construct($propertyBag) {
            parent::__construct($propertyBag);
        }
        
    
    }

}