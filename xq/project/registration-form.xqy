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
    {tix-include:getDocumentHead("Welcome to TiX - Create New Project")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <h2 class="information">Create a New Project</h2>
            <p class="strong">Please fill in all fields below:</p>
            
            <form action="/xq/project/register.xqy" method="post"> 
                <p class="inputfield">
                    <label for="projname">Project Code/Acronym (Max 5 Characters): </label>
                    <input id="projname" type="text" name="name" maxlength="5" />
                </p>
                
                <p class="inputfield">
                    <label for="description">Project name: </label>
                    <input id="description" type="text" name="desc" />
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