xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";


declare function local:getDocument() {
    let $doc := doc(xdmp:get-request-field("id"))
    return $doc
};

declare function local:setReporter() {
    let $u1 := xdmp:node-replace(doc(xdmp:get-request-field("id"))/TicketDocument/Ticket[1]/reporterId[1]/text(), text{xdmp:get-current-user()} )
    return $u1
};


declare function local:setCreatedDate() {
    let $u2 := xdmp:node-replace(doc(xdmp:get-request-field("id"))/TicketDocument/Ticket[1]/createdDate[1]/text(), text{current-dateTime()} )
    return $u2
};

declare function local:createWorkflowNode() {
    let $u3 := xdmp:node-insert-after(doc(xdmp:get-request-field("id"))/TicketDocument/Ticket,
    <WorkflowEvents/>)
    return $u3
};

local:setReporter(),
local:setCreatedDate(),
local:createWorkflowNode(),
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
                    <dl>
                        <dt>Document Stored as:</dt>
                        <dd>{xdmp:get-request-field("id")}</dd> 
                        <dt>Project / Component Id:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/id[1]/text()}</dd>
                        <dt>Ticket type:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/type[1]/text()}</dd>
                        <dt>Ticket summary:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/summary[1]/text()}</dd>
                        <dt>Ticket description:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/description[1]/text()}</dd>
                        <dt>Assignee Id:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/assigneeId[1]/text()}</dd>
                        <dt>Ticket Priority:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/ticketPriority[1]/text()}</dd>
                        <dt>Due Date:</dt>
                        <dd>{local:getDocument()/TicketDocument/Ticket[1]/dueDate[1]/text()}</dd>
                    </dl>
                    <p><a title="List all currently open tickets" href="/list/default.xqy?colname=tixOpen">List All Open Tickets</a></p>
                    <p><a title="View HTML Representation of the Ticket" href="/detail/default.xqy?id={xdmp:get-request-field("id")}">View Document (XHTML)</a></p>
                    <p><a title="View XML Representation of the Ticket" href="/detail/xml.xqy?id={xdmp:get-request-field("id")}">View Document (XML)</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>