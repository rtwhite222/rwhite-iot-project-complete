<!DOCTYPE html>
<!-- User List Page - This page is designed for users view other users in the system and acts a means of accessing
     their user profile page -->
<html>
    <head>
        <link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
        <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
        <script src="https://use.fontawesome.com/1e803d693b.js"></script>
        <link rel="stylesheet" href="cssfiles/userlist.css?version=25">
        <meta name=viewport content="width=device-width, initial-scale=1" />
        <script>
        $(document).ready(function($) {
            $(".clickable-row").click(function() {
                window.location = $(this).data("href");
            });
        });
        // jQuery script which assigns an onclick callback on each div assigned to a user
        // to direct the browser to the user's profile page
        </script>
    </head>
    <body>
        <div id="new-header">
            <script>
                // Loads navbar from "header.lsp" and sets the user list
                // to active
            $("#new-header").load("header.lsp", function() {
                $('#header-userList').addClass('active');
            });
            </script>
        </div>
        
        <div class="container">
            <div class="search-container">
            <?lsp -- checks if the user has logged in, if not, forces them to login page
                usersession = request:session()
                if not usersession then response:forward"index.lsp" end
                    function checkLogin()
                        if not usersession.loggedin then
                            request:session(false)
                            response:forward"index.lsp"
                        end
                    end
                checkLogin()
                -- if user has permission to view all users, gives them the ability to search the user list by company
                if tonumber(usersession.viewAllUsers) == 1 then ?>
                    <form method = "post">
                    <select name="companyName" >  <option selected disabled>Select a company</option>
                    <?lsp 
                    local su=require"sqlutil"
                    local sql = selectQuery({"companyName"},"company")
                    local function execute(cur)
                        local company = cur:fetch()
                        while company do
                           ?>
                           <option value='<?lsp=company?>'><?lsp=company?></option>
                           <?lsp
                           company = cur:fetch()
                        end
                        return true
                    end
                    
                    local function opendb() 
                        return su.open"file" 
                    end
                    
                    local ok,err=su.select(opendb,string.format(sql), execute)
                    ?>
                    </select>
                    <input type="submit" value = "Search by Company">
                </form>
            
            <?lsp  -- end of company search code
            end ?>
            </div>
            <!-- builds user list from server side database access -->
            
        	<div class="row">
                <div class="panel panel-default user_panel">
                    <div class="panel-heading">
                        <h3 class="panel-title">User List</h3>
                    </div>
                    <div class="panel-body">
        				<div class="table-container">
                            <table class="table-users table" border="0">
                                <tbody>
                                <?lsp 
                                
                                local su=require"sqlutil"
                                local sql
                                -- Multiple options (in order of select statement):
                                    -- If user has permission to view all users, views all users
                                    -- If user has permission to view all users and is searching for a particular company
                                    --      then only that company will be shown
                                    -- If user doesn't have permission to view all users, only show users of the
                                    --      company that they belong to
                                if (tonumber(usersession.viewAllUsers) == 1) then
                                    sql = selectQuery({"username","companyname","Email","permissionlevel"},"users")
    
                                    if request:method() == "POST" and request:data().companyName then
                                        sql = selectQueryWhere({"username","companyname","Email","permissionlevel"}
                                        ,"users","CompanyName", request:data().companyName)
                                    trace(sql)
                                    end
                                else 
                                    sql = selectQueryWhere({"username","companyname","Email","permissionlevel"}
                                    ,"users","CompanyName", usersession.company)
                                end
                                
                                local function opendb() 
                                    return su.open"file" 
                                end
                                    
                                local function execute(cur)
                                    local user,company,Email,permissions = cur:fetch()
                                    while Email do
                                        -- Builds href through current location and unique email address of the user
                                        -- so the link directs to the correct user's page
                                        ?>
                                        
                                    <tr class='clickable-row' data-href='usersettings.lsp?from=list&userSelect=<?lsp=Email?>'>
                                        <td width='10' align='center'>
                                            <i class='fa fa-2x fa-user fw'></i>
                                        </td>
                                        <td>
                                            <!-- builds parts of user list through server side data accessed -->
                                            <?lsp=user?> <br>
                                        </td>
                                        <td>
                                            <?lsp=permissions?> 
                                        </td>
                                        <td align='center'>
                                            Company<br><small class='text-muted'><?lsp=company ?></small>
                                        </td>
                                    </tr> 
                                        <?lsp
                                       user,company,Email,permissions = cur:fetch()
                                    end
                                    return true
                                end
                                
                                local ok,err=su.select(opendb,string.format(sql), execute)
                                ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
        	</div>
        </div>
    </body>
</html>
