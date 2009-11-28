xquery version "1.0-ml";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";
xdmp:set-response-content-type("text/html; charset=utf-8"),
let $doc := doc(xdmp:get-request-field("id"))
return
<html>
    <head></head>
    <body>
    <p>Type:{$doc/TicketDocument/Ticket[1]/type[1]/text()}</p>
    <p>Date:{$doc/TicketDocument/Ticket[1]/createdDate[1]/text()}:</p>
    </body>
</html>
