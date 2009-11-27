(:
 : Copyright (c) 2004 Mark Logic Corporation
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :)

import module "http://marklogic.com/xdmp/security" at "/xq/modules/security.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

let $user := xdmp:get-request-field("user", ""),
    $password := xdmp:get-request-field("password", ""),
    $password2 := xdmp:get-request-field("password2", ""),
    $desc := xdmp:get-request-field("desc", "")


return
if (($password != $password2) or ($password = "")) then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <body>
	{ if (($password = "") and ($password2 = "")) then
		<h2>You did not provide a password</h2>
          else
		<h2>You did not type the same password both times</h2>
	}
        <p>
        Please hit the "Back" button and re-type your password
        </p>
      </body>
    </html>
	
else if (tix-common:registerUser($user,$desc,$password)) then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <body>
        <h2>Congratulations! You are successfully registered with the site</h2>
        <p>
        Please login by clicking <a href="login.xqy"> login </a>
        </p>
      </body>
    </html>

else 
    <html xmlns="http://www.w3.org/1999/xhtml">
      <body>
        There are problems in registering. Please contact the site administrator at <a href="mailto:admin@yourdomain.com">admin@yourdomain.com</a>
      </body>
    </html>
