xquery version "0.9-ml"

(: Copyright 2002-2009 Mark Logic Corporation.  All Rights Reserved. :)

module "http://marklogic.com/xdmp/security"

declare namespace gr="http://marklogic.com/xdmp/group"

(:
::
:: sec:create-user(
::      $user-name as xs:string,  
::      $description as xs:string?,
::      $password as xs:string,  
::      $role-names as xs:string*,  
::      $permissions as element(sec:permission)*,  
::      $collections as xs:string*)
:: as xs:unsignedLong
::
:: Summary:
::
::      Creates a new user in the system database for the context database. 
::      Returns the user ID of the created user.  
::
:: Parameters:
::
::      $user-name 
::            A unique username. If $user-name is not unique, an error is 
::            returned.  
::  
::      $description 
::           A description of the user.  
::  
::      $password 
::           The initial password for this user.  
::  
::      $role-names 
::           The roles (if any) assigned to this user. If one of the 
::            $role-names names a role that does not exist, an error is 
::            returned.  
::  
::      $permissions 
::            The default permissions granted to this user.  
::  
::      $collections 
::            The default collections to which this user has access.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/create-user and, for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
create-user(
  $user-name as xs:string,
  $description as xs:string?, 
  $password as xs:string, 
  $role-names as xs:string*,
  $permissions as element(sec:permission)*,
  $collections as xs:string*)
as xs:unsignedLong
{
  try {
    let $assert := 
            xdmp:security-assert(
              "http://marklogic.com/xdmp/privileges/create-user",
              "execute"),
        $bad := 
          if (xdmp:castable-as(security-namespace(), "user-name", $user-name))
          then ()
          else if ($user-name) 
          then fn:error("SEC-BADUSERNAME")
          else fn:error("SEC-NOEMPTYUSERNAME"),
        $badPerms := validate-permissions($permissions),
        $col := security-collection(),
        $curr-user :=  xdmp:get-current-user(),
        $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
        $duplicate := 
          if (fn:exists(fn:collection($col)/sec:user/sec:user-name[.=$user-name]))
          then fn:error("SEC-USEREXISTS") 
          else (),
        $pass := 
          if ($password = "") 
          then fn:error("SEC-EMPTYPWD")
          else (),
        $default-permissions := user-doc-permissions(),
        $default-collections := user-doc-collections(),
        $uri := "http://marklogic.com/xdmp/users/",
        $user-id := get-unique-elem-id("user-name()",$user-name),
        $default-cols := 
          for $d in $collections 
          return <sec:uri>{$d}</sec:uri>,
        $realm := 
            fn:data(/sec:metadata/sec:realm)
    return
      let $insert := xdmp:document-insert(
        fn:concat($uri, xs:string($user-id)),
        <sec:user>
          <sec:user-id>{$user-id}</sec:user-id>
          <sec:user-name>{$user-name}</sec:user-name>
          <sec:description>{$description}</sec:description>
          <sec:password>{xdmp:crypt($password, 
                                xs:string($user-id))}</sec:password>
          <sec:digest-password>{xdmp:md5(fn:concat($user-name,":",
                                                  $realm,":",
                                                  $password))}</sec:digest-password>
          <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>
          <sec:permissions>{$permissions}</sec:permissions>
          <sec:collections>{$default-cols}</sec:collections>
        </sec:user>,
        $default-permissions,
        $default-collections)
      return (
        xdmp:audit("userconfig",$user-name,"create-user",fn:true()),
        $user-id
      )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"create-user",fn:false()),
    xdmp:rethrow()
  }

}

(:
::
:: sec:create-user-with-role(
::      $user-name as xs:string,  
::      $description as xs:string?,
::      $password as xs:string,  
::      $role-names as xs:string*,  
::      $permissions as element(sec:permission)*,  
::      $collections as xs:string*)
:: as xs:unsignedLong
::
:: Summary:
::
::      Creates a new user in the system database for the context database. 
::      Returns the user ID of the created user.  Also creates a role by the
::      same name and assigns the newly-created user to the newly-created role.
::      Parameters that define roles, permissions, and collections are only 
::      applied to the new user.
::
:: Parameters:
::
::      $user-name 
::            A unique username. If $user-name is not unique, an error is 
::            returned.  
::  
::      $description 
::           A description of the user.  
::  
::      $password 
::           The initial password for this user.  
::  
::      $role-names 
::           The roles (if any) assigned to this user. If one of the 
::            $role-names names a role that does not exist, an error is 
::            returned.  
::  
::      $permissions 
::            The default permissions granted to this user.  
::  
::      $collections 
::            The default collections to which this user has access.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/create-user,
::       http://marklogic.com/xdmp/privileges/create-role and, for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
create-user-with-role(
  $user-name as xs:string,
  $description as xs:string?, 
  $password as xs:string, 
  $role-names as xs:string*,
  $permissions as element(sec:permission)*,
  $collections as xs:string*)
as xs:unsignedLong
{
  try {
    let $assert := 
          (xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/create-user",
            "execute"),
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/create-role",
            "execute")),   
        $bad := 
          if (xdmp:castable-as(security-namespace(), "user-name", $user-name))
          then ()
          else if ($user-name) 
          then fn:error("SEC-BADUSERNAME")
          else fn:error("SEC-NOEMPTYUSERNAME"),
        $badPerms := validate-permissions($permissions),
        $col := security-collection(),
        $curr-user :=  xdmp:get-current-user(),
        $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
        $duplicate := 
          fn:collection($col)/sec:user/sec:user-name[.=$user-name],
        $duplicate-role := 
          fn:collection($col)/sec:role/sec:role-name[.=$user-name],
        $pass := 
          if ($password = "") 
          then fn:error("SEC-EMPTYPWD")
          else (),
        $err := 
          if (fn:exists($duplicate)) 
          then fn:error("SEC-USEREXISTS") 
          else (),
        $err := 
          if (fn:exists($duplicate-role)) 
          then fn:error("SEC-ROLEEXISTS") 
          else (),
        $default-u-permissions := user-doc-permissions(),
        $default-u-collections := user-doc-collections(),
        $default-r-permissions := role-doc-permissions(),
        $default-r-collections := role-doc-collections(),
        $u-uri := "http://marklogic.com/xdmp/users/",
        $user-id := get-unique-elem-id("user-name()",$user-name),
        $r-uri := "http://marklogic.com/xdmp/roles/",
        $role-id := get-unique-elem-id("role-name()",$user-name),
        $default-cols := 
          for $d in $collections 
          return <sec:uri>{$d}</sec:uri>,
        $realm := 
            fn:data(/sec:metadata/sec:realm)
    return
      (xdmp:document-insert(
        fn:concat($u-uri, xs:string($user-id)),
        <sec:user>
          <sec:user-id>{$user-id}</sec:user-id>
          <sec:user-name>{$user-name}</sec:user-name>
          <sec:description>{$description}</sec:description>
          <sec:password>{
            xdmp:crypt(
              $password,xs:string($user-id))
          }</sec:password>
          <sec:digest-password>{xdmp:md5(fn:concat($user-name,":",
                                                  $realm,":",
                                                  $password))
          }</sec:digest-password>
          <sec:role-ids>{
              (get-role-ids($role-names),
              <sec:role-id>{$role-id}</sec:role-id>)
          }</sec:role-ids>
          <sec:permissions>{$permissions}</sec:permissions>
          <sec:collections>{$default-cols}</sec:collections>
        </sec:user>,
        $default-u-permissions,
        $default-u-collections),
      xdmp:document-insert(fn:concat($r-uri, xs:string($role-id)),
        <sec:role>
          <sec:role-id>{$role-id}</sec:role-id>
          <sec:role-name>{$user-name}</sec:role-name>
          <sec:description>{$description}</sec:description>
          <sec:role-ids/>
          <sec:permissions/>
          <sec:collections/>
        </sec:role>,
        $default-r-permissions,
        $default-r-collections),
      $user-id,
      xdmp:audit("userconfig",$user-name,"create-user",fn:true()),
      xdmp:audit("roleadd",$user-name,$role-names,fn:true())
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"create-user",fn:false()),
    xdmp:audit("roleadd",$user-name,$role-names,fn:false()),
    xdmp:rethrow()
  }
}

(:
::
:: sec:user-set-name(
::      $user-name as xs:string,  
::      $new-user-name as xs:string,
::      $password as xs:string )
:: as  empty() 
::
:: Summary:
::
::      Changes the name of the user from $user-name to $new-user-name.  
::
:: Parameters:
::
::      $user-name 
::            The existing name of the user.  
::  
::      $new-user-name 
::            The new name of the user.  
::  
::      $password 
::            The password to set for the user.  This can be either the 
::            original password for the user or a new password.
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-set-name if the 
::       currrent user is not $user-name.  
:: 
:: Usage Notes:
::
::       If a user with name equal to $user-name is not found, an error is 
::       returned. If $new-user-name is not unique, an error is returned.  
::
:)

define function
user-set-name(
  $user-name as xs:string,
  $new-user-name as xs:string,
  $password as xs:string)
as empty()
{
  try {
    let $curr-user := xdmp:get-current-user(),
        $bad := 
          if (xdmp:castable-as(security-namespace(), "user-name", $new-user-name)) 
          then ()
          else if ($new-user-name) 
          then fn:error("SEC-BADUSERNAME")
          else fn:error("SEC-NOEMPTYUSERNAME"),
        $verify := 
          if ($curr-user = $user-name) 
          then fn:true()
          else 
            xdmp:security-assert(
              "http://marklogic.com/xdmp/privileges/user-set-name",
              "execute"),
        $col := security-collection(),
        $user := get-element($col, "sec:user", 
                            "sec:user-name",$user-name, 
                            "SEC-USERDNE"),
        $pass := 
          if ($password = "") 
          then fn:error("SEC-EMPTYPWD")
          else (),
        $has-digest := fn:not(fn:empty($user/sec:digest-password)),
        $realm := 
            fn:data(/sec:metadata/sec:realm),
        $duplicate := fn:collection($col)/sec:user/sec:user-name[.=$new-user-name]
    return
      if (fn:exists($duplicate))
      then fn:error("SEC-UNEXISTS")
      else if($user-name = $new-user-name) then
        ()
      else (
        xdmp:node-replace(
          $user/sec:user-name, 
          <sec:user-name>{$new-user-name}</sec:user-name>),
  
        xdmp:node-replace(
          $user/sec:password,
          <sec:password>{xdmp:crypt($password,
          xs:string($user/sec:user-id))}</sec:password>),
        if($has-digest) then
          xdmp:node-replace(
            $user/sec:digest-password,
            <sec:digest-password>{xdmp:md5(fn:concat($new-user-name,":",
                                                    $realm,":",
                                                    $password))}
            </sec:digest-password>)
        else
          xdmp:node-insert-child($user,
            <sec:digest-password>{xdmp:md5(fn:concat($new-user-name,":",
                                                    $realm,":",
                                                    $password))}
            </sec:digest-password>),
      xdmp:audit("userconfig",$user-name,"change-user-name",fn:true())
      )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"change-user-name",fn:false()),
    xdmp:rethrow()
  }
}

