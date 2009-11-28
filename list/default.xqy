xquery version "1.0-ml";

import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

declare function local:getCollectionContents($collection as xs:string){
let $node := for $doc in collection($collection)
      return <p><a href="/detail/default.xqy?id={document-uri($doc)}">{document-uri($doc)}-doc</a>
      </p>
return $node
};

<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Tix</title></head>
<body>
<h1>Current tickets</h1>
<h2>request field: {xdmp:get-request-field("colname")}</h2>
<div xmlns="">
  { 
  local:getCollectionContents(xdmp:get-request-field("colname"))
  }
</div>
<h3>and: {tix-common:getDocCount(xdmp:get-request-field("colname"))}</h3>
</body></html>