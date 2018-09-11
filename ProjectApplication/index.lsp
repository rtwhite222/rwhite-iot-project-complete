<!DOCTYPE html>
<!-- Login page - This page is intended to be the gateway into the web application. 
     The signing in is handed server side through a user session. No other pages are
     accessable if the user has not logged in first. -->
<html>
    <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1">
        <title>Login Page</title>
        <link rel="stylesheet" href="cssfiles/loginpage.css">
    </head>
<body>
    <div class="center-div">
        <form method="post">
        <br>
        <h2 align = "center">Email:</h2>
        <input type="text" name="Email" placeholder="Enter Email" autocomplete="off" autofocus required><br>
        <h2 align = "center">Password:</h2>
        <input type="password" name="password" placeholder="Enter password"  required><br><br><br>
        <input type="submit" value = "Login">
        </form>
            <?lsp -- START SERVER SIDE CODE
            
                usersession = request:session(true) 
                -- Creates user session (persistent through the application)
            
                usersession.loggedin = false
                -- Sets the inactivity duration of the session before
                -- it is automatically deleted from the server
                usersession:maxinactiveinterval(1800)
                if not usersession.lockoutuntil then usersession.lockoutuntil = 0 end
                -- If this value has not been set, set it to 0, if not done this way, would set to 0 every iteration
                if request:method() == "POST" and (os.time()>(usersession.lockoutuntil or 0)) then
                -- If the user submits data nd they aren't locked out from too many incorrect login attempts
                -- allow them to attempt to log in.
                local luaTable = request:data() -- grabs data from posted form
                local su=require("sqlutil") -- sql utility that allows access to database commands
                local sql = selectQueryWhere({"password"},"users","Email",luaTable.Email); -- builds select query
            
                
                    local function execute(cur)
                        password = cur:fetch()
                        return true
                    end
                    -- finds password associated with account
                    
                    local function opendb() 
                        return su.open("file")
                    end
                    -- opens database
                    
                    local ok,err=su.select(opendb,string.format(sql), execute)
                    -- performs select query and closes database
                    if not ok then 
                        response:write("DB err: "..err) 
                    end
                    -- prints error message if database caused issue with logging in
                    
                    
                   if (luaTable.password == password) then
                        usersession.loggedin = true;
                        -- Sets the logged in value for the session to true
                        
                        usersession.loggedinas = luaTable.Email;
                        -- Adds the name of the logged in user to the session
                        
                        usersession.loginattempts = 0;
                        -- Resets number of failed login attempts
                        -- 
                        local sql = selectQueryWhere({"CompanyName,PermissionLevel"},"users","Email",luaTable.Email);
                        -- another select query grabbing the permission level and associated company with the user
                        -- the permission levels could have been found by performing an inner join
                        -- but the custom select query wasn't suited for that sort of peration
                        -- so creating two selects was oped for instead
                        
                        local function execute(cur)
                            company,permissionlevel = cur:fetch();
                            return true;
                        end
                        
                        local function opendb() 
                            return su.open("file");
                        end
                        
                        local ok,err=su.select(opendb,string.format(sql), execute);
                        
                        usersession.company=company;
                        -- Adds the user's associated company to the session
                        if not ok then 
                            response:write("DB err: "..err) 
                        end
                        
                        local sql = selectQueryWhere({"viewAllDevices","viewAllUsers","changeUserSettings","viewCompanyUsers"
                            ,"addNewNonCompanyUsers","addCompanyUsers","addNewCompany","addNewDevice",
                            "changeDeviceSettings","isManufacturerEmployee","isRoot"},"permissions","PermissionLevel",permissionlevel)
                        -- Builds select query that grabs all permissions from permission list
                        local function execute(cur)
                            usersession.viewAllDevices, usersession.viewAllUsers,usersession.changeUserSettings,usersession.viewCompanyUsers
                            ,usersession.addNewNonCompanyUsers,usersession.addCompanyUsers,usersession.addNewCompany,usersession.addNewDevice,
                            usersession.changeDeviceSettings,usersession.isManufacturerEmployee,usersession.isRoot = cur:fetch();
                            return true;
                        end
                        -- assigns all permissions associated with the user's permission settings
                        -- to the user's session
                        local ok,err=su.select(opendb,string.format(sql), execute);
                        
                        local sql= "INSERT INTO userlogs VALUES('"..luaTable.Email.."','"..os.time().."','User Login');"
                        local env,conn = su.open"file"
                        local ok,err=conn:execute(sql)
                        su.close(env,conn)
                        -- block of code which logs the user's login and time of login
                    
                    if not ok then 
                        response:write("DB err: "..err) 
                    end
                    --if ok then
                    ?>
                       <script>location.href = "devicelist.lsp"</script>
                       <!-- directs user to deviceslist page -->
                    <?lsp    
                    -- if login failed
                    else
                        usersession.loginattempts = (usersession.loginattempts or 0) + 1
                        -- if a failed login attempt, creates a session value for login attempts if not
                        -- already created, otherwise add 1 to previous number of attempts
                        if(usersession.loginattempts >= 3) then
                            usersession.loginattempts = 0
                            usersession.lockoutuntil =  os.time() + 60*5-1
                            -- If the user failed to log in for three times, locks them out for 5 minutes
                        else
                            print("<h3>Wrong username or password. Please try again</h3>")
                        end
                        
                end
                
            end
            -- If the user has exceeded 3 login attempts and current time is less than 5 minutes after
            -- the last attempt, display this message.
            if usersession.lockoutuntil > os.time() then print("<h3>Please wait another "
                ..(usersession.lockoutuntil-os.time())//60+1 .. 
                    " minute(s) before trying to log in again</h3>") 
            end
            ?>
        </div>
    </body>
</html>