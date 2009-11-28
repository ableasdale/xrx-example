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

declare function local:getProjectId() as xs:string {
    let $projectId := xdmp:get-request-body()/node()/Ticket[1]/id[1]/text()
    return $projectId
};

declare function local:getXmlDocumentName() as xs:string {
    let $filename := tix-common:createFileName(local:getProjectId(), "tixOpen")
    return $filename
};

(: fn:current-dateTime   :)
xdmp:document-insert(
         local:getXmlDocumentName(), 
         <TicketDocument>
            {local:getRequestBodyElement()/*}
         </TicketDocument>,
         xdmp:default-permissions(),
         "tixOpen"), 
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
                        <dd>Document Stored as:</dd>
                        <dt>{local:getXmlDocumentName()}</dt>
                        <dd>Project / Component Id:</dd>
                        <dt>{local:getRequestBodyElement()/Ticket[1]/id[1]/text()}</dt>  
                        <dt>Project / Component Id:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/id[1]/text()}</dd>
                        <dt>Ticket type:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/type[1]/text()}</dd>
                        <dt>Ticket summary:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/summary[1]/text()}</dd>
                        <dt>Ticket description:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/description[1]/text()}</dd>
                        <dt>Assignee Id:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/assigneeId[1]/text()}</dd>
                        <dt>Reporter Id:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/reporterId[1]/text()}</dd>
                        <dt>Ticket Priority:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/ticketPriority[1]/text()}</dd>
                        <dt>Ticket Created:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/createdDate[1]/text()}</dd>
                        <dt>Due Date:</dt>
                        <dd>{local:getRequestBodyElement()/Ticket[1]/dueDate[1]/text()}</dd>
                    </dl>
                    
                    <p>DEBUG: <a href="/list/default.xqy?colname=tixOpen">LIST</a></p>
                    <p>DEBUG: <a href="/detail/default.xqy?id={local:getXmlDocumentName()}">View Doc</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>