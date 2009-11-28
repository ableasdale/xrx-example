xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";
xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
    {tix-include:getDocumentHead("TiX Search")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">

    <h2>TiX: Search for '{xdmp:get-request-field("word")}'</h2>
    {
    let $elem := 
        <table>
            <tr>
                <th>View Document</th>
                <th>Summary</th>
                <th>Description</th>
            </tr>
        {
        (: cts:element-values(xs:QName("animal"),"aardvark") [and preceding-sibling::] :)
            for $item in cts:search(//TicketDocument/Ticket (:[and preding-sibling::[1]]:)
            , cts:word-query(xdmp:get-request-field("word")) )
            (:cts:element-value-match(xs:QName("TicketDocument"), "BOO*"):)
            return

            <tr>
                <td><a title="View {xdmp:node-uri($item)}" href="/detail/default.xqy?id={xdmp:node-uri($item)}">View {xdmp:node-uri($item)}</a></td>
                <td>{$item/summary/text()}</td>
                <td>{$item/description/text()}</td>
            </tr>
            }
        </table>
        
    return $elem
    } 
     </div>
    {tix-include:getFooter()}
    </div>
    <script type="text/javascript">
        $('td').highlight('{xdmp:get-request-field("word")}');
    </script>
    </body>
</html>