(:
::
:: sec:user-set-password(
::      $user-name as xs:string,  
::      $password as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Changes the password for the user identified by $user-name to 
::      $password.  
::
:: Parameters:
::
::      $user-name 
::           The name of the user.  
::  
::      $password 
::           The new password. If $password is the empty string, an error 
::            is returned.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-set-password if 
::       the currrent user is not $user-name.  
::
:)

define function 
user-set-password(
  $user-name as xs:string, 
  $password as xs:string)
as empty()
{ 
  try {
    let $curr-user := xdmp:get-current-user(),
        $verify := 
          if ($curr-user = $user-name) 
          then fn:true()
          else 
            xdmp:security-assert(
              "http://marklogic.com/xdmp/privileges/user-set-password",
              "execute"),
        $col := security-collection(), 
        $user := get-element($col, "sec:user", 
                            "sec:user-name",$user-name, 
                            "SEC-USERDNE"),
        $pass := 
          if ($password = "") 
          then fn:error("SEC-EMPTYPWD")
          else (),
        $has-digest := fn:not(fn:empty($user/sec:digest-password)),
        $realm := 
            fn:data(/sec:metadata/sec:realm)
    return (
      xdmp:node-replace(
        $user/sec:password,
        <sec:password>{xdmp:crypt($password,
        xs:string($user/sec:user-id))}</sec:password>),
      if($has-digest) then
        xdmp:node-replace(
          $user/sec:digest-password,
          <sec:digest-password>{xdmp:md5(fn:concat($user-name,":",
                                                  $realm,":",
                                                  $password))}
          </sec:digest-password>)
      else
        xdmp:node-insert-child($user,
          <sec:digest-password>{xdmp:md5(fn:concat($user-name,":",
                                                  $realm,":",
                                                  $password))}
          </sec:digest-password>),
      xdmp:audit("userconfig",$user-name,"change-password",fn:true())  
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"change-password",fn:false()),
    xdmp:rethrow()  
  }
}

(:
::
:: sec:user-set-description(
::      $user-name as xs:string,  
::      $description as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Changes the description of the user identified by $user-name to 
::      $description. Requires a privilege if the currrent user is 
::      not $user-name.  
::
:: Parameters:
::
::      $user-name 
::           The name of the user.  
::  
::      $description 
::            A description of the user.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-set-description  
::
:)

define function 
user-set-description(
  $user-name as xs:string,
  $description as xs:string)
as empty()
{
  try {
    let $curr-user := xdmp:get-current-user(),
        $verify := 
          if ($curr-user = $user-name) 
          then fn:true()
          else 
            xdmp:security-assert(
              "http://marklogic.com/xdmp/privileges/user-set-description",
              "execute"),
        $col := security-collection(),
        $user := get-element($col, "sec:user", 
                            "sec:user-name",$user-name, 
                            "SEC-USERDNE")
    return (
      xdmp:node-replace(
        $user/sec:description, 
        <sec:description>{$description}</sec:description>),
      xdmp:audit("userconfig",$user-name,"change-description",fn:true())
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"change-description",fn:false()),
    xdmp:rethrow()
  }      
}

(:
::
:: sec:role-set-description(
::      $role-name as xs:string,  
::      $description as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Changes the description of the role identified by $role-name to 
::      $description.  
::
:: Parameters:
::
::      $role-name 
::           The name of the role.  
::  
::      $description 
::           A description of the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-set-description 
::       if the currrent role is not $role-name.  
::
:)

define function 
role-set-description(
  $role-name as xs:string,
  $description as xs:string)
as empty()
{
  let $curr-user := xdmp:get-current-user(),
      $user-roles := 
        if ($curr-user) then xdmp:user-roles($curr-user) else (),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE"),
      $verify := 
        if ($user-roles = fn:data($role/sec:role-ids/sec:role-id)) 
        then fn:true()
        else 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/role-set-description",
            "execute")
  return
    xdmp:node-replace(
      $role/sec:description, 
      <sec:description>{$description}</sec:description>)
}

(:
::
:: sec:role-get-description(
::      $role-name as xs:string)
:: as  xs:string 
::
:: Summary:
::
::      Returns the description for the specified role.  
::
:: Parameters:
::
::      $role-name 
::           The name of the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-get-description  
:: 
:: Usage Notes:
::
::       If a role with name equal to $role-name is not found, an error is 
::       returned.  
::
:)

define function 
role-get-description(
  $role-name as xs:string)
as xs:string
{
  let $col := security-collection(),
      $verify := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-get-description",
          "execute"),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE")
  return
    fn:data($role/sec:description)
}

(:
::
:: sec:get-role-ids(
::      $role-names as xs:string*)
:: as  element(sec:role-id)*
::
:: Summary:
::
::      Returns sequence of unique sec:role-id's that corresponds to the 
::      sequence of role names $role-names.  Duplicate names return a single 
::      id. If a role name in $role-names does not correspond to an existing 
::      role, an error is returned.  
::
:: Parameters:
::
::      $role-names 
::           A sequence of role names.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/get-role-ids  
:: 
:: Examples:
::
::       sec:get-role-ids(("writer", "editor"))  returns: 
::       <sec:role-id>2</sec:role-id>, <sec:role-id>5</sec:role-id>   
::
:)

define function get-role-ids(
  $role-names as xs:string*)
as element(sec:role-id)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/get-role-ids",
          "execute"),
      $col := security-collection()
  for $r-name in fn:distinct-values($role-names)
  let $role := fn:collection($col)/sec:role[sec:role-name=$r-name]
  return 
    if (fn:exists($role))
    then $role/sec:role-id
    else fn:error("SEC-ROLEDNE", ("sec:role-name",$r-name))
}
(:
::
:: sec:get-role-names(
::      $role-ids as xs:unsignedLong*)
:: as  element(sec:role-name)* 
::
:: Summary:
::
::      Returns sequence of unique sec:role-name's that corresponds to the 
::      sequence of role IDs $role-ids. Duplicate IDs return a single name.  
::
:: Parameters:
::
::      $role-ids 
::            A sequence of role IDs.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/get-role-names  
:: 
:: Usage Notes:
::
::       If a role ID in $role-ids does not correspond to an existing role, an 
::       error is returned.  
:: 
:: Examples:
::
::       sec:get-role-names((xs:unsignedLong(2234), 
::                           xs:unsignedLong(543356)))    
::       =>       
::       (<sec:role-name>editor</sec:role-name>,        
::       <sec:role-name>writer</sec:role-name>)     
::
:)

define function get-role-names(
  $role-ids as xs:unsignedLong*)
as element(sec:role-name)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/get-role-names",
          "execute"),
      $col := security-collection()
  for $r-id in fn:distinct-values($role-ids)
  let $role := fn:collection($col)/sec:role[sec:role-id=$r-id]
  return 
    if (fn:exists($role))
    then $role/sec:role-name
    else fn:error("SEC-ROLEDNE", ("sec:role-id",$r-id))
}



(:
::
:: sec:user-set-roles(
::      $user-name as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Assigns the user with name $user-name to have the roles identified by 
::      $role-names. Removes previously assigned roles. If a user with name 
::      equal to $user-name is not found, an error is returned. If a role name 
::      in $role-names does not correspond to an existing role, an error is 
::      returned. If $role-names is the empty sequence, all existing roles for 
::      the user are removed. If the current user is limited to granting only 
::      his/her roles, and $role-names is not a subset of the current user's 
::      roles or one of the removed roles is not a subset of the current user's 
::      roles, then an error is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
::  
::      $role-names 
::           A sequence of role names.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-set-roles and 
::       for role assignment ($role-names not empty sequence): 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
user-set-roles(
  $user-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-set-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $user :=  get-element($col, "sec:user", 
                              "sec:user-name",$user-name, 
                              "SEC-USERDNE"),
        $role-ids := fn:data(get-role-ids($role-names)),
        $user-roles := fn:data($user/sec:role-ids/sec:role-id),
        $remove := 
          for $r in $user-roles
          return
            if ($r = $role-ids) 
            then ()
            else $r,
        $removeNames := 
          for $rem in $remove 
          return 
            fn:data(/sec:role[sec:role-id = $rem]/sec:role-name),
        $grant := 
          fn:empty($removeNames) or xdmp:can-grant-roles($removeNames)
    return 
      (
        xdmp:node-replace(
          $user/sec:role-ids,
          <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>),
        if ($removeNames) then
          xdmp:audit("roleremove",$user-name,$removeNames,fn:true())
        else (),
        let $addNames := for $a in $role-ids 
                        return 
                          if ($a = $user-roles) then () 
                          else fn:data(/sec:role[sec:role-id = $a]/sec:role-name)
        return
          if ($addNames) then 
            xdmp:audit("roleadd",$user-name,$addNames,fn:true())
          else (),
        xdmp:audit("userconfig",$user-name,"set-roles",fn:true())
      )
  } catch ($e) {
    xdmp:audit("rolefail",$user-name,$role-names,fn:false()),
    xdmp:audit("userconfig",$user-name,"set-roles",fn:false()),
    xdmp:rethrow()
  }
}


(:
::
:: sec:user-add-roles(
::      $user-name as xs:string,  
::      $role-names as xs:string*)
:: as  empty()
::
:: Summary:
::
::      Adds the roles ($role-names) to the list of roles granted to the user 
::      ($user-name). If a user with name equal to $user-name is not found, an 
::      error is returned. If one of the $role-names does not correspond to an 
::      existing role, an error is returned. If the current user is limited to 
::      granting only his/her roles, and $role is not a subset of the current 
::      user's roles, then an error is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
::  
::      $role-names 
::           A sequence of role names.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-add-roles and 
::       for role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
user-add-roles(
  $user-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-add-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $user :=  get-element($col, "sec:user", 
                              "sec:user-name",$user-name, 
                              "SEC-USERDNE"),
        $roles := fn:distinct-values(($role-names,user-get-roles($user-name)))
    return
      (
        xdmp:node-replace(
          $user/sec:role-ids,
          <sec:role-ids>{get-role-ids($roles)}</sec:role-ids>),
        xdmp:audit("roleadd",$user-name,$role-names,fn:true()),
        xdmp:audit("userconfig",$user-name,"add-roles",fn:true())
      )
  } catch ($e) {
    xdmp:audit("rolefail",$user-name,$role-names,fn:false()),
    xdmp:audit("roleadd",$user-name,$role-names,fn:false()),
    xdmp:audit("userconfig",$user-name,"add-roles",fn:false()),
    xdmp:rethrow()
  }
}


(:
::
:: sec:user-remove-roles(
::      $user-name as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Removes the roles ($role-names) from the list of roles granted to the 
::      user ($user-name). If a user with name equal to $user-name is not 
::      found, an error is returned. If one of $role-names does not correspond 
::      to an existing role, an error is returned. If the current user is 
::      limited to granting only his/her roles, and one of $role-names is not a 
::      subset of the current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
::  
::      $role-names 
::           A sequence of role names.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-role-from-user 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
user-remove-roles(
  $user-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-remove-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $user :=  get-element($col, "sec:user", 
                              "sec:user-name",$user-name, 
                              "SEC-USERDNE"),
        $current := user-get-roles($user-name),
        $new := 
          for $r in $current
          return 
            if ($r = $role-names) 
            then () 
            else $r
    return
      (
        xdmp:audit("roleremove",$user-name,$role-names,fn:true()),
        xdmp:audit("userconfig",$user-name,"delete-roles",fn:true()),      
        xdmp:node-replace(
          $user/sec:role-ids,
          <sec:role-ids>{get-role-ids($new)}</sec:role-ids>)
      )
  } catch ($e) {
    xdmp:audit("rolefail",$user-name,$role-names,fn:false()),
    xdmp:audit("roleremove",$user-name,$role-names,fn:false()),
    xdmp:audit("userconfig",$user-name,"delete-roles",fn:false()),
    xdmp:rethrow()      
  }
}

(:
::
:: sec:user-get-roles(
::      $user-name as xs:string)
:: as  xs:string*
::
:: Summary:
::
::      Returns a sequence of role names for the roles directly assigned to 
::      the user ($user-name). Does not flatten the roles to include "inherited 
::      roles." If a user with name equal to $user-name is not found, an error 
::      is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-get-roles  
::
:)

define function 
user-get-roles(
  $user-name as xs:string)
as xs:string*
{
  let $col := security-collection(),
      $curr-user := xdmp:get-current-user(),
      $verify := 
        if ($curr-user = $user-name) 
        then fn:true()
        else 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-get-roles",
            "execute"),
      $user := get-element($col, "sec:user", 
                           "sec:user-name",$user-name, 
                           "SEC-USERDNE")
  return
    for $r in $user/sec:role-ids/sec:role-id
    return fn:data(fn:collection($col)/sec:role[sec:role-id=$r]/sec:role-name)
}

(:
::
:: sec:user-get-description(
::      $user-name as xs:string)
:: as xs:string 
::
:: Summary:
::
::      Returns the user's description. If a user with name equal to 
::      $user-name is not found, an error is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-get-description 
::       or the current user is the same as the $user-name.  
::
:)

define function 
user-get-description(
  $user-name as xs:string)
as xs:string
{
  let $col := security-collection(),
      $curr-user := xdmp:get-current-user(),
      $verify := 
        if ($curr-user = $user-name) 
        then fn:true()
        else 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-get-description",
            "execute"),
      $user := get-element($col, "sec:user", 
                           "sec:user-name",$user-name, 
                           "SEC-USERDNE")
  return
    fn:data($user/sec:description)
}

