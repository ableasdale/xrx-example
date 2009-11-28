(:~
: Default User registration page for TiX
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";

if (xdmp:get-current-user() != "admin") then
    let $session-field := xdmp:set-session-field("login-status", "notadmin")
    return
    xdmp:redirect-response ("/xq/user/login.xqy")
else

xdmp:set-response-content-type("text/html; charset=utf-8"),
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Welcome to TiX - Create New User")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <h2 class="information">Create a New User</h2>
            <p class="strong">Please fill in all fields below:</p>
            
            <form action="/xq/user/register.xqy" method="post"> 
                <p class="inputfield">
                    <label for="username">User (login) name: </label>
                    <input id="username" type="text" name="user" />
                </p>
                
                <p class="inputfield">
                    <label for="description">Full name: </label>
                    <input type="description" name="desc" />
                </p>
    
                <p class="inputfield">
                    <label for="password">Password: </label>
                    <input type="password" name="password" />
                </p>
                
                <p class="inputfield">
                    <label for="password">Confirm Password: </label>
                    <input type="password" name="password2" />
                </p>
    
                <p>
                    <input type="submit" name="submit" value="Submit" />
                </p>
            </form>
         </div>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>