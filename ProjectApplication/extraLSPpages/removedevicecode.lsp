<?lsp -- Code used to delete the device from the database. Device restart required to move it back into discovery page
    deviceData = request:data()
    local su=require"sqlutil"
    local sql = deleteQueryWhere("device","deviceIP",deviceData.deviceIP)
    local env,conn = su.open"file"
    local ok,err=conn:execute(sql)
    if ok then print"The device has been removed. Restart it for the changes to take effect" end
    su.close(env,conn)
    usersession = request:session()
        sql= "INSERT INTO userlogs VALUES('"..usersession.loggedinas.."','"..os.time().."','Deleted device - <br> - Model:"..deviceData.deviceModel.." <br> - IP: "..deviceData.deviceIP.."');"
        local env,conn = su.open"file"
        local ok,err=conn:execute(sql)
        su.close(env,conn)
?>