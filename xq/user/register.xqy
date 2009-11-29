(:
::     Registers a TiX user
::    
::      The design pattern for this method is based a method found in this document:
::      <strong>http://xqzone.marklogic.com/svn/userlogin/trunk/register.xqy</strong>
::      and neither currently handle a user which already exists.
:)
xquery version "1.0-ml";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

let $user := xdmp:get-request-field("user", ""),
    $password := xdmp:get-request-field("password", ""),
    $password2 := xdmp:get-request-field("password2", ""),
    $desc := xdmp:get-request-field("desc", "")
    
return
if (($password != $password2) or ($password = "")) then
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("TiX: Issue with your password?")}
    <body>
        <div id="container">
            {tix-include:getHeader()}
            <div id="main-content">
                <div id="cta" class="center">
                { if (($password = "") and ($password2 = "")) then
                    <h2>You did not provide a password</h2>
                else
                    <h2>You did not type the same password both times</h2>
                }
                    <p>Please <a title="Create a new user account" href="/xq/user/registration-form.xqy">try again</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>
else if (tix-common:registerUser($user,$desc,$password)) then
    let $updateUserDoc := tix-common:updateUserDoc($user, $desc)
    return
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("TiX: User Account Created")}
    <body>
        <div id="container">
            {tix-include:getHeader()}
            <div id="main-content">
                <div id="cta" class="center">
                    <h2 class="information">Good News!</h2>
                    <p>The account {$user} has now been created.</p>
                    <p>While you're logged in as an administrator, why not <a title="Create a new user account" href="/xq/user/registration-form.xqy">create more?</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>
else 
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("TiX: Bad News... :( ")}
    <body>
        <div id="container">
            {tix-include:getHeader()}
            <div id="main-content">
                <div id="cta" class="center">
                    <h2 class="information">Looks like something went wrong...</h2>
                    <p>Please contact your administrator at <a href="mailto:admin@example.com">admin@example.com</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>