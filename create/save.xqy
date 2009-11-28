(:~
: Facilitates the saving of a new ticket into the XML Server
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

declare function local:getRequestBodyElement() {
    let $element := xdmp:get-request-body()/node()
    return $element
};

xdmp:document-insert(
         tix-common:createFileName("DEF", "empty3"), 
         <TicketDocument>
            {local:getRequestBodyElement()/*}
         </TicketDocument>,
         xdmp:default-permissions(),
         "empty3"), 
xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
    {tix-include:getDocumentHead("Ticket Created Successfully!")}
    <body>
        <div id="container">
            {tix-include:getHeader()}
            <div id="main-content">
                <div id="cta" class="center">
                    <h2 class="information">Thanks for filing a Ticket with TiX!</h2>
                    <p>The following information has been submitted:</p>
                    <p>{local:getRequestBodyElement()/Ticket[1]/type[1]/text()}</p>
                    <p>DEBUG: <a href="http://localhost:8005/list/default.xqy?colname=empty3">LIST</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>