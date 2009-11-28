xquery version "1.0-ml";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";

(: TODO
    if (xdmp:get-current-user() = "nobody") then
        xdmp:redirect-response ("xq/user/login.xqy")
    else :)

let $crvXML := doc(xdmp:get-request-field("id"))
return
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Ticket Detail for ")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
    
    <h2>we got this:</h2>
        <dl>
            <dt>Ticket type:</dt>
         
            <dd>{$crvXML/TicketDocument/Ticket[1]/type[1]/text()}</dd>
            <dt>Ticket summary:</dt>
            <dd>{$crvXML/TicketDocument/Ticket[1]/summary[1]/text()}</dd>
            <dt>Ticket description:</dt>
            <dd>{$crvXML/TicketDocument/Ticket[1]/detail[1]/text()}</dd>
        </dl>
        <!--
        
        
        <summary>example summary</summary>
    <description>example description</description>
    <assigneeId>assigneeId</assigneeId>
    <reporterId>reporterId</reporterId>
    <ticketPriority>Medium</ticketPriority>
    <createdDate>2001-12-31T12:00:00</createdDate>
    <dueDate>2001-12-31T12:00:00</dueDate>
        -->
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>