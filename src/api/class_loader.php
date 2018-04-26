<?php

class ClassLoaderService
{
    function map()
    {
        return array(
            'Application' => __DIR__ . '/',
            'InfraStructure' => __DIR__  . '/',
            'Repository' => __DIR__  . '/',
            'Services' => __DIR__  . '/',
            'Model' => __DIR__  . '/',
            //'Psr' => __DIR__ . '/Vendor/',
            //'Monolog' => __DIR__ . '/Vendor/',
            //'Slim' => __DIR__  . '/Vendor/',
            'Test' => __DIR__ . '/'
        );
    }

    function setup()
    {
        require_once __DIR__ . '/vendor/autoload.php';
        #include_once __DIR__ . '/Vendor/composer_autoloader.php';

        // $loader = new \Composer\Autoload\ClassLoader();

        // $map = $this->map();

        // foreach ($map as $namespace => $directory) {
        //     $loader->add($namespace, $directory);
        // }

        // $loader->register();

        return $this;
    }

}

?>
