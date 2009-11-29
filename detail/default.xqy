xquery version "1.0-ml";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";

(: TODO
    if (xdmp:get-current-user() = "nobody") then
        xdmp:redirect-response ("xq/user/login.xqy")
    else :)

declare function local:getDoc() {
    let $doc := doc(xdmp:get-request-field("id"))
    return $doc
};

declare function local:getWorkflow(){

let $workflow-table := 
    <table>
        <tr>
            <th>Workflow Date</th>
            <th>Workflow Comment</th>
            <th>Workflow User</th>
        </tr>
        {
         for $item in local:getDoc()/TicketDocument/WorkflowEvents/WorkflowEvent
            let $inner-node := 
            <tr>
                <td>{xdmp:strftime("%a, %d %b %Y %H:%M:%S",$item/updatedDate/text())}</td>
                <td>{$item/workflowCommentText/text()}</td>
                <td>{$item/workflowUserId/text()}</td>
            </tr>
            return $inner-node
        }
    </table>
       return $workflow-table
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
    {tix-include:getDocumentHead("Ticket Detail for ")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
    <p><a title="Update this document ({xdmp:get-request-field("id")})" href="/update/default.xqy?{xdmp:get-request-field("id")}">Update {xdmp:get-request-field("id")}</a></p>
    <h2>we got this:</h2>
        <dl>
            <dt>Document Stored as:</dt>
            <dd>{xdmp:get-request-field("id")}</dd>
            <dt>Project / Component Id:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/id[1]/text()}</dd>
            <dt>Ticket type:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/type[1]/text()}</dd>
            <dt>Ticket summary:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/summary[1]/text()}</dd>
            <dt>Ticket description:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/description[1]/text()}</dd>
            <dt>Assignee Id:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/assigneeId[1]/text()}</dd>
            <dt>Reporter Id:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/reporterId[1]/text()}</dd>
            <dt>Ticket Priority:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/ticketPriority[1]/text()}</dd>
            <dt>Ticket Created:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/createdDate[1]/text()}</dd>
            <dt>Due Date:</dt>
            <dd>{local:getDoc()/TicketDocument/Ticket[1]/dueDate[1]/text()}</dd>
        </dl>
        {local:getWorkflow()} 
        <p><a title="View XML Representation of the Ticket" href="/detail/xml.xqy?id={xdmp:get-request-field("id")}">View Document (XML)</a></p>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>