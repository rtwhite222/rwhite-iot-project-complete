<!DOCTYPE html>
<html>
    <?lsp
        -- Makes sure the user is logged in
        usersession = request:session()
        if not usersession then response:forward"index.lsp" end
        function checkLogin()
            if not usersession.loggedin then
                print "not logged in"
                response:forward"index.lsp"
            end
        end
        checkLogin()
        -- If the user has permission to be on this page ie is able to add users to the system then
        -- allow access 
        if tonumber(usersession.addCompanyUsers)==1 then ?>
            <head>
                <meta charset="UTF-8"/>
                <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1">
                <title>Login Page</title>
                <link rel="stylesheet" href="cssfiles/inputForms.css?version=23">
                <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
            </head>
        
            <body>
                <div id="new-header">
                    <script> // loads the navbar and sets the add new user tab to be active
                        $("#new-header").load("header.lsp?version=2", function() {
                            $('#header-addNewUser').addClass('active');
                        });
                    </script>
                </div>
                
                <div class="container">
                    <div class="content-container-user-company">
                        <form method="post" autocomplete="off">
                            <!-- Form to create new user -->
                            Email *<br> <input type="email" name="Email" title="Please input a valid email address" required placeholder = "Enter a valid email address">
                            Password *<br> <input type="password" name="password" placeholder="Enter password" pattern="(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}" autocomplete="off" title="at least one number and one uppercase and lowercase letter, and at least 8 or more characters" required>
                            <br>Confirn Password *<br><input type="password" placeholder="Re-enter password" name="passwordCheck" required>
                            <input type="hidden" name ="PasswordExpiry" value = "0">
                            <br>Company *<br> 
                            <select name="CompanyName" required>
                                <option value=""></option>
                                <?lsp   
                                -- If the user is permitted to add new users from other companies
                                -- gives the company dropdown box a list of all companies currently
                                -- in the system
                                if tonumber(usersession.addNewNonCompanyUsers)==1 then
                                    local su=require"sqlutil"
                                    local sql=string.format("companyName FROM company")
                                        
                                    local function execute(cur)
                                        local company = cur:fetch()
                                        while company do
                                              response:write("<option value='"..company.."'>"..company.."</option>")
                                              company = cur:fetch()
                                        end
                                        return true
                                    end
                                        
                                    local function opendb() 
                                        return su.open"file" 
                                    end
                                        
                                    local ok,err=su.select(opendb,string.format(sql), execute)
                                    
                                else -- If not permitted to add non company users, gives their company as the only option
                                    response:write("<option value='"..usersession.company.."'>"..usersession.company.."</option>")
                                end
                                ?>
                            </select>
                            <br>
                            
                            <br>Phone Number<br> <input type="tel" name="ContactNumber" placeholder="Enter your phone number" title="Please input a valid phone number"><br>
                            Name *<br> <input type="text" name="username" required placeholder="Enter your full name here" ><br>
                            Permission Level *<br> <select name="permissionlevel" required><br>
                            <option value=""></option>
                            
                            <?lsp 
                            local sql
                            local su=require"sqlutil"
                            -- Used to determine what permission settings the user can grant another user
                            -- If the user is part of the manufacturer list, gives permission to give manufacturer employee roles
                            if tonumber(usersession.isManufacturerEmployee)== 1 then 
                                -- If the user has permission to add new non company users, permission granted will allow the same
                                if tonumber(usersession.addNewNonCompanyUsers)== 1 then
                                    -- If root, gives all permissions
                                    if tonumber(usersession.isRoot) == 1 then
                                        sql=selectQuery({"permissionLevel"},"permissions")
                                    else
                                    -- If not root, gives permission for everything except adding new root users
                                         sql=selectQueryWhere({"permissionLevel"},"permissions","isRoot","0")
                                    end
                                else
                                    -- If not able to add new company users, allows permission to add users that have manufacturer
                                    -- employee roles but don't allow for adding new non company users
                                     sql=selectQueryWhereMult(
                                         {"permissionLevel"},"permissions",
                                         {"isManufacturerEmployee","addNewNonCompanyUsers"},
                                         {"1","0"})
                                     trace(sql)
                                end
                            else
                                -- User can only grant permissions that don't allow for manufacturer permissions
                                 sql=selectQueryWhere({"permissionLevel"},"permissions","isManufacturerEmployee","0")
                            end
                        
                            
                            local function execute(cur)
                                local permissions = cur:fetch()
                                while permissions do
                                   print("<option value='"..permissions.."'>"..permissions.."</option>")
                                   permissions = cur:fetch()
                                end
                                return true
                            end
                            
                            local function opendb() 
                                return su.open"file" 
                            end
                        
                            local ok,err=su.select(opendb,string.format(sql), execute)
                            ?>
                            </select><br>
                            <input type="submit" value = "Create new user">
                        </form>
                        
                        
                    <?lsp -- START SERVER SIDE CODE
                        -- Checks to see if data has been submitted through a post method
                        if request:method() == "POST"  then
                            local userTable = request:data()
                            -- checks to see if the passwords entered are identical
                            if userTable.password == userTable.passwordCheck then
                                -- as it's now not needed (and causes issues) sets the password check back to nil
                                userTable.passwordCheck = nil
                                -- password expiry not implemented so it's set to 0
                                userTable.PasswordExpiry = 0
                                local su=require"sqlutil"
                                local env,conn = su.open"file"
                                -- Constructs the sql query
                                local sql = insertQuery(userTable,"users")
                                -- Performs the sql query
                                ok, err = conn:execute(sql)
                                if ok then 
                                ?>
                                <!-- Informs the user that the user has been created successfully -->
                                    <script>alert("New user created");</script>
                                    <?lsp local sql= "INSERT INTO userlogs VALUES('"..usersession.loggedinas.."','"..os.time().."','Created new user - ".. userTable.username .."');"
                                    local env,conn = su.open"file"
                                    local ok,err=conn:execute(sql)
                                    su.close(env,conn)
                                    -- Inserts the action of creating the user into the user logs
                                else ?>
                                    <script>alert("Failed to create this user. The email address used may have already been registered")</script>
                                <?lsp 
                                end
                                su.close(env,conn)
                            else if userTable.password ~= userTable.passwordCheck then ?>
                                <script>alert("Password mismach. Try again")</script>
                                
                    <?lsp   end -- If the entered passwords are mismatched prompts an alert to try again.
                        end
                    end
            
                    ?>
                    </div>
                </div>
            </body>
        <?lsp
        else
            print"ACCESS DENIED"
        end
    ?>
</html>