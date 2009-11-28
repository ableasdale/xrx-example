(:~
: Default landing page for TiX
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";

	if (xdmp:get-current-user() = "nobody") then
		xdmp:redirect-response ("xq/user/login.xqy")
	else
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Welcome to TiX!")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        {tix-include:getAdminPanel()}
        TODO: Admin panel and Dashboard Component(s)
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>