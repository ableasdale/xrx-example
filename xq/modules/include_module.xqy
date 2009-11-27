(:~
: Module providing standard markup components for re-use across pages 
:
: @author Alex Bleasdale
: @version 1.0
:)

xquery version "1.0-ml";

module namespace tix-include="http://www.alexbleasdale.co.uk/tix-include";
import module "http://marklogic.com/xdmp/security" at "security.xqy";

declare function tix-include:getDocumentHead($pageName as xs:string){
  let $head := <head xmlns="http://www.w3.org/1999/xhtml"><title>{$pageName} | TiX Bug Tracker v1.0</title><link rel="stylesheet" type="text/css" media="screen, projection" href="../../css/styles.css" /></head>
  return $head  
};

declare function tix-include:getCurrentUserCredentials(){
  let $credentials-pane := 
  if (xdmp:get-current-user() = "nobody") then
    <div class="split-pane">
        <p class="left">Currently not logged in</p>
        <br class="clearboth" />
    </div>
 else
    <div class="split-pane">
            <p class="left">Currently Logged in as: <span class="user">{xdmp:get-current-user()}</span></p>
            <p class="right"><a href="/xq/user/logout.xqy" title="This will end your TiX session">Logout</a></p>
            <br class="clearboth" />
    </div>
 
 return $credentials-pane
};

declare function tix-include:getAdminUserLink(){
    let $admin-panel := if (xdmp:get-current-user() = "admin") then
        <p class="cta-panel">Administrators: <a href="registration-form.xqy">create new user account</a></p>
    else 
        <p class="cta-panel">Not got an account yet? <a href="mailto:administrator@example.com">Request one here</a></p>
    return $admin-panel
};

declare function tix-include:getLoginForm(){
   let $login-form :=
   <div id="login-component">
   <form action="/xq/user/validatelogin.xqy" method="post"> 
    <p class="inputfield">
        <label for="username">User name: </label>
        <input id="username" type="text" name="user" />
    </p>
    
    <p class="inputfield">
        <label for="password">Password: </label>
        <input type="password" name="password" />
    </p>
    
    <p>
        <input type="submit" name="submit" value="Submit" />
    </p>
   </form>
   {tix-include:getAdminUserLink()}
   </div>
   return $login-form
};

declare function tix-include:getHeader(){
    let $header := 
    <div id="header">
        <h1>TiX : XML Bug Tracking System (v0.1)</h1>
        {tix-include:getCurrentUserCredentials()}
    </div>
    return $header
};

declare function tix-include:getFooter(){
    let $footer :=
    <div id="footer">
        <h3>&#x00A9; 2009 TiX | Privacy Policy | Support</h3>
        {tix-include:getCurrentUserCredentials()}
    </div>
    return $footer
};

declare function tix-include:checkForWarnings(){
    let $status := 
    if (xdmp:get-session-field("login-status") = "invalid") then
    <p class="cta-warning">Invalid credentials provided - try again?</p>
    else if (xdmp:get-session-field("login-status") = "notadmin") then
    <p class="cta-warning">You need to be logged in as <strong>administrator</strong> to create user accounts</p>
    else
    <p class="cta-info">Welcome! Please log in using the form below</p>
    return $status
};