(:
::
:: sec:remove-user(
::      $user-name as xs:string)
:: as  empty()
::
:: Summary:
::
::      Removes the user with name $user-name. If a user with name equal to 
::      $user-name is not found, an error is returned.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-user  
::
:)

define function 
remove-user(
  $user-name as xs:string)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/remove-user",
            "execute"),
        $col := security-collection(),
        $admin-id := get-element($col, "sec:role",
                                "sec:role-name", "admin", 
                                "SEC-ROLEDNE")/sec:role-id,
        $is-admin := (xdmp:user-roles($user-name) = $admin-id),
        $user := get-element($col, "sec:user", 
                            "sec:user-name", $user-name, 
                            "SEC-USERDNE")
    return (
      if ($is-admin) then 
        let $admin-users := 
          fn:collection($col)/sec:user[sec:role-ids/sec:role-id = $admin-id]
        return
          if (fn:count($admin-users) eq 1)
            then fn:error("SEC-LASTADMIN",$user-name)
          else xdmp:document-delete(xdmp:node-uri($user))
      else xdmp:document-delete(xdmp:node-uri($user))
      ,
      xdmp:audit("userconfig",$user-name,"delete-user",fn:true())
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"delete-user",fn:false()),      
    xdmp:rethrow()
  }
}

(:
::
:: sec:validate-permissions(
::      $permissions as element(sec:permission)*)
:: as node()*
::
:: Summary:
::
::      Throws an error if any of the permissions are not valid.
::
:: Parameters:
::
::      $permissions
::           The permissions.
:: 
::
:)

define function
validate-permissions(
  $permissions as element(sec:permission)*)
as node()*
{
  for $perm in $permissions
  return (
    if (fn:count($perm/sec:capability) = 1)
    then ()
    else fn:error("SEC-NOPERMCAP"),
    if (fn:count($perm/sec:role-id) = 1)
    then ()
    else fn:error("SEC-NOPERMROLEID")
  )
}

(:
::
:: sec:create-role(
::      $role-name as xs:string,
::      $description as xs:string?,  
::      $role-names as xs:string*,  
::      $permissions as element(sec:permission)*,  
::      $collections as xs:string*)
:: as xs:unsignedLong 
::
:: Summary:
::
::      Creates a new role in the system database for the context database. If 
::      $role-name is not unique, an error is returned. If one of the 
::      $role-names does not identify a role, an error is returned. If the 
::      current user is limited to granting only his/her roles, and $role-names 
::      is not a subset of the current user's roles, then an error is returned. 
::      Returns the role-id.  
::
:: Parameters:
::
::      $role-name 
::            The name of the role to be created.  
::  
::      $description 
::            The description of the role to be created.  
::  
::      $role-names 
::            A sequence of role names to which the role is assigned.  
::  
::      $permissions 
::            The default permissions for the role.  
::  
::      $collections 
::            The default collections for the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/create-role and for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
create-role(
  $role-name as xs:string,
  $description as xs:string?, 
  $role-names as xs:string*,
  $permissions as element(sec:permission)*,
  $collections as xs:string*)
as xs:unsignedLong
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-role",
          "execute"),
      $bad := 
        if (xdmp:castable-as(security-namespace(), "role-name", $role-name)) 
        then ()
        else if ($role-name) 
        then fn:error("SEC-BADROLENAME")
        else fn:error("SEC-NOEMPTYROLENAME"),
      $badPerms := validate-permissions($permissions),
      $col := security-collection(),
      $curr-user :=  xdmp:get-current-user(),
      $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
      $duplicate := fn:collection($col)/sec:role/sec:role-name[.=$role-name],
      $err := 
        if (fn:exists($duplicate)) 
        then fn:error("SEC-ROLEEXISTS") 
        else (),
      $default-permissions := 
        if ($role-name = "admin" or $role-name = "security") 
        then ()
        else role-doc-permissions(),
      $default-collections := role-doc-collections(),
      $uri :="http://marklogic.com/xdmp/roles/",
      $role-id := get-unique-elem-id("role-name()",$role-name),
      $default-cols := 
        for $d in $collections
        return <sec:uri>{$d}</sec:uri>

  return
    let $insert :=
      xdmp:document-insert(fn:concat($uri, xs:string($role-id)),
      <sec:role>
        <sec:role-id>{$role-id}</sec:role-id>
        <sec:role-name>{$role-name}</sec:role-name>
        <sec:description>{$description}</sec:description>
        <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>
        <sec:permissions>{$permissions}</sec:permissions>
        <sec:collections>{$default-cols}</sec:collections>
      </sec:role>,
      $default-permissions,
      $default-collections)
    return $role-id
}


(:
::
:: sec:role-set-name(
::      $role-name as xs:string,  
::      $new-role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Changes the sec:role-name of a role from $role-name to $new-role-name. 
::      If $new-role-name is not unique, an error is returned.  
::
:: Parameters:
::
::      $role-name 
::            The name of the role to change.  
::  
::      $new-role-name 
::            The new name for the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-set-name  
::
:)

define function 
role-set-name(
  $role-name as xs:string,
  $new-role-name as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-set-name",
          "execute"),
      $bad := 
        if (xdmp:castable-as(security-namespace(), "role-name", $new-role-name)) 
        then ()
        else if ($new-role-name) 
        then fn:error("SEC-BADROLENAME")
        else fn:error("SEC-NOEMPTYROLENAME"),
      $bad := 
        if ($role-name = "admin")
        then fn:error("SEC-ADMINROLE")
        else (),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name", $role-name, 
                           "SEC-ROLEDNE"),
      $duplicate := fn:collection($col)/sec:role/sec:role-name[.=$new-role-name]
  return
    if (fn:exists($duplicate)) 
    then fn:error("SEC-RNEXISTS")
    else
      xdmp:node-replace(
        $role/sec:role-name, 
        <sec:role-name>{$new-role-name}</sec:role-name>)
}


