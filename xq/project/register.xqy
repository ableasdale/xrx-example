(: TODO - xqDoc :)
xquery version "1.0-ml";

import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

let $name := xdmp:get-request-field("name", ""),
    $desc := xdmp:get-request-field("desc", "")

return
let $done := tix-common:updateProjectDoc($name, $desc)

return
xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
    {tix-include:getDocumentHead("Project Created Successfully!")}
    <body>
        <div id="container">
            {tix-include:getHeader()}
            <div id="main-content">
                <div id="cta" class="center">
                    <h2 class="information">Your Project has been registered with TiX!</h2>
                    <p>The following information has been submitted:</p>
                    <!-- TODO - why can't I use $name and $desc here? -->
                    <p><strong>Project Id/Code: </strong> {xdmp:get-request-field("name", "")}</p>
                    <p><strong>Project Name: </strong> {xdmp:get-request-field("desc", "")}</p>
                    <p><a title="This will take you back to your dashboard" href="/">Home</a></p>
                </div>
            </div>
            {tix-include:getFooter()}
        </div>
    </body>
</html>

