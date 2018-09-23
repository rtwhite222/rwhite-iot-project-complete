<?lsp -- Code used to log the changing of a device's settings
    deviceData = request:data()
    local su=require"sqlutil"
    local sql = deleteQueryWhere("device","deviceIP",deviceData.deviceIP)
    local env,conn = su.open"file"
    local ok,err=conn:execute(sql)
    if ok then print("The device's "..deviceData.setting.." has been set to "..deviceData.value) end
    su.close(env,conn)
    usersession = request:session()
        sql= "INSERT INTO userlogs VALUES('"..usersession.loggedinas.."','"..os.time().."','Changed device settings - <br> - Model:"..deviceData.deviceModel.." <br> - IP: "..deviceData.deviceIP.." <br> - set ".. deviceData.setting ..": "..deviceData.value.."');"
        local env,conn = su.open"file"
        local ok,err=conn:execute(sql)
        su.close(env,conn)
?>