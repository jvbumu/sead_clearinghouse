<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

//ini_set('include_path', ini_get('include_path'));

require_once __DIR__ . '/../public/api/class_loader.php';

$loader = new ClassLoaderService();
$loader->setup();



?>