(:
::
:: sec:role-set-roles(
::      $role-name as xs:string,  
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Assigns roles (named $role-names) to be the set of included roles for 
::      the role ($role-name). Removes previously assigned roles. If a role 
::      with name equal to $role-name is not found, an error is returned. If a 
::      role name in $role-names does not correspond to an existing role, an 
::      error is returned. If $role-names is the empty sequence, all included 
::      roles for the role are removed. If the current user is limited to 
::      granting only his/her roles, and $role-names is not a subset of the 
::      current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
::  
::      $role-name 
::            The names of roles to assign to $role-name.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-set-roles  and 
::       for role assignment ($role-names not empty sequence): 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
role-set-roles(
  $role-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/role-set-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE"),
        $role-ids := fn:data(get-role-ids($role-names)),
        $role-roles := fn:data($role/sec:role-ids/sec:role-id),
        $remove := 
          for $r in $role-roles
          return
            if ($r = $role-ids) 
            then ()
            else 
            $r,
        $removeNames := 
          for $rem in $remove 
          return 
            fn:data(/sec:role[sec:role-id = $rem]/sec:role-name),
        $grant := 
          fn:empty($removeNames) or xdmp:can-grant-roles($removeNames)
    return (
      xdmp:node-replace(
        $role/sec:role-ids,
        <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>),
      if ($removeNames) then
        for $u in role-get-users($role/sec:role-id,(),())
        return
          xdmp:audit("roleremove",$u,$removeNames,fn:true())
      else (),
      let $addNames := for $a in $role-ids 
                       return 
                         if ($a = $role-roles) then () 
                         else fn:data(/sec:role[sec:role-id = $a]/sec:role-name)
       return
         if ($addNames) then 
           for $u in role-get-users($role/sec:role-id,(),())
           return
             xdmp:audit("roleadd",$u,$addNames,fn:true())
         else ()
    )
  } catch ($e) {
    let $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE")
    for $u in role-get-users($role/sec:role-id,(),())
    return
      xdmp:audit("rolefail",$u,$role-names,fn:false()),
    xdmp:rethrow()
  }
}


(:
::
:: sec:role-add-roles(
::      $role-name as xs:string,  
::      $new-roles as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Adds the roles ($new-roles) to the set of roles included by the role 
::      ($role-name). If a role with name equal to $role-name is not found, an 
::      error is returned. If one of $new-roles does not correspond to an 
::      existing role, an error is returned. If the current user is limited to 
::      granting only his/her roles, and $new-role is not a subset of the 
::      current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
::  
::      $new-roles 
::            The roles to add to the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-add-roles  and 
::       for role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
role-add-roles(
  $role-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/role-add-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE"),
        $roles := fn:distinct-values(($role-names,role-get-roles($role-name)))
    return (
      xdmp:node-replace(
        $role/sec:role-ids,
        <sec:role-ids>{get-role-ids($roles)}</sec:role-ids>),
      for $u in role-get-users($role/sec:role-id,(),())
      return
        xdmp:audit("roleadd",$u,$role-names,fn:true())
    )
  } catch ($e) {
    let $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE")
    for $u in role-get-users($role/sec:role-id,(),())
    return (
      xdmp:audit("rolefail",$u,$role-names,fn:false()),
      xdmp:audit("roleadd",$u,$role-names,fn:false())
    ),
    xdmp:rethrow()
  }
}



(:
::
:: sec:role-remove-roles(
::      $role-name as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Removes the roles ($role-names) from the set of roles included by the 
::      role ($role-name). If a role with name equal to $role-name is not 
::      found, an error is returned. If one of $role-names does not correspond 
::      to an existing role, an error is returned. If the current user is 
::      limited to granting only his/her roles, and $old-role is not a subset 
::      of the current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
::  
::      $role-names 
::            The name of the roles to remove from the role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-remove-roles and 
::       for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
role-remove-roles(
  $role-name as xs:string,
  $role-names as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/role-remove-roles",
            "execute"),
        $curr-user := xdmp:get-current-user(),
        $grant := xdmp:can-grant-roles($role-names),
        $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE"),
        $current := role-get-roles($role-name),
        $new := 
          for $r in $current
          return 
            if ($r = $role-names) 
            then () 
            else $r
    return (
      xdmp:node-replace(
        $role/sec:role-ids,
        <sec:role-ids>{get-role-ids($new)}</sec:role-ids>),
     for $u in role-get-users($role/sec:role-id,(),())
      return
        xdmp:audit("roleremove",$u,$role-names,fn:true())
    )
  } catch ($e) {
    let $col := security-collection(),
        $role := get-element($col, "sec:role", 
                            "sec:role-name",$role-name, 
                            "SEC-ROLEDNE")
    for $u in role-get-users($role/sec:role-id,(),())
    return (
      xdmp:audit("rolefail",$u,$role-names,fn:false()),
      xdmp:audit("roleremove",$u,$role-names,fn:false())
    ),
    xdmp:rethrow()
  }
}


(:
::
:: sec:remove-role(
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes the role ($role-name). If a role with name equal to $role-name 
::      is not found, an error is returned. This function also removes all 
::      references to the role (privileges, amps, permissions and users).  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-role  
::
:)

define function 
remove-role(
  $role-name as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-role",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name", $role-name, 
                           "SEC-ROLEDNE"),
      $r := $role/sec:role-name
  return
    (remove-role-from-users($r),
     remove-role-from-roles($r),
     remove-role-from-privileges($r),
     remove-role-from-amps($r),
     xdmp:document-delete(xdmp:node-uri($role)))
}

(:
::
:: sec:remove-role-from-users(
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes references to the role ($role-name) from all users. If a role 
::      with name equal to $role-name is not found, an error is returned. If 
::      the current user is limited to granting only his/her roles, and 
::      $role-name is not a subset of the current user's roles, then an error 
::      is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/remove-role-from-users 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
remove-role-from-users(
  $role-name as xs:string)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/remove-role-from-users",
            "execute"),
        $col := security-collection(),
        $curr-user :=  xdmp:get-current-user(),
        $grant := xdmp:can-grant-roles($role-name),
        $rid := get-element($col, "sec:role", 
                            "sec:role-name", $role-name, 
                            "SEC-ROLEDNE")/sec:role-id
    return (
      for $r in fn:collection($col)/sec:user/sec:role-ids/sec:role-id[. = $rid]
      return 
        xdmp:node-delete($r),
      for $u in role-get-users($rid,(),())
      return 
        xdmp:audit("roleremove",$u,$role-name,fn:true())
    )
  } catch ($e) {
    let $col := security-collection(),
        $rid := get-element($col, "sec:role", 
                            "sec:role-name", $role-name, 
                            "SEC-ROLEDNE")/sec:role-id
    for $u in role-get-users($rid,(),())
    return (
      xdmp:audit("rolefail",$u,$role-name,fn:false()),
      xdmp:audit("roleremove",$u,$role-name,fn:false())
    ),
    xdmp:rethrow()
  }
}

(:
::
:: sec:remove-role-from-role(
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes references to the role ($role-name) from other roles. If a 
::      role with name equal to $role-name is not found, an error is returned. 
::      If the current user is limited to granting only his/her roles, and 
::      $role-name is not a subset of the current user's roles, then an error 
::      is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/remove-role-from-users 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
remove-role-from-roles(
  $role-name as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-role-from-roles",
          "execute"),
      $col := security-collection(),
      $curr-user :=  xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-name),
      $rid := get-element($col, "sec:role", 
                          "sec:role-name", $role-name, 
                          "SEC-ROLEDNE")/sec:role-id
  for $r in fn:collection($col)/sec:role/sec:role-ids/sec:role-id[. = $rid]
  return
    xdmp:node-delete($r)
}


(:
::
:: sec:remove-role-from-privileges(
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes references to the role ($role-name) from all privileges. If a 
::      role with name equal to $role-name is not found, an error is returned. 
::      If the current user is limited to granting only his/her roles, and 
::      $role-name is not a subset of the current user's roles, then an error 
::      is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/remove-role-from-priveleges 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
remove-role-from-privileges(
  $role-name as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-role-from-privileges",
          "execute"),
      $col := security-collection(),
      $curr-user :=  xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-name),
      $rid := get-element($col, "sec:role", 
                          "sec:role-name", $role-name, 
                          "SEC-ROLEDNE")/sec:role-id
  for $r in fn:collection($col)/sec:privilege/sec:role-ids/sec:role-id[. = $rid]
  return
    xdmp:node-delete($r)
}


(:
::
:: sec:remove-role-from-amps(
::      $role-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes references to the role ($role-name) from all amps. If a role 
::      with name equal to $role-name is not found, an error is returned. If 
::      the current user is limited to granting only his/her roles, and 
::      $role-name is not a subset of the current user's roles, then an error 
::      is returned.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-role-from-amps 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
remove-role-from-amps(
  $role-name as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-role-from-amps",
          "execute"),
      $col := security-collection(),
      $curr-user :=  xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-name),
      $rid := get-element($col, "sec:role", 
                          "sec:role-name", $role-name, 
                          "SEC-ROLEDNE")/sec:role-id
  for $r in fn:collection($col)/sec:amp/sec:role-ids/sec:role-id[. = $rid]
  return
    xdmp:node-delete($r)
}


(:
::
:: sec:create-privilege(
::      $privilege-name as xs:string,  
::      $action as xs:string,  
::      $kind as xs:string,  
::      $role-names as xs:string*)
:: as xs:unsignedLong 
::
:: Summary:
::
::      Creates a new privilege and returns the new privilege-id. If $action 
::      is not unique, an error is returned. If $kind is not one of ("execute", 
::      "uri") then en error is returned. If one of the $role-names names a 
::      role that does not exist, an error is returned. If the current user is 
::      limited to granting only his/her roles, and $role-names is not a subset 
::      of the current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $privilege-name 
::            The name of the privelege to create (unique within security 
::            database).  
::  
::      $action 
::           Action protected by this privilege. For an Execute Privilege, 
::            this is usually a URI describing an activity. For a URI 
::            Privilege, this is a base URI used to filter database 
::            activities with certain document URIs.  
::  
::      $kind 
::           Either "execute" or "uri".  
::  
::      $role-names 
::            The names of the roles which can perform this action.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/create-privilege  and 
::       for role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
create-privilege(
  $privilege-name as xs:string,
  $action as xs:string,
  $kind as xs:string,
  $role-names as xs:string*)
as xs:unsignedLong
{
  let $lastchar := fn:substring($action,fn:string-length($action)),
      $action :=
       if(($kind eq "uri") and fn:not($lastchar eq "/")) then
         fn:concat($action,"/")
       else
         $action,
      $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-privilege",
          "execute"),
      $bad := 
        if (xdmp:castable-as(security-namespace(), "privilege-name", $privilege-name)) 
        then ()
        else if ($privilege-name) 
        then fn:error("SEC-BADPRIVNAME")
        else fn:error("SEC-NOEMPTYPRIVNAME"),
      $bad := 
        if (xdmp:castable-as(security-namespace(), "action", $action)) 
        then ()
        else if ($action) 
        then fn:error("SEC-BADPRIVACTION")
        else fn:error("SEC-NOEMPTYPRIVACTION"),
      $check-kind := 
        if (fn:not($kind = ("execute", "uri"))) 
        then fn:error("SEC-BADKIND")
	else (),
      $curr-user := xdmp:get-current-user(),
      $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $action := element sec:action { $action },
      $duplicate := fn:collection($col)/sec:privilege
                      [sec:action = $action][sec:kind = $kind],
      $dup2 := fn:collection($col)/sec:privilege
                 [sec:privilege-name = $privilege-name][sec:kind = $kind],
      $err := 
        if (fn:exists($duplicate)) 
        then fn:error("SEC-PRIVEXISTS") 
        else (),
      $err2 := 
        if (fn:exists($dup2)) 
        then fn:error("SEC-PRIVNAMEEXISTS") 
        else (),
      $default-permissions := priv-doc-permissions(),
      $default-collections := priv-doc-collections(),
      $uri := "http://marklogic.com/xdmp/privileges/",
      $priv-id := 
        xdmp:add64(
          xdmp:mul64(
            xdmp:add64(
              xdmp:mul64(xdmp:hash64($action),5),
              xdmp:hash64($kind)),
            5),
          xdmp:hash64("privilege()"))
  return
    let $insert := 
     xdmp:document-insert(
       fn:concat($uri, xs:string($priv-id)),
          <sec:privilege>
            <sec:privilege-id>{$priv-id}</sec:privilege-id>
            <sec:privilege-name>{$privilege-name}</sec:privilege-name>
            {$action}
            <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>
            <sec:kind>{$kind}</sec:kind>
          </sec:privilege>,
          $default-permissions,
          $default-collections)
    return $priv-id
}


(:
::
:: sec:privilege-set-name(
::      $action as xs:string,  
::      $kind as xs:string,  
::      $new-privilege-name as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Changes the sec:privilege-name of a sec:privilege to 
::      $new-privilege-name. If a privilege with the given $action and $kind is 
::      not found, an error is returned. If $new-privilege-name is not unique, 
::      an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
::  
::      $new-privilege-name 
::           The new name for the privilege.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/privilege-set-name  
::
:)

define function
privilege-set-name(
  $action as xs:string,
  $kind as xs:string,
  $new-privilege-name as xs:string)
as empty()
{
  let $verify := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-set-name",
          "execute"),
      $bad := 
        if (xdmp:castable-as(security-namespace(),"privilege-name",$new-privilege-name))
        then ()
        else if ($new-privilege-name) 
        then fn:error("SEC-BADPRIVNAME")
        else fn:error("SEC-NOEMPTYPRIVNAME"),
      $col := security-collection(),
      $priv := get-privilege($action,$kind),
      $empty := 
        if ($new-privilege-name = "") 
        then fn:error("SEC-NOEMPTYPRIVNAME") 
        else (),
      $duplicate := fn:collection($col)/sec:privilege
                      [sec:privilege-name = $new-privilege-name and 
                       sec:kind = $priv/sec:kind]
  return
    if (fn:exists($duplicate))
    then fn:error("SEC-PRIVNAMEEXISTS")
    else
      xdmp:node-replace(
        $priv/sec:privilege-name, 
        <sec:privilege-name>{$new-privilege-name}</sec:privilege-name>)
}

(:
::
:: sec:remove-privilege(
::      $action as xs:string,  
::      $kind as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes the privilege identified by ($action,$kind). If a privilege 
::      identified by ($action,$kind) is not found, an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-privilege  
::
:)

define function 
remove-privilege(
  $action as xs:string,
  $kind as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-privilege",
          "execute"),
      $col := security-collection(),
      $priv := get-privilege($action, $kind)
  return
    if (fn:data(xdmp:read-cluster-config-file("groups.xml")/
          gr:groups/gr:group/gr:privilege) = fn:data($priv/sec:privilege-id))
    then 
      fn:error("SEC-PRIVINUSE")
    else
      xdmp:document-delete(xdmp:node-uri($priv))
}


(:
::
:: sec:privilege-get-roles(
::      $action as xs:string,  
::      $kind as xs:string)
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of role names for the roles assigned to the 
::      privilege ($action,$kind).  If a privilege with action equal to $action 
::      is not found, an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/privilege-get-roles  
::
:)

define function 
privilege-get-roles(
  $action as xs:string,
  $kind as xs:string)
as xs:string*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-get-roles",
          "execute"),
      $col := security-collection(),
      $priv := get-privilege($action, $kind)
  return
    for $r in $priv/sec:role-ids/sec:role-id
    return fn:data(fn:collection($col)/sec:role[sec:role-id=$r]/sec:role-name)
}


