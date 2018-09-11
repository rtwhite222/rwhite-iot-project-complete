<!DOCTYPE html>
<html>
    <head>
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>
    <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
    <script src="https://use.fontawesome.com/1e803d693b.js"></script>
    <link rel="stylesheet" href="cssfiles/inputForms.css?version=32">
    <meta name=viewport content="width=device-width, initial-scale=1" />
    <?lsp 
        usersession = request:session()
        if not usersession then response:forward"index.lsp" end
        function checkLogin()
            if not usersession.loggedin then
                print "not logged in"
                response:forward"index.lsp"
            end
        end
    checkLogin()
    local userInfo=request:data().userSelect
    local tabHighlight = request:data().from
    ?>
    
        <?lsp 
              -- Function to check if the user is allowed access to this page
              -- If the user is not allowed access to view all users and the user
              -- is not of the same company as the user they're viewing, then an 
              -- access denied message will be displayed and no access will be given
            local su=require"sqlutil"
            local sql = selectQueryWhere({"companyname"},"users","Email",userInfo);
            local function opendb() 
                return su.open"file" 
            end
    
            local function execute(cur)
                companynameCheckAccess = cur:fetch()
                return true
            end
            
            local ok,err=su.select(opendb,string.format(sql), execute)
            
            if tonumber(usersession.viewAllUsers) == 0 and companynameCheckAccess ~= usersession.company then
                print("ACCESS DENIED")
            else
            
            ?>
    </head>
    
    <body>
    <div id="new-header">
        <script>
            // Loads navbar from "header.lsp" and sets the user list
            // to active if loaded from user list. Otherwise set the
            // user profile to active in the navbar
        function getActiveTab(){
        return <?lsp if tabHighlight == "list" then print("'#header-userList'") else print("'#header-userProfile'") end?>
        }
        $("#new-header").load("header.lsp", function() {
            $(getActiveTab()).addClass('active');
        });
        </script>
    </div>
    <div class="container" >
        <!-- Generates list of tabs the user is allowed to access. If the user is unable to change other
             user's settings, removes that from the list -->
        <div class="tab">
            <button class="tablinks" onclick="openInfo(event, 'UserInfo')" id="defaultOpen">User Info</button>
            <?lsp if tonumber(usersession.changeUserSettings) == 1 or userInfo == usersession.loggedinas then ?> 
            <button class="tablinks" onclick="openInfo(event, 'ChangeSettings')">Edit User Settings</button> 
            <?lsp end ?>
            
            <button class="tablinks" onclick="openInfo(event, 'UserLogs')">User Logs</button>
        </div>
    
    <!-- Tab content -->
    <?lsp 
             
            local su=require"sqlutil"
            local sql = selectQueryWhere({"username","companyname","passwordexpiry","contactnumber","email","permissionlevel"},"users","Email",userInfo);
            local function opendb() 
                return su.open"file" 
            end
    
            local function execute(cur)
                local name,companyname,passwordexpiry,contactnumber,email,permissionlevel = cur:fetch()?>
                <div id="UserInfo" class="tabcontent">
                    <div class="usernameContainer">
                        <h1><?lsp=name?>
                        <span class="companyContainer"> <?lsp=companyname?> </span></h1>
                        </div>
                    <div class="userImageContainer">
                        <img src="images/iconspngimage.jpg" />
                    </div>
                    <div class="textContainer"> 
                        <!-- If the user hasn't got an associated contact number, print 'none given' -->
                        <h2><i class="fa fa-phone" title="phone">   </i> <?lsp if contactnumber == "" then print"None given" else print(contactnumber) end?></h2><br>
                        <h2><i class="fa fa-envelope" title = "email"></i> <?lsp=email?></h2><br>
                        <h2><i class='fa fa-lock' title = "permission level"> </i> <?lsp=permissionlevel?></h2>
                        </div></div>
                        <?lsp
                return true
            end
            
            
            
            local ok,err=su.select(opendb,string.format(sql), execute)
            
            
            ?>
    
        <div id="ChangeSettings" class="tabcontent">
            <!-- Buttons which relate to opening the modals to change user settings -->
            <button class="settings-btn" id="pass-popup">Change password</button>
            <button class="settings-btn" id="name-popup">Change name</button><br>
            <button class="settings-btn" id="phone-popup">Change phone number</button>
            <button class="settings-btn" id="email-popup">Change Email</button>
            <!-- If the user has root level access, gives them permission to change the access level of the user -->
            <?lsp  if tonumber(usersession.isRoot) == 1 then ?><button class="settings-btn btn-right" id="permission-popup">Change Permission</button> <?lsp end ?>
        </div>
        <div id="UserLogs" class="tabcontent">
            <?lsp -- user logs list code
                local su=require"sqlutil"
                -- Selects all user logs relating to the user
                local sql = selectQueryWhere({"*"},"userlogs","Email",userInfo);
                local function opendb() 
                    return su.open"file" 
                end
            ?>
            <table class="table table-striped" >
                <thead>
                    <!-- Headers for the user logs list -->
                    <th scope="col">user</th>
                    <th scope="col">time</th>
                    <th scope="col">action</th>
                </thead>
                <tbody>
                    <?lsp
                    local function execute(cur)
                        local user,activitytime,action = cur:fetch()
                        while user do
                            ?>
                            <tr> 
                                <!-- Converts the time in the system into one that is formatted to be easily read by the user -->
                                <th> <?lsp=user?> </th><th> <?lsp=(os.date("%c", activitytime))?> </th><th> <?lsp=action ?></th>
                            </tr>
                        <?lsp
                            user,activitytime,action = cur:fetch()
                        end
                        return true
                    end
                    ?>
                    <?lsp
                    local ok,err=su.select(opendb,string.format(sql), execute)
                    ?>
                </tbody>
            </table>
        </div>
    </div> 
        <!-- Start of modals list - These are set as closed and functions are called to 'open' them
                They sit on row 1 of the z plane which essentially means that they are brought to the 
                foreground on open (as the rest of the content is set to 0 on the z plane) -->
        <div class = "setting-modal" id = "change-password">
            <div class="modal-interior">
                <form method="post"><span class="close" id="change-password-close">&times;</span>
                    Password: <br><input type="password" name="passwordCheck" placeholder = "Please enter your password"  required><br>
                    New Password: <br><input type="password" name="password" placeholder = "Enter account&#39;s new password" pattern="(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}" autocomplete="off" title="at least one number and one uppercase and lowercase letter, and at least 8 or more characters" required><br>
                    Confirm New Password: <br><input type="password" name="passwordConfirm" placeholder = "Confirm password" required><br>
                    <input type="submit" value="Change password">
                </form>
            </div>
        </div>
        <div class = "setting-modal" id ="edit-name">
            <div class="modal-interior">
    
            <form method="post"><span class="close" id="edit-name-close">&times;</span>
                Password: <br><input type="password" name="passwordCheck" placeholder = "Please enter your password" required><br>
                Name: <br><input type="text" name="username" placeholder = "Enter new name" required><br>
                <input type="submit" value="Update Name">
            </form></div>
        </div>
        <div class = "setting-modal" id="edit-contact-number">
            <div class="modal-interior">
    
            <form method="post"><span class="close" id="edit-contact-number-close">&times;</span>
                Password: <br><input type="password" name="passwordCheck" placeholder = "Please enter your password" required><br>
                Phone Number: <br><input type="text" name="ContactNumber" placeholder = "Enter new contact number" required><br>
                <input type="submit" value="Update Contact No.">
            </form></div>
        </div>
        <div class = "setting-modal" id ="edit-email">
            <div class="modal-interior">
    
            <form method="post"><span class="close" id="edit-email-close">&times;</span>
                Password: <br><input type="password" name="passwordCheck" placeholder = "Please enter your password" required><br>
                Email: <br><input type="text" name="Email" placeholder = "Enter new email address"><br>
                <input type="submit" value="Update Email">
                <br> Keep in mind that this new value will be used to sign you in
            </form></div>
        </div>
     <div class = "setting-modal" id ="edit-permission">
            <div class="modal-interior">
            <form method="post"><span class="close" id="edit-permission-close">&times;</span>
                Password: <br><input type="password" name="passwordCheck" placeholder = "Please enter your password" required><br>
                Permission Level:<br> <select name="permissionlevel" required>
                <option value=""></option>
    <?lsp
    -- builds list of options for the select statement for user permissions
    local sql
            local su=require"sqlutil" 
            sql=selectQuery({"permissionLevel"},"permissions")
    
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
            
            ?></select><br>
                 <input type="submit" value="Update Permission">
            </form></div>
        </div>
    <script>
        // This code is what functions to open and close the tabs on the page. It was
        // adapted from a tutorial - https://www.w3schools.com/howto/howto_js_tabs.asp
        function openInfo(evt, tabName) {
        // Declare all variables
        var i, tabcontent, tablinks;
    
        // Get all elements with class="tabcontent" and hide them
        tabcontent = document.getElementsByClassName("tabcontent");
        for (i = 0; i < tabcontent.length; i++) {
            tabcontent[i].style.display = "none";
        }
    
    
        // Get all elements with class="tablinks" and remove the class "active"
        tablinks = document.getElementsByClassName("tablinks");
        for (i = 0; i < tablinks.length; i++) {
            tablinks[i].className = tablinks[i].className.replace(" active", "");
        }
    
        // Show the current tab, and add an "active" class to the button that opened the tab
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.className += " active";
        
        } 
        
        document.getElementById("defaultOpen").click();
        
        // start of the modals button onclick listener - It's not as efficient as the
        // adapted tab code, which I could have made use of again, but this
        // method is more intuitive to me
        document.getElementById("pass-popup").onclick = function() {
            document.getElementById('change-password').style.display = "block";
        }
        document.getElementById("name-popup").onclick = function() {
            document.getElementById('edit-name').style.display = "block";
        }   
        document.getElementById("phone-popup").onclick = function() {
            document.getElementById('edit-contact-number').style.display = "block";
        } 
        document.getElementById("email-popup").onclick = function() {
            document.getElementById('edit-email').style.display = "block";
        } 
        document.getElementById("permission-popup").onclick = function() {
            document.getElementById('edit-permission').style.display = "block";
        } 
        
        
        // Gives the close buttons the ability to close the modals
        document.getElementById("change-password-close").onclick = function() {
            document.getElementById('change-password').style.display = "none";
        }
        document.getElementById("edit-name-close").onclick = function() {
            document.getElementById('edit-name').style.display = "none";
        }   
        document.getElementById("edit-contact-number-close").onclick = function() {
            document.getElementById('edit-contact-number').style.display = "none";
        } 
        document.getElementById("edit-email-close").onclick = function() {
            document.getElementById('edit-email').style.display = "none";
        } 
        document.getElementById("edit-permission-close").onclick = function() {
            document.getElementById('edit-permission').style.display = "none";
        } 
        
        // If the window is clicked, checks if one of the modal containers were clicked.
        // If they were, close the corresponding modal
        window.onclick = function(event) {
            if (event.target == document.getElementById('change-password')) {
                document.getElementById('change-password').style.display = "none";
            } 
            if (event.target == document.getElementById('edit-name')) {
                document.getElementById('edit-name').style.display = "none";
            }
            if (event.target == document.getElementById('edit-contact-number')) {
                document.getElementById('edit-contact-number').style.display = "none";
            }
            if (event.target == document.getElementById('edit-email')) {
                document.getElementById('edit-email').style.display = "none";
            }
            if (event.target == document.getElementById('edit-permission')) {
                document.getElementById('edit-permission').style.display = "none";
            }
        }
    
    </script>
    
    
    <?lsp -- START SERVER SIDE CODE
    
    
    if request:method() == "POST" then
        local updateValues = request:data()
        -- builds select query
       local sql = selectQueryWhere({"password"},"users","Email",usersession.loggedinas); 
    
        
            local function execute(cur)
                password = cur:fetch()
                return true
            end
            
            local function opendb() 
                return su.open("file")
            end
            
            local ok,err=su.select(opendb,string.format(sql), execute)
            
            if not ok then 
                response:write("DB err: "..err) 
            end
            -- checks to make sure the password entered matches the one in the database
            if updateValues.passwordCheck == password then 
                -- Checks for two scenarios:
                    -- Checks to see if the password is to be changed. If true, checks to see if the password confirmation
                        -- matches the password
                    -- Else checks to see if the password confirmation check is nonexistant(if left blank would be sent as "", not nil)
                if updateValues.passwordConfirm == nil or updateValues.passwordConfirm == updateValues.password then 
                     
                    
                    local logincheck = updateValues.userSelect
                    -- Flueshes unneeded information that would be also sent in the update query. Does this by setting them to nil
                    updateValues.userSelect = nil
                    local fromPage = updateValues.from
                    updateValues.from = nil
                    updateValues.passwordCheck = nil
                    updateValues.passwordConfirm = nil
                    local su=require"sqlutil"
                    local env,conn = su.open"file"
                    
                    local sql = updateQueryWhere(updateValues,'users', 'Email', userInfo)
                    
                    ok, err = conn:execute(string.format(sql))
                    if ok then 
                        print("User settings updated")
                    else
                        print("SQL update failed ",err)
                    end
                    -- Checks to see if the user's email has changed
                    if updateValues.Email ~= nil then 
                        -- if the email has changed, checks to see if it's the email of the user
                        -- currently logged in. If so, changes the user's setting to match that
                        -- in the user session
                        if logincheck == usersession.loggedinas then
                            usersession.loggedinas = updateValues.Email
                        end
                        ?>
                        <script> // Directs the user to the current page, with the updated email
                        location.href = "usersettings.lsp?from=<?lsp=fromPage ?>&userSelect=<?lsp=updateValues.Email?>";
                        </script> 
                    
                    <?lsp 
                    else
                        ?>
                        <script> // Directs the user back to the page after the updates have been made, so they can
                                 // examine the changes
                        location.href = "usersettings.lsp?from=<?lsp=fromPage?>&userSelect=<?lsp=logincheck?>";
                        </script>
                           
                    <?lsp 
                    end 
                else ?>
                <!-- If the user changing the password enters the password fields in incorrectly, this message is prompted -->
                    <script>alert("Password mismatch")</script> 
                    <?lsp
                end    
            else ?>
            <!-- Alert is displayed if the user enters their password incorrectly when attempting to make changes to user settings -->
                <script>alert("Incorrect password entered")</script> 
                <?lsp
            end
    end
end

    ?>
    </body>
</html>