(:~
: Manages user validation for TiX
:
: @author Alex Bleasdale
: @version 1.0
:)
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

let $user := xdmp:get-request-field ("user", ""),
    $password := xdmp:get-request-field ("password", "")
return
	if (tix-common:validateLogin($user,$password)) then
	   let $session-field := xdmp:set-session-field("login-status", "valid")
	   return
	   xdmp:redirect-response("/default.xqy")
	else
	   let $session-field := xdmp:set-session-field("login-status", "invalid")
	   return
	   xdmp:redirect-response("/xq/user/login.xqy")
