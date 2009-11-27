(:~
: Facilitates the saving of a new ticket into the XML Server
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";

import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

xdmp:document-insert(
         tix-common:createFileName("PROJid-", "empty2"), 
         <item>{xdmp:get-request-body()/node()}</item>,
         xdmp:default-permissions(),
         "empty2"), 
<result>
<count>{1 + (fn:count(fn:collection("empty2")))}</count>
<filename>{tix-common:createFileName("PROJid-", "empty2")}</filename>
{xdmp:get-request-body()/node()}
</result>