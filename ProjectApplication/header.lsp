
<?lsp usersession = request:session()

        if not usersession then response:forward"index.lsp" end
        function checkLogin()
            if not usersession.loggedin then
                print "not logged in"
                request:session(false)
                response:forward"index.lsp"
            end
        end
checkLogin()
?>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>


<nav class="navbar navbar-inverse">
  <div class="container-fluid">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#myNavbar">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>                        
      </button>
      <a class="navbar-brand" >CHAMELEON</a>
    </div>
    <div class="collapse navbar-collapse" id="myNavbar">
      <ul class="nav navbar-nav">
        <li id="header-deviceList"><a href="devicelist.lsp">Connected Devices</a></li>
                <li id="header-userList"><a href="userlist.lsp">User List</a></li>
        <?lsp if tonumber(usersession.addNewDevice) + tonumber(usersession.addCompanyUsers) + tonumber(usersession.addNewCompany) >= 2 then ?><li class="dropdown">
          <a class="dropdown-toggle" data-toggle="dropdown" id="header-addNew">Add New...<span class="caret"></span></a>
          <ul class="dropdown-menu"><?lsp end ?>
        <?lsp if tonumber(usersession.addNewDevice) == 1 then ?><li id="header-addDevices"><a href="adddevice.lsp">Add New Device</a></li><?lsp end ?>
        <?lsp if tonumber(usersession.addCompanyUsers) == 1 then ?><li id="header-addNewUser"><a href="adduser.lsp">Add New User</a></li><?lsp end ?>
        <?lsp if tonumber(usersession.addNewCompany) == 1 then ?><li id="header-addNewCompany"><a href="addcompany.lsp">Add New Company</a></li><?lsp end ?>
          <?lsp if tonumber(usersession.addNewDevice) + tonumber(usersession.addCompanyUsers) + tonumber(usersession.addNewCompany) >= 2 then ?></ul>
        </li>
<?lsp end ?>
      </ul>
        <ul class="nav navbar-nav navbar-right">
            <li id="header-userProfile"><a href="usersettings.lsp?from=profile&userSelect=<?lsp=usersession.loggedinas ?>"><span class="glyphicon glyphicon-user"></span> My Profile</a></li>
            <li><a href="index.lsp"><span class="glyphicon glyphicon-log-in"></span> Log Out</a></li>
        </ul>
  </div>
</nav>