(:
::
:: sec:privilege-set-roles(
::      $action as xs:string,  
::      $kind as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Assigns the privilege ($action,$kind) to have the roles identified by 
::      $role-names. Removes the prviously assigned roles. If a privilege 
::      identified by ($action,$kind) is not found, an error is returned. If a 
::      role name in $role-names does not correspond to an existing role, an 
::      error is returned. If $role-names is the empty sequence, all existing 
::      roles for the privilege are removed. If the current user is limited to 
::      granting only his/her roles, and $role-names is not a subset of the 
::      current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
::  
::      $role-names 
::            New roles that can perform this action. All previously 
::            assigned roles will be removed. If $role-names is the empty 
::            sequence, the privilege will have no roles assigned.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/privilege-set-roles  
::       and for role assignment ($role-names not empty sequence): 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
privilege-set-roles(
  $action as xs:string,
  $kind as xs:string,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-set-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $priv := get-privilege($action, $kind),
      $role-ids := fn:data(get-role-ids($role-names)),
      $priv-roles := fn:data($priv/sec:role-ids/sec:role-id),
      $remove := 
        for $r in $priv-roles
        return
          if ($r = $role-ids) 
          then ()
          else $r,
      $removeNames := 
        for $rem in $remove 
        return 
          fn:data(/sec:role[sec:role-id = $rem]/sec:role-name),
      $grant := 
        fn:empty($removeNames) or xdmp:can-grant-roles($removeNames)
  return
    xdmp:node-replace(
      $priv/sec:role-ids,
      <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>)
}



(:
::
:: sec:privilege-add-roles(
::      $action as xs:string,  
::      $kind as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Adds the roles ($role-names) to the list of roles assigned to the 
::      privilege ($action,$kind). If a privilege identified by ($action,$kind) 
::      is not found, an error is returned. If one of $role-names does not 
::      correspond to an existing role, an error is returned. If the current 
::      user is limited to granting only his/her roles, and $role is not a 
::      subset of the current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
::  
::      $role-names 
::            Additional roles for the privilege. If $role-names is the 
::            empty sequence, the function has no effect.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/privilege-add-roles  
::       and for role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
privilege-add-roles(
  $action as xs:string,
  $kind as xs:string,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-add-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $priv := get-privilege($action, $kind),
      $roles := fn:distinct-values(($role-names,
                                    privilege-get-roles($action,$kind)))
  return
    xdmp:node-replace(
      $priv/sec:role-ids,
      <sec:role-ids>{get-role-ids($roles)}</sec:role-ids>)

}

(: FOR USE BY ADMIN INTERFACE ONLY :)
define function 
privilege-add-roles-by-id(
  $action as xs:string,
  $kind as xs:string,
  $role-ids as xs:unsignedLong*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-add-roles",
          "execute"),
      $assert2 := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/grant-all-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $col := security-collection(),
      $priv := get-privilege($action, $kind),
      $roles := fn:distinct-values(
                  ($role-ids, fn:data($priv/sec:role-ids/sec:role-id))),
      $rids := for $r in $roles return <sec:role-id>{$r}</sec:role-id>
  return
    xdmp:node-replace(
      $priv/sec:role-ids,
      <sec:role-ids>{$rids}</sec:role-ids>)

}



(:
::
:: sec:privilege-remove-roles(
::      $action as xs:string,  
::      $kind as xs:string,  
::      $role-names as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Removes roles ($role-names) from the roles assigned to the privilege 
::      ($action,$kind). If a privilege identified by ($action,$kind) is not 
::      found, an error is returned. If one of $role-names does not correspond 
::      to an existing role, an error is returned. If the current user is 
::      limited to granting only his/her roles, and $role is not a subset of 
::      the current user's roles, then an error is returned.  
::
:: Parameters:
::
::      $action 
::           The action for the privilege.  
::  
::      $kind 
::           Either "execute" or "uri".  
::  
::      $role-names 
::            Additional roles for the privilege. If $role-names is the 
::            empty sequence, the function has no effect.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/privilege-remove-roles 
::       and for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
privilege-remove-roles(
  $action as xs:string,
  $kind as xs:string,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/privilege-remove-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $priv := get-privilege($action, $kind),
      $current := privilege-get-roles($action,$kind),
      $new := 
        for $r in $current
        return 
          if ($r = $role-names) 
          then () 
          else $r
  return
    xdmp:node-replace(
      $priv/sec:role-ids,
      <sec:role-ids>{get-role-ids($new)}</sec:role-ids>)
}


(:
::
:: sec:create-amp(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,  
::      $database as xs:unsignedLong,
::      $role-names as xs:string*)
:: as xs:unsignedLong 
::
:: Summary:
::
::      Creates a new amp in the system database for the context database. If 
::      the tuple ($namespace, $local-name, $document-uri, $database) is not unique, 
::      an error is returned. If one of the $role-names does not identify a role, 
::      an error is returned. If the current user is limited to granting only 
::      his/her roles, and $role-names is not a subset of the current user's 
::      roles, then an error is returned. Returns the amp-id.  
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the module in which the function is located.  
::  
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
::      $role-names 
::            Roles that should be temporarily assumed while the amp is in 
::            effect.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/create-amp and for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
create-amp(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong,
  $role-names as xs:string*)
as xs:unsignedLong
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-amp",
          "execute"),
      $bad := 
        if ($namespace) 
        then ()
        else fn:error("SEC-NOEMPTYAMPNS"),
      $bad := 
         if ($local-name) 
         then ()
         else fn:error("SEC-NOEMPTYAMPLN"),
      $bad := 
         if ($document-uri) 
         then ()
         else fn:error("SEC-NOEMPTYAMPDU"),
      $curr-user := xdmp:get-current-user(),
      $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $namespace := element sec:namespace { $namespace },
      $local-name := element sec:local-name { $local-name },
      $document-uri := element sec:document-uri { $document-uri },
      $dup := fn:collection($col)/sec:amp
                [ sec:namespace = $namespace ]
                [ sec:local-name = $local-name ]
                [ sec:document-uri = $document-uri ]
                [ sec:database = $database], 
      $err := 
        if (fn:exists($dup)) 
        then fn:error("SEC-AMPEXISTS") 
        else (),
      $role-ids := get-role-ids($role-names),
      $default-permissions := amp-doc-permissions(),
      $default-collections := amp-doc-collections(),
      $uri := "http://marklogic.com/xdmp/amps/",
      $qnameKey := 
        xdmp:add64(
          xdmp:mul64(
            xdmp:add64(
              xdmp:mul64(xdmp:hash64($namespace),5),
              xdmp:hash64($local-name)),
            5),
          xdmp:hash64("qname()")),
      $amp-id := 
        xdmp:add64(
          xdmp:mul64(
            xdmp:add64(
              xdmp:mul64(
                xdmp:add64(
                  xdmp:mul64($qnameKey,5),
                  xdmp:hash64($document-uri)),
                5),
              $database),
            5),
          xdmp:hash64("amp()"))
  return
    let $insert :=
      xdmp:document-insert(
       fn:concat($uri, xs:string($amp-id)),
         <sec:amp>
           <sec:amp-id>{$amp-id}</sec:amp-id>
           {$namespace}
           {$local-name}
           {$document-uri}
           <sec:database>{$database}</sec:database>
           <sec:role-ids>{$role-ids}</sec:role-ids>
         </sec:amp>,
         $default-permissions,
         $default-collections)
    return $amp-id
}


(:
::
:: sec:amp-set-roles(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,  
::      $database as xs:unsignedLong,
::      $role-names as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Assigns the amp identified by $namespace, $local-name, $database and 
::      $document-uri to have the roles identified by $roles-names. Removes 
::      previously assigned roles. If an amp with the given identifiers does 
::      not exist, an error is returned. If a role name in $role-names does not 
::      correspond to an existing role, an error is returned. If $role-names is 
::      the empty sequence, all roles assigned to the amp are removed. If the 
::      current user is limited to granting only his/her roles, and $role-names 
::      is not a subset of the current user's roles, then an error is returned. 
::       
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the document in which the function is located.  
::  
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
::      $role-names 
::            Roles that should be temporarily assumed while the amp is in 
::            effect.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/amp-set-roles and for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
::
:)

define function 
amp-set-roles(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/amp-set-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := fn:empty($role-names) or xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $amp := get-amp($namespace, $local-name, $document-uri, $database),
      $role-ids := fn:data(get-role-ids($role-names)),
      $amp-roles := fn:data($amp/sec:role-ids/sec:role-id),
      $remove := 
        for $r in $amp-roles
        return
          if ($r = $role-ids) 
          then ()
          else $r,
      $removeNames := 
        for $rem in $remove 
        return 
          fn:data(/sec:role[sec:role-id = $rem]/sec:role-name),
      $grant := 
        fn:empty($removeNames) or xdmp:can-grant-roles($removeNames)
  return
    xdmp:node-replace(
      $amp/sec:role-ids,
      <sec:role-ids>{get-role-ids($role-names)}</sec:role-ids>)
}


(:
::
:: sec:amp-add-roles(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,  
::      $database as xs:unsignedLong,
::      $role-names as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Adds the roles ($role-names) to the list of roles granted to the amp 
::      ($namespace, $local-name, $document-uri, $database).  
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the document in which the function is located.  
::  
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
:: 
::      $role-names 
::            Roles that should be temporarily assumed while the amp is in 
::            effect.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/amp-add-roles and for 
::       role assignment: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
:: 
:: Usage Notes:
::
::       If an amp with the given identifiers ($namespace, $local-name, 
::       $document-uri, $database) is not found, an error is returned. If one of 
::       $role-names does not correspond to an existing role, an error is 
::       returned. If the current user is limited to granting only his/her 
::       roles, and $role is not a subset of the current user's roles, then an 
::       error is returned.  
::
:)

define function 
amp-add-roles(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/amp-add-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $amp := get-amp($namespace,$local-name,$document-uri,$database),
      $roles := fn:distinct-values(($role-names,
                                    amp-get-roles($namespace,
                                                  $local-name,
                                                  $document-uri,
                                                  $database)))
  return
    xdmp:node-replace(
      $amp/sec:role-ids,
      <sec:role-ids>{get-role-ids($roles)}</sec:role-ids>)
}


(:
::
:: sec:amp-get-roles(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,
::      $database as xs:unsignedLong)
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of role names for the roles directly assigned to 
::      the amp ($namespace, $local-name, $document-uri, $database).  
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the document in which the function is located.  
:: 
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/amp-get-roles  
:: 
:: Usage Notes:
::
::       If an amp is not found with the given identifiers, an error is 
::       returned.  
::
:)

define function 
amp-get-roles(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong)
as xs:string*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/amp-get-roles",
          "execute"),
      $col := security-collection(),
      $amp := get-amp($namespace, $local-name, $document-uri, $database)
  return
    for $r in $amp/sec:role-ids/sec:role-id
    return fn:data(fn:collection($col)/sec:role[sec:role-id=$r]/sec:role-name)
}


(:
::
:: sec:role-get-roles(
::      $role-name as xs:string)
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of role names for the roles directly assigned to 
::      the given role ($role-name).  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
::
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-get-roles  
:: 
:: Usage Notes:
::
::       If a role with name equal to $role-name is not found, an error is 
::       returned.
::
::       To find all of the roles this role inherits (that is, the
::       roles assigned directly to this role, the roles assigned to those 
::       roles, and so on), use the xdmp:role-roles built-in
::       function.  
::
:)

define function 
role-get-roles(
  $role-name as xs:string)
as xs:string*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-get-roles",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name", $role-name, 
                           "SEC-ROLEDNE")
  return
    for $r in $role/sec:role-ids/sec:role-id
    return fn:data(fn:collection($col)/sec:role[sec:role-id=$r]/sec:role-name)

}


(:
::
:: sec:amp-remove-roles(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,  
::      $database as xs:unsignedLong,
::      $role-names as xs:string)
:: as  empty() 
::
:: Summary:
::
::      Removes a role ($role-name) from the set of roles included by the amp 
::      ($namespace, $local-name, $document-uri, $database).  
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the document in which the function is located.  
::  
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
::      $role-names 
::            Roles that should be temporarily assumed while the amp is in 
::            effect.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/amp-remove-roles and 
::       for role removal: 
::       http://marklogic.com/xdmp/privileges/grant-all-roles or 
::       http://marklogic.com/xdmp/privileges/grant-my-roles  
:: 
:: Usage Notes:
::
::       If one of $role-names does not correspond to an existing role, an 
::       error is returned. If an amp idnetified by ($namespace, $local-name, 
::       $document-uri, $database) is not found then an error is returned. If the current 
::       user is limited to granting only his/her roles, and $role-name is not 
::       a subset of the current user's roles, then an error is returned.  
::
:)

define function 
amp-remove-roles(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong,
  $role-names as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/amp-remove-roles",
          "execute"),
      $curr-user := xdmp:get-current-user(),
      $grant := xdmp:can-grant-roles($role-names),
      $col := security-collection(),
      $amp := get-amp($namespace, $local-name, $document-uri, $database),
      $current := amp-get-roles($namespace, $local-name, $document-uri, $database),
      $new := 
        for $r in $current
        return 
          if ($r = $role-names) 
          then () 
          else $r
  return
    xdmp:node-replace(
      $amp/sec:role-ids,
      <sec:role-ids>{get-role-ids($new)}</sec:role-ids>)
}


(:
::
:: sec:remove-amp(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,
::      $database as xs:unsignedLong)
:: as  empty() 
::
:: Summary:
::
::      Removes the amp ($namespace, $local-name, $document-uri, $database) and returns 
::      true after completion.  
::
:: Parameters:
::
::      $namespace 
::            The namespace of the function to which the amp applies.  
::  
::      $local-name 
::            The name of the function to which the amp applies.  
::  
::      $document-uri 
::            The URI of the document in which the function is located.  
::
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/remove-amp  
:: 
:: Usage Notes:
::
::       If an amp ($namespace, $local-name, $document-uri, $database) is not found, an 
::       error is returned.  
::
:)

define function 
remove-amp(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/remove-amp",
          "execute"),
      $col := security-collection(),
      $amp := get-amp($namespace, $local-name, $document-uri, $database)
  return
    xdmp:document-delete(xdmp:node-uri($amp))
}


