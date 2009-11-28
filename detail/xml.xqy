xquery version "1.0-ml";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

let $crvXML := doc(xdmp:get-request-field("id"))
return

<TicketDocument>
    {$crvXML/TicketDocument/*}
</TicketDocument>
