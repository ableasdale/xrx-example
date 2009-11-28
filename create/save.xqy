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

declare function local:getXmlDocumentName() {
    let $filename := tix-common:createFileName(local:getProjectId(), "tixOpen")
    return $filename
};

declare function local:getProjectId() as xs:string {
    let $projectId := xdmp:get-request-body()/node()/Ticket[1]/id[1]/text()
    return $projectId
};

declare function local:saveDoc() {
    let $save :=
    xdmp:document-insert(
             local:getXmlDocumentName(), 
             <TicketDocument>
                {local:getRequestBodyElement()/*}
             </TicketDocument>,
             xdmp:default-permissions(),
             "tixOpen")
return $save
};

declare function local:createRedirectString(){
    let $redirect := fn:concat("/create/update.xqy?id=", local:getXmlDocumentName())
(: xdmp:redirect-response(local:createRedirectString()) :)
    return $redirect
};

local:saveDoc(),
xdmp:redirect-response(local:createRedirectString())