(:
::
:: sec:amp-doc-collections()
:: as  xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings corresponding to the collection uri's 
::      that amps belong to.  
::
::
:)

define function 
amp-doc-collections()
as xs:string*
{
  (security-collection(),amps-collection())
}


(:
::
:: sec:amp-doc-permissions()
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements that all newly created amp 
::      documents receive.  
::
::
:)

define function 
amp-doc-permissions()
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-amp",
          "execute"),
      $amps-update := get-role-ids("security"),
      $amps-insert := get-role-ids("security"),
      $amps-read := get-role-ids("security")
  return
    (<sec:permission>
       {$amps-read}
       <sec:capability>read</sec:capability>
     </sec:permission>,
     <sec:permission>
       {$amps-update}
       <sec:capability>update</sec:capability>
     </sec:permission>,  
     <sec:permission>
       {$amps-insert}
       <sec:capability>insert</sec:capability>
     </sec:permission>)
}

(:
::
:: sec:user-doc-collections()
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings corresponding to the collection uri's 
::      that users belong to.  
::
::
:)

define function 
user-doc-collections()
as xs:string*
{
  (security-collection(),users-collection())
}


(:
::
:: sec:user-doc-permissions()
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements that all newly created user 
::      documents receive.  
::
::
:)

define function 
user-doc-permissions()
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-user",
          "execute"),
      $users-update := get-role-ids("security"),
      $users-insert := get-role-ids("security"),
      $users-read := get-role-ids("security")
  return
    (<sec:permission>
       {$users-read}
       <sec:capability>read</sec:capability>
     </sec:permission>,
     <sec:permission>
       {$users-update}
       <sec:capability>update</sec:capability>
     </sec:permission>,  
     <sec:permission>
       {$users-insert}
       <sec:capability>insert</sec:capability>
     </sec:permission>)
}

(:
::
:: sec:role-doc-collections()
:: as  xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings corresponding to the collection uri's 
::      that roles belong to.  
::
::
:)

define function 
role-doc-collections()
as xs:string*
{
  (security-collection(),roles-collection())
}


(:
::
:: sec:role-doc-permissions()
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements that all newly created role 
::      documents receive.  
::
::
:)

define function 
role-doc-permissions()
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-role",
          "execute"),
      $roles-update := get-role-ids("security"),
      $roles-insert := get-role-ids("security"),
      $roles-read := get-role-ids("security")
  return
    (<sec:permission>
       {$roles-read}
       <sec:capability>read</sec:capability>
     </sec:permission>,
     <sec:permission>
       {$roles-update}
       <sec:capability>update</sec:capability>
     </sec:permission>,  
     <sec:permission>
       {$roles-insert}
       <sec:capability>insert</sec:capability>
     </sec:permission>)
}


(:
::
::
:: get-element(
::   $col as xs:string,
::   $elem as xs:string,
::   $filter as xs:string,
::   $value as xs:string,
::   $function-error as xs:string)
:: as element()?
:: 
:: retrieves an element within a collection, $col, that is the root
:: element in a document and has has xs:Qname $elem.  The element must also
:: have a child with xs:QName $filter with value equal to $value.  If these
:: conditions are not met, an error is thrown with argument $function-error.
::
:: This function should be left for internal security module functions use.
::
:)

define function get-element(
  $col as xs:string,
  $elem as xs:string,
  $filter as xs:string,
  $value as xs:string,
  $function-error as xs:string)
