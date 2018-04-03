<?php

require_once __DIR__ . '/class_loader.php';

$loader = new ClassLoaderService();
$loader->setup();

$application = new \Application\Main();
$application->run();

$router = new \Application\Router($application);
$router->run();


?>