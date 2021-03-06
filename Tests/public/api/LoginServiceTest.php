<?php
namespace Application\Services;
require __DIR__ . '/../../../vendor/autoload.php';

use PHPUnit\Framework\TestCase;

/**
 * Generated by PHPUnit_SkeletonGenerator 1.2.1 on 2014-03-13 at 13:23:37.
 */
class LoginServiceTest extends TestCase
{
    /**
     * @var LoginService
     */
    protected $object;

    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp()
    {
        $this->object = new LoginService;
    }

    /**
     * Tears down the fixture, for example, closes a network connection.
     * This method is called after a test is executed.
     */
    protected function tearDown()
    {
    }

    /**
     * @covers Application\Services\LoginService::login
     * @todo   Implement testLogin().
     */
    public function testLogin()
    {

        $userName = "test_admin";
        $userPassword = "secret";
        $ip = "130.139.57.55";

        $session = $this->object->login($userName, $userPassword, $ip = null);

        $this->assertTrue($session != null);
        $this->assertEquals($session != null);


    }
}