as element()?
{
  let $value := element { xs:QName($filter) } { $value }
  let $elem := fn:collection($col)/*[fn:node-name(.) eq xs:QName($elem)]/*
                 [fn:node-name(.) eq xs:QName($filter)]
                 [. = $value]/..
  return
    if (fn:empty($elem))
    then fn:error($function-error, ($filter, $value))
    else $elem
}

(:
::
:: sec:get-amp(
::      $namespace as xs:string,  
::      $local-name as xs:string,  
::      $document-uri as xs:string,
::	$datbase as xs:unsignedLong)
:: as element(sec:amp)? 
::
:: Summary:
::
::      Returns an sec:amp element corresponding to an amp identified by 
::      ($namespace, $local-name, $document-uri, $database). If no such amp is found, 
::      an error is returned.  
::
:: Parameters:
::
::      $namespace 
::            Namespace of the function to which the amp applies.  
::  
::      $local-name 
::            Name of function to which the amp applies.  
::  
::      $document-uri 
::            URI of the document in which the function is located.  
:: 
::      $database
::            Database ID in which the module is located. If the module is on
::            the file system, specify xs:unsignedLong(0).
::
:)

define function 
get-amp(
  $namespace as xs:string,
  $local-name as xs:string,
  $document-uri as xs:string,
  $database as xs:unsignedLong)
as element(sec:amp)?
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/get-amp",
          "execute"),
      $col := security-collection(),
      $namespace := element sec:namespace { $namespace },
      $local-name := element sec:local-name { $local-name },
      $document-uri := element sec:document-uri { $document-uri },
      $amp := fn:collection($col)/sec:amp
                [ sec:namespace = $namespace ]
                [ sec:local-name = $local-name ]
                [ sec:document-uri = $document-uri ]
                [ sec:database = $database or 
                  ($database = 0 and fn:empty(sec:database)) ],
      $err := 
        if (fn:empty($amp)) 
        then fn:error("SEC-AMPDNE",($namespace,$local-name,$document-uri,$database))
        else ()
  return
    $amp
}

(:
::
:: sec:get-privilege(
::      $action as xs:string,  
::      $kind as xs:string)
:: as element(sec:privilege)? 
::
:: Summary:
::
::      Returns a sec:privilege element corresponding to a privilege 
::      identified by ($action,$kind). If no such privilege is found, an error 
::      is returned.  
::
:: Parameters:
::
::      $action 
::            Action protected by this privilege. For an Execute 
::            Privilege, this is usually a URI describing an activity. For 
::            a URI Privilege, this is a base URI used to filter database 
::            activities with certain document URIs.  
::  
::      $kind 
::           Either "execute" or "uri".  
:: 
::
:)

define function 
get-privilege(
  $action as xs:string,
  $kind as xs:string)
as element(sec:privilege)?
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/get-privilege",
          "execute"),
      $col := security-collection(),
      $action := element sec:action { $action },
      $priv := fn:collection($col)/sec:privilege
                 [sec:action = $action][sec:kind = $kind],
      $err := 
        if (fn:empty($priv)) 
        then fn:error("SEC-PRIVDNE",($action,$kind))
        else ()
  return
    $priv
}

(:
::
:: sec:get-unique-elem-id(
::      $type as xs:string,
::      $name as xs:string)
:: as xs:unsignedLong 
::
:: Summary:
::
::      Returns a hashed id for a given $type and $name combined.  
::
:: Parameters:
::
::      $type
::           The type of the security object.  
::      $name 
::           The name of a security object.  
:: 
::
:)

define function 
get-unique-elem-id(
  $type as xs:string,
  $name as xs:string)
as xs:unsignedLong
{
  xdmp:add64(
    xdmp:mul64(xdmp:hash64($name),5),
    xdmp:hash64($type))
}

(:
::
:: sec:priv-doc-collections()
:: as  xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings corresponding to the collection uri's 
::      that privileges belong to.  
::
::
:)

define function 
priv-doc-collections()
as xs:string*
{
  (security-collection(),privileges-collection())
}


(:
::
:: sec:priv-doc-permissions()
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements that all newly created 
::      privilege documents receive.  
::
::
:)

define function 
priv-doc-permissions()
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/create-privilege",
          "execute"),
      $privs-update := get-role-ids("security"),
      $privs-insert := get-role-ids("security"),
      $privs-read := get-role-ids("security")
  return
    (<sec:permission>
       {$privs-read}
       <sec:capability>read</sec:capability>
     </sec:permission>,
     <sec:permission>
       {$privs-update}
       <sec:capability>update</sec:capability>
     </sec:permission>,  
     <sec:permission>
       {$privs-insert}
       <sec:capability>insert</sec:capability>
     </sec:permission>)
}

(:
::
:: sec:security-collection()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the Security collection. 
::       
::
::
:)

define function 
security-collection()
as xs:string
{
  "http://marklogic.com/xdmp/security"
}

(:
::
:: sec:security-namespace()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri of the security namespace.  
::
::
:)

define function 
security-namespace()
as xs:string
{
  "http://marklogic.com/xdmp/security"
}

(:
::
:: sec:users-collection()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the users collection.  
::
::
:)

define function 
users-collection()
as xs:string
{
  "http://marklogic.com/xdmp/users"
}

(:
::
:: sec:roles-collection()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the roles collection.  
::
::
:)

define function 
roles-collection()
as xs:string
{
  "http://marklogic.com/xdmp/roles"
}

(:
::
:: sec:privileges-collection()
:: as  xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the privileges 
::      collection.  
::
::
:)

define function 
privileges-collection()
as xs:string
{
  "http://marklogic.com/xdmp/privileges"
}

(:
::
:: sec:amps-collection()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the amps collection.  
::
::
:)

define function 
amps-collection()
as xs:string
{
  "http://marklogic.com/xdmp/amps"
}

(:
::
:: sec:collections-collection()
:: as xs:string 
::
:: Summary:
::
::      Returns a string corresponding to the uri for the protected 
::      collections collection.  
::
::
:)

define function 
collections-collection()
as xs:string
{
  "http://marklogic.com/xdmp/collections"
}

(:
:: 
:: collection-doc-collections()
:: as xs:string*
::
:: Returns a sequence of strings corresponding to the uri's of the
:: collections that a protected collection is added to.
::
:: This function should be left for internal security module functions use.
::
:)

define function 
collection-doc-collections()
as xs:string*
{
  (security-collection(),collections-collection())
}


(:
::
:: sec:user-set-default-permissions(
::      $user-name as xs:string,  
::      $permissions as element(sec:permission)*)
:: as  empty() 
::
:: Summary:
::
::      Sets the default permissions for a user with name $user-name.  
::
:: Parameters:
::
::      $user-name 
::           The name of the user.  
::  
::      $permissions 
::            New permissions. If the empty sequence is provided, deletes 
::            the existing permissions.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/user-set-default-permissions 
::        
:: 
:: Usage Notes:
::
::       If a user with name $user-name is not found, an error is raised.  
::
:)

define function 
user-set-default-permissions(
  $user-name as xs:string,
  $permissions as element(sec:permission)*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-set-default-permissions",
            "execute"),
        $col := security-collection(),
        $user := get-element($col, "sec:user", 
                            "sec:user-name",$user-name, 
                            "SEC-USERDNE"),
        $role-id-check := 
          for $p in $permissions 
          return
            get-element($col, "sec:role", 
                        "sec:role-id", xs:string($p/sec:role-id), 
                        "SEC-ROLEDNE"),
        $perms := get-distinct-permissions($permissions,())
    return (
      xdmp:node-replace(
        $user/sec:permissions,
        <sec:permissions>{$perms}</sec:permissions>),
      xdmp:audit("userconfig",$user-name,"change-default-permissions",fn:true())
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"change-default-permissions",fn:false()),
    xdmp:rethrow()
  }
      
}

(:
::
:: sec:get-distinct-permissions(
::      $input-perms as element(sec:permission)*,  
::      $output-perms as element(sec:permission)*)
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements made up of a concatenation 
::      of $output-perms and the distinct permission elements of $input-perms.  
::
:: Parameters:
::
::      $input-perms 
::            The input permissions.  
::  
::      $output-perms 
::            The output permissions.  
:: 
::
:)

define function
get-distinct-permissions(
  $input-perms as element(sec:permission)*,
  $output-perms as element(sec:permission)*)
as element(sec:permission)*
{
  if (fn:empty($input-perms)) 
  then $output-perms
  else
    let $in-p := fn:item-at($input-perms, 1)
    let $no-add :=
      for $out-p in $output-perms
      return
        if ((fn:data($out-p/sec:role-id) = fn:data($in-p/sec:role-id)) and
            (fn:data($out-p/sec:capability) = fn:data($in-p/sec:capability)))
        then "found" else ()
    return 
      if ("found" = $no-add)
      then get-distinct-permissions(fn:subsequence($input-perms,2),
                                    $output-perms)
      else get-distinct-permissions(fn:subsequence($input-perms,2),
                                    ($in-p,$output-perms))
}


(:
::
:: sec:role-set-default-permissions(
::      $role-name as xs:string,  
::      $permissions as element(sec:permission)*)
:: as  empty() 
::
:: Summary:
::
::      Sets the default permissions for a role with name $role-name.  
::
:: Parameters:
::
::      $role-name 
::            The name of the role to which the default permissions are 
::            set.  
::  
::      $permissions 
::            New permissions. If the empty sequence is provided, deletes 
::            the existing permissions.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/role-set-default-permissions 
::        
:: 
:: Usage Notes:
::
::       If a role with name $role-name is not found, an error is raised.  
::
:)

define function 
role-set-default-permissions(
  $role-name as xs:string,
  $permissions as element(sec:permission)*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-set-default-permissions",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE"),
      $role-id-check := 
        for $p in $permissions 
        return
          get-element($col, "sec:role", 
                      "sec:role-id", xs:string($p/sec:role-id), 
                      "SEC-ROLEDNE"),
      $perms := get-distinct-permissions($permissions,())
  return
    xdmp:node-replace(
      $role/sec:permissions,
      <sec:permissions>{$perms}</sec:permissions>)
}

(:
::
:: sec:user-get-default-permissions(
::      $user-name as xs:string)
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements correspondinig to the user's 
::      default permissions.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/user-get-default-permission 
::        
:: 
:: Usage Notes:
::
::       If a user with name $user-name is not found, an error is raised.  
::
:)

define function 
user-get-default-permissions(
  $user-name as xs:string)
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/user-get-default-permission",
          "execute"),
      $col := security-collection(),
      $user := get-element($col, "sec:user", 
                           "sec:user-name",$user-name, 
                           "SEC-USERDNE")
      return
        $user/sec:permissions/sec:permission
}

(:
::
:: sec:role-get-default-permissions(
::      $role-name as xs:string)
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements correspondinig to the role's 
::      default permissions.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/role-get-default-permissions 
::        
:: 
:: Usage Notes:
::
::       If a role with name $role-name is not found, an error is raised.  
::
:)

define function 
role-get-default-permissions(
  $role-name as xs:string)
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-get-default-permissions",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE")
      return
        $role/sec:permissions/sec:permission
}

(:
::
:: sec:user-get-default-collections(
::      $user-name as xs:string)
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings correspondinig to the uri's of the 
::      user's default collections.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/user-get-default-collections 
::        
:: 
:: Usage Notes:
::
::       If a user with name $user-name is not found, an error is raised.  
::
:)

define function 
user-get-default-collections(
  $user-name as xs:string)
as xs:string*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/user-get-default-collections",
          "execute"),
      $col := security-collection(),
      $user := get-element($col, "sec:user", 
                           "sec:user-name",$user-name, 
                           "SEC-USERDNE")
      return
        for $c in $user/sec:collections/sec:uri
        return xs:string($c)
}

(:
::
:: sec:role-get-default-collections(
::      $role-name as xs:string)
:: as xs:string* 
::
:: Summary:
::
::      Returns a sequence of strings correspondinig to the uri's of the 
::      role's default collections.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/role-get-default-collections 
::        
:: 
:: Usage Notes:
::
::       If a role with name $role-name is not found, an error is raised.  
::
:)

define function 
role-get-default-collections(
  $role-name as xs:string)
as xs:string*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-get-default-collections",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE")
      return
        for $c in $role/sec:collections/sec:uri
        return xs:string($c)
}


(:
::
:: sec:user-set-default-collections(
::      $user-name as xs:string,  
::      $collections as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Sets the default collections of a user with name $user-name to 
::      $collections.  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
::  
::      $collections 
::            A sequence of collections.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/user-set-default-collections 
::        
:: 
:: Usage Notes:
::
::       If a user with name $user-name is not found, an error is raised.  
::
:)

define function 
user-set-default-collections(
  $user-name as xs:string,
  $collections as xs:string*)
as empty()
{
  try {
    let $assert := 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-set-default-collections",
            "execute"),
        $col := security-collection(),
        $user := get-element($col, "sec:user", 
                              "sec:user-name",$user-name, 
                              "SEC-USERDNE"),
        $cols := 
          for $c in fn:distinct-values($collections)
          return <sec:uri>{$c}</sec:uri>
    return (
      xdmp:node-replace(
        $user/sec:collections,
        <sec:collections>{$cols}</sec:collections>),
        xdmp:audit("userconfig",$user-name,"change-default-collections",fn:true())
    )
  } catch ($e) {
    xdmp:audit("userconfig",$user-name,"change-default-collections",fn:false()),
    xdmp:rethrow()
  }
}



(:
::
:: sec:role-set-default-collections(
::      $role-name as xs:string,  
::      $collections as xs:string*)
:: as  empty() 
::
:: Summary:
::
::      Sets the default collections of a role with name $role-name to 
::      $collections.  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
::  
::      $collections 
::            A sequence of collections.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/role-set-default-collections 
::        
:: 
:: Usage Notes:
::
::       If a role with name $role-name is not found, an error is raised.  
::
:)

define function 
role-set-default-collections(
  $role-name as xs:string,
  $collections as xs:string*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-set-default-collections",
          "execute"),
      $col := security-collection(),
      $role := get-element($col, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE"),
      $cols := 
        for $c in fn:distinct-values($collections)
        return <sec:uri>{$c}</sec:uri>
  return
    xdmp:node-replace(
      $role/sec:collections,
      <sec:collections>{$cols}</sec:collections>)
}


(:
::
:: sec:get-collection(
::      $uri as xs:string)
:: as element(sec:collection) 
::
:: Summary:
::
::      Gets the security document corresponding to a protected collection 
::      with uri equal to $uri.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/unprotect-collection 
::       or 
::       http://marklogic.com/xdmp/privileges/collection-set-permissions 
::       or 
::       http://marklogic.com/xdmp/privileges/collection-add-permissions 
::       or 
::       http://marklogic.com/xdmp/privileges/collection-remove-permissions 
::        
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function
get-collection(
  $uri as xs:string)
as element(sec:collection)
{
  let $assert := 
        xdmp:security-assert(
          ("http://marklogic.com/xdmp/privileges/unprotect-collection",
           "http://marklogic.com/xdmp/privileges/collection-set-permissions",
           "http://marklogic.com/xdmp/privileges/collection-add-permissions",
           "http://marklogic.com/xdmp/privileges/collection-remove-permissions"),
          "execute"),
      $col := security-collection(),
      $uri := element sec:uri { $uri },
      $c := fn:collection($col)/sec:collection[sec:uri = $uri],
      $err := 
        if (fn:empty($c)) 
        then fn:error("SEC-COLDNE", $uri) 
        else ()
  return $c
}


(:
::
:: sec:protect-collection(
::      $uri as xs:string,  
::      $permissions as element(sec:permission)*)
:: as xs:unsignedLong 
::
:: Summary:
::
::      Protects a collection $uri with the given permissions ($permissions). 
::      Returns the unique id of the protected collection.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
::  
::      $permissions 
::            Permissions governing the collection.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/protect-collection  
:: 
:: Usage Notes:
::
::       If $uri is empty or can not be cast as an xs:AnyURI, an error is 
::       raised. If a collection with the same uri is already protected, an 
::       error is raised.  
::
:)

define function 
protect-collection(
  $uri as xs:string,
  $permissions as element(sec:permission)*)
as xs:unsignedLong
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/protect-collection",
          "execute"),
      $bad := 
        if (xdmp:castable-as(security-namespace(), "uri", $uri)) 
        then ()
        else if ($uri) 
        then fn:error("SEC-BADCOLURI")
        else fn:error("SEC-NOEMPTYCOLURI"),
      $uri := element sec:uri { $uri },
      $err := 
        if (fn:collection(security-collection())/sec:collection[sec:uri = $uri])
        then fn:error("SEC-COLPROTECTED") 
        else (),
      $doc-uri := "http://marklogic.com/xdmp/collections/",
      $collection-id := get-unique-elem-id("collection-uri()",$uri)
  return
    let $insert :=
      xdmp:document-insert(fn:concat($doc-uri,xs:string($collection-id)),
        <sec:collection>
          <sec:collection-id>{$collection-id}</sec:collection-id>
          {$uri}
        </sec:collection>,
        $permissions,collection-doc-collections())
    return $collection-id
}

(:
::
:: sec:unprotect-collection(
::      $uri as xs:string)
:: as  empty()
::
:: Summary:
::
::      Removes the protection of a collection $uri. This does not remove the 
::      collection or any of its documents.  
::
:: Parameters:
::
::      $uri 
::            The URI of the collection from which to remove protections.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/unprotect-collection  
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function
unprotect-collection(
  $uri as xs:string)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/unprotect-collection",
          "execute"),
      $col := get-collection($uri),
      $err := 
        if ($col) 
        then () 
        else fn:error("SEC-COLCNE") 
  return
    xdmp:document-delete(xdmp:node-uri($col))
}

(:
::
:: sec:collection-set-permissions(
::      $uri as xs:string,  
::      $permissions as element(sec:permission)*)
:: as  empty() 
::
:: Summary:
::
::      Sets the permissions of a protected collection identified by $uri to 
::      $permissions.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
::  
::      $permissions 
::            New permissions. If the empty sequence is provided, deletes 
::            the existing permissions.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/collection-set-permissions 
::        
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function 
collection-set-permissions(
  $uri as xs:string,
  $permissions as element(sec:permission)*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/collection-set-permissions",
          "execute"),
      $col := get-collection($uri)
  return
    xdmp:document-set-permissions(xdmp:node-uri($col), $permissions)
}

(:
::
:: sec:collection-add-permissions(
::      $uri as xs:string,  
::      $permissions as element(sec:permission)*)
:: as  element(sec:permission)* 
::
:: Summary:
::
::      Add the permissions $permissions to the protected collection 
::      identified by $uri.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
::  
::      $permissions 
::            New permissions to add to that protected collection. If 
::            $permissions is the empty sequence, the function will have no 
::            effect.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/collection-add-permissions 
::        
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function 
collection-add-permissions(
  $uri as xs:string,
  $permissions as element(sec:permission)*)
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/collection-add-permissions",
          "execute"),
      $col := get-collection($uri)
  return
    xdmp:document-add-permissions(xdmp:node-uri($col), $permissions)
}

(:
::
:: sec:collection-remove-permissions(
::      $uri as xs:string,  
::      $permissions as element(sec:permission)*)
:: as  empty()
::
:: Summary:
::
::      Removes the permissions $permissions from the protected collection 
::      identified by $uri.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
::  
::      $permissions 
::            Permissions to be removed from that protected collection. If 
::            $permissions is the empty sequence, the function will have no 
::            effect.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/collection-remove-permissions 
::        
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function 
collection-remove-permissions(
  $uri as xs:string,
  $permissions as element(sec:permission)*)
as empty()
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/collection-remove-permissions",
          "execute"),
      $col := get-collection($uri)
  return
    xdmp:document-remove-permissions(xdmp:node-uri($col), $permissions)
}

(:
::
:: sec:collection-get-permissions(
::      $uri as xs:string)
:: as element(sec:permission)* 
::
:: Summary:
::
::      Returns a sequence of permission elements corresponding to the current 
::      permissions granted to the protected collection identified by $uri.  
::
:: Parameters:
::
::      $uri 
::           The URI of a collection.  
:: 
:: Privileges Required:
::
::       
::       http://marklogic.com/xdmp/privileges/collection-get-permissions 
::        
:: 
:: Usage Notes:
::
::       If a protected collection with uri equal to $uri is not found, an 
::       error is raised.  
::
:)

define function 
collection-get-permissions(
  $uri as xs:string)
as element(sec:permission)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/collection-get-permissions",
          "execute"),
      $col := get-collection($uri)
  return
    xdmp:document-get-permissions(xdmp:node-uri($col))
}

(:
::
:: sec:user-privileges(
::      $user-name as xs:string)
:: as element(sec:privilege)* 
::
:: Summary:
::
::      Returns a set of privilege elements corresponding to all privileges 
::      that a user has. (roles are flattened to give a complete set of 
::      privileges).  
::
:: Parameters:
::
::      $user-name 
::           The name of a user.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/user-privileges if 
::       the current user is not $user-name.  
:: 
:: Usage Notes:
::
::       If a user with name equal to $user-name is not found, an error is 
::       raised.  
::
:)

define function
user-privileges(
  $user-name as xs:string)
as element(sec:privilege)*
{
  let $curr-user := xdmp:get-current-user(),
      $sec  := security-collection(),
      $user := get-element($sec, "sec:user", 
                           "sec:user-name",$user-name, 
                           "SEC-USERDNE"),
      $verify := 
        if ($curr-user = $user-name) 
        then ()
        else 
          xdmp:security-assert(
            "http://marklogic.com/xdmp/privileges/user-privileges",
            "execute"),
      $col := privileges-collection(),
      $privs := fn:collection($col)/sec:privilege,
      $rids := xdmp:user-roles($user-name)
  return
    for $p in $privs
    return
      if ((xdmp:privilege-roles(xs:string($p/sec:action),$p/sec:kind)) = $rids)
      then $p
      else ()
}

(:
::
:: sec:role-privileges(
::      $role-name as xs:string)
:: as  element(sec:privilege)*
::
:: Summary:
::
::      Returns a set of privilege elements corresponding to all privileges 
::      that a role has. (Roles are flattened to give a complete set of 
::      privileges).  
::
:: Parameters:
::
::      $role-name 
::           The name of a role.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/role-privileges if 
::       the current role is not $role-name.  
:: 
:: Usage Notes:
::
::       If a role with name equal to $role-name is not found, an error is 
::       raised.  
::
:)

define function
role-privileges(
  $role-name as xs:string)
as element(sec:privilege)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/role-privileges",
          "execute"),
      $sec  := security-collection(),
      $role := get-element($sec, "sec:role", 
                           "sec:role-name",$role-name, 
                           "SEC-ROLEDNE"),
      $col := privileges-collection(),
      $privs := fn:collection($col)/sec:privilege,
      $rids := (xdmp:role-roles($role-name),fn:data($role/sec:role-id))
  return
    for $p in $privs
    return
      if ((xdmp:privilege-roles(xs:string($p/sec:action),$p/sec:kind)) = $rids)
      then $p
      else ()
}

(:
::
:: sec:security-installed()
:: as xs:boolean 
::
:: Summary:
::
::      Returns fn:true() if security has been installed on the current 
::      database. Otherwise, returns false.  
::
::
:)

define function
security-installed()
as xs:boolean
{
  if (fn:empty(fn:collection("http://marklogic.com/xdmp/security"))) 
  then fn:false()
  else fn:true()
}

(:
::
:: sec:uid-for-name(
::      $name as xs:string)
:: as xs:unsignedLong* 
::
:: Summary:
::
::      Returns the uids for the named user or () if no such user exists.  
::
:: Parameters:
::
::      $name 
::           The named user.  
:: 
::
:)

define function
uid-for-name($name as xs:string)
as xs:unsignedLong*
{
  fn:collection(security-collection())/sec:user
    [sec:user-name eq $name]/sec:user-id 
}

(:
::
:: sec:get-user-names(
::      $user-ids as xs:unsignedLong*)
:: as element(sec:user-name)* 
::
:: Summary:
::
::      Returns sequence of unique sec:user-name's that corresponds to the 
::      sequence of user IDs $user-ids. Duplicate IDs return a single name.  
::
:: Parameters:
::
::      $user-ids 
::            A sequence of user IDs.  
:: 
:: Privileges Required:
::
::       http://marklogic.com/xdmp/privileges/get-user-names  
:: 
:: Usage Notes:
::
::       If a user ID in $user-ids does not correspond to an existing user, an 
::       error is returned.  
:: 
:: Examples:
::
::       sec:get-user-names((xs:unsignedLong(2234), 
::                           xs:unsignedLong(543356)))    
::       =>       
::       (<sec:user-name>john</sec:user-id>,        
::       <sec:user-id>kate</sec:user-id>)     
::
:)

define function get-user-names(
  $user-ids as xs:unsignedLong*)
as element(sec:user-name)*
{
  let $assert := 
        xdmp:security-assert(
          "http://marklogic.com/xdmp/privileges/get-user-names",
          "execute"),
      $col := security-collection()
  for $u-id in fn:distinct-values($user-ids)
  let $user := fn:collection($col)/sec:user[sec:user-id=$u-id]
  return 
    if (fn:exists($user))
    then $user/sec:user-name
    else fn:error("SEC-USERDNE", ("sec:user-id",$u-id))
}

(:
::
:: sec:set-realm(
::      $realm as xs:string)
:: as empty() 
::
:: Summary:
::
::      Changes the realm of this security database to $realm. If the realm is 
::      different from the old value this function also invalidates all the 
::      existing digest passwords since they will no longer work with the new 
::      realm.  
::
:: Parameters:
::
::      $realm 
::            The new realm name to which the security database name is 
::            changed.  
:: 
::
:)

define function
set-realm($realm as xs:string)
as empty()
{
  if ($realm eq "") then
    fn:error("SEC-EMPTYREALM")  
  else 
    let $old-realm :=
    fn:data(/sec:metadata/sec:realm)
    return
    if($old-realm eq $realm) then
      (: don't make any changes if the realm is the same as it was before :)
      ()
    else ( 
      xdmp:node-replace(
        /sec:metadata/sec:realm,
        <sec:realm>{$realm}</sec:realm>),
  
      (: now delete all the invalid digest passwords :)
      for $u in fn:collection(security-collection())/sec:user[sec:digest-password]
      return
        xdmp:node-delete($u/sec:digest-password) )
}

(:
::
:: sec:check-admin()
:: as empty() 
::
:: Summary:
::
::      Throws an error if the current user does not have the admin role.  
::
::
:)

define function
check-admin()
as empty()
{
  if (xdmp:has-privilege(
    "http://marklogic.com/xdmp/privileges/admin-ui",
    "execute")) 
  then ()
  else fn:error("SEC-NOADMIN")
}

(:
::
:: sec:security-version()
:: as xs:integer 
::
:: Summary:
::
::      Returns the current version of the security database.  
::
::
:)

define function
security-version()
as xs:integer
{
  xs:integer(xdmp:security-version())
}

define function
role-children($role-ids as xs:unsignedLong*)
as xs:unsignedLong*
{
  let $col := security-collection()
  return fn:distinct-values
  (
    for $r in $role-ids
    return fn:data(fn:collection($col)/sec:role[$r = xdmp:role-roles(sec:role-name)]/sec:role-id)
  )
}

define function role-get-users(
  $unparsed-roles as xs:unsignedLong*,
  $parsed-roles as xs:unsignedLong*,
  $users as xs:string*)
as xs:string*
{
  let $role := $unparsed-roles[1]
  let $other-roles := if (fn:count($unparsed-roles) eq 1) then ()
                else $unparsed-roles[2 to fn:last()]
  return
    if (fn:empty($role)) then fn:distinct-values($users)
    else if ($role = $parsed-roles) then
      role-get-users($other-roles,$parsed-roles,$users)
    else
      let $col := security-collection()
      let $new-roles := 
          for $r in fn:collection($col)/sec:role[sec:role-ids/sec:role-id = $role]/sec:role-id
          return 
            fn:data($r)
        let $new-users := 
          for $u in fn:collection($col)/sec:user[sec:role-ids/sec:role-id = $role]/sec:user-name
          return 
            fn:data($u)
      return
        role-get-users(($other-roles,$new-roles),
          ($parsed-roles,$role),($users,$new-users))
}
