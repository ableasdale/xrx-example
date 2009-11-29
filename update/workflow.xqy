(:~
: Default Workflow update service for TiX
:
: N.B. I had to resort to an HTML form (rather than an XForm) as I encountered issues
: with ML XQuery and the XSLTForms PI.  Will work to solve this issue another time..
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";


declare function local:updateStatus() {
    let $u1 := if(string-length(xdmp:get-request-field("status")) > 0) then
        xdmp:node-replace(
            doc(xdmp:get-request-field("id"))/TicketDocument/Ticket[1]/ticketStatus[1]/text(), 
            text{xdmp:get-request-field("status")})
        
        else false()
    return $u1
};

declare function local:updatePriority() {
   let $u2 := if(string-length(xdmp:get-request-field("priority")) > 0) then
        xdmp:node-replace(
            doc(xdmp:get-request-field("id"))/TicketDocument/Ticket[1]/ticketPriority[1]/text(), 
            text{xdmp:get-request-field("priority")})
        
        else false()
    return $u2
};

declare function local:updateReassign() {
   let $u3 := if(string-length(xdmp:get-request-field("assign")) > 0) then
        xdmp:node-replace(
            doc(xdmp:get-request-field("id"))/TicketDocument/Ticket[1]/assigneeId[1]/text(), 
            text{xdmp:get-request-field("assign")})
        
        else false()
    return $u3
};

declare function local:insertWorkflowNode() {

    let $u4 := xdmp:node-insert-child(doc(xdmp:get-request-field("id"))/TicketDocument/WorkflowEvents[1], 
<WorkflowEvent>
      <updatedDate>{current-dateTime()}</updatedDate>
      <workflowCommentText>{xdmp:get-request-field("wf-comment")}</workflowCommentText>
      <workflowUserId>{xdmp:get-current-user()}</workflowUserId>
</WorkflowEvent>)

    return $u4
};

    
local:updateStatus(),
local:updatePriority(),
local:updateReassign(),
local:insertWorkflowNode(),
xdmp:set-response-content-type("text/html; charset=utf-8"),
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Welcome to TiX - Update Document Workflow")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <h2 class="information">GOt values: {xdmp:get-request-field("id")} | {xdmp:get-request-field("wf-comment")} | {xdmp:get-request-field("status")} {string-length(xdmp:get-request-field("status"))} | {xdmp:get-request-field("priority")} | {xdmp:get-request-field("reassign")}</h2>
             </div>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>