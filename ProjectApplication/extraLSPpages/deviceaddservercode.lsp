<?lsp -- Server side code used to register device into database to be looked up on device restart
      -- Also emails a specified user the device registration details such as the device IP and the time,
      -- including the user who registered the device
      -- the 'to' has been changed to a generic email address. To test this yourself please input your own email address
      -- The development of this project has not reached a stage where an advanced settings page has been incorporated to 
      -- change this from the UI.
      -- If you change the sender user and password, this will most likely not work. An error message should display the 
      -- actions you should take to lower the required security of the gmail account used.
      -- If gmail is not used and another email provider is used, look up the smtp server that email provider uses
    deviceData = request:data()
    local su=require"sqlutil"
    local env,conn = su.open"file"
    local sql = insertQuery(deviceData,"device")
    
    ok, err = conn:execute(sql)
    if ok then 
        print("Device registered")
        usersession = request:session()
        sql= "INSERT INTO userlogs VALUES('"..usersession.loggedinas.."','"..os.time().."','Registered device - <br> - Model:"..deviceData.deviceModel.." <br> - IP: "..deviceData.deviceIP.." <br> - Company : "..deviceData.companyName.."');"
        local env,conn = su.open"file"
        local ok,err=conn:execute(sql)
        su.close(env,conn)
        -- Mail code intentionally commented out. Feel free to add it using your own email address as receiver if you wish to test it
        --require "socket.mail" -- Load mail library
        --local mail=socket.mail{
        --   shark=ba.create.sharkssl(),
        --   server="smtp.gmail.com",
        --   user="projectservertestemail@gmail.com",
        --   password="X3hLkB0063",
        --}
         
        -- Send email
        --local ok,err=mail:send{
        --   subject="Auto response message",
        --   from='Project Application Server <projectservertestemail1@gmail.com>',
        --   to='Richard <insertnamehere@gmail.com>', 
        --   body= usersession.loggedinas.." registered a new device at "..os.date("%c", os.time()).." Registered device model:"..deviceData.deviceModel.." IP: "..deviceData.deviceIP.." Company : "..deviceData.companyName
        --}

    else
        print("Device registration failed ",err)
    end
?>

