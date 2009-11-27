(:~
: Default logged out page for TiX
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
let $logout := xdmp:logout()

return
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("You are now logged out from TiX")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <h2 class="information">You have been Logged out</h2>
            <p class="strong">You can log in again using the form below:</p>
            {tix-include:getLoginForm()}
        </div>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>