xquery version "1.0-ml";
import module namespace tix-table = "http://www.alexbleasdale.co.uk/tix-table" at "/xq/modules/table_module.xqy";
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
    {tix-table:getSearchResults()}
     </div>
    {tix-include:getFooter()}
    </div>
    <script type="text/javascript">
        $('td').highlight('{xdmp:get-request-field("word")}');
    </script>
    </body>
</html>