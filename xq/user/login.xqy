(:~
: Default log-in page for TiX
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Welcome to TiX - Please Log-in")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <p>{tix-include:checkForWarnings()}</p>
            <h2 class="information">Greetings, TiX User!</h2>
            <p class="strong">Please Log-in using the form below:</p>
            {tix-include:getLoginForm()}
        </div>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>