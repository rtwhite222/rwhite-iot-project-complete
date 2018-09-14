<!DOCTYPE html>
<!-- Add Company Page - This page is designed for users to fill out a form to add a new company into the system -->
<html>
    <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1">
        <title>Login Page</title>
        <link rel="stylesheet" href="cssfiles/inputForms.css?version=25">
        <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
        <meta name=viewport content="width=device-width, initial-scale=1" />
    </head>

    <body>
        <!-- Loads navbar on page and adds active class to add new company page on the navbar, highlighting it -->
        <div id="new-header">
            <script>
                $("#new-header").load("header.lsp", function() {
                    $('#header-addNewCompany').addClass('active');
                });
            </script>
        </div>
        
        <div class="container">
            <div class="content-container-user-company">
            <!-- Form used to create company  -->
            <form method="post">
                Company Name * <br><input type="text" name="CompanyName" required><br>
                Street<br><input type="text" name="street"><br>
                City<br><input type="text" name="city"><br>
                Postcode<br><input type="text" name="postc"><br>
                Company Email * <br><input type="text" name="email" required><br>
                Company Phone * <br><input type="text" name="ContactNumber" required><br> 
                <input type="submit" value="Create Company Profile">
            </form>
    
    
        
            <?lsp -- START SERVER SIDE CODE
                
                -- Checks to see if the user is logged in. If not, directs them to login page
                usersession = request:session()
                if not usersession then response:forward"index.lsp" end
                function checkLogin()
                    if not usersession.loggedin then
                        print "not logged in"
                        response:forward"index.lsp"
                    end
                end
                checkLogin()
                
                -- Checks to see if a post method was used to submit data
                if request:method() == "POST" then
                    local companyTable = request:data()
                    local su=require"sqlutil"
                    local env,conn = su.open"file"
                
                    -- Constructs insert query used to create company
                    local sql = insertQuery(companyTable,"company")
                    -- Carries out sql query
                    ok, err = conn:execute(sql)
                    if ok then 
                                ?>
                		<script>
                		    // Informs user that the company has been created
                		    alert("New company created")
                		</script>
                		<?lsp
                		-- Inserts the company creation into the user's logs
                         local sql= "INSERT INTO userlogs VALUES('"..usersession.loggedinas.."','"..os.time()
                                    .."','Created new company - ".. companyTable.CompanyName .."');"
                            local env,conn = su.open"file"
                            local ok,err=conn:execute(sql)
                            su.close(env,conn)
                        
                            if not ok then 
                                response:write("DB err: "..err) 
                            end
                    else
                        ?>
                        <script>
                            // Alert informing the company creation has failed
                        alert("New company create failed. Make sure that the company is "+
                                "not already in the system. Otherwise, please try again.")
                        </script>
                        <?lsp
                    end
                    su.close(env,conn)
                   
                end
            ?>
            </div>
        </div>
    </body>
</html>
