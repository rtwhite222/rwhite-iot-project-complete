<?lsp  -- Server code used to insert an unresolved test error into the database, with the current time and device IP included 
deviceData = request:data()
sql="INSERT INTO deviceerrors VALUES('"..deviceData.deviceIP.."','Test Error',"
sql = sql .. os.time()..",0);"
su=require"sqlutil" 
   local env,conn = su.open"file"
  ok, err = conn:execute(sql)
    if ok then 
        print("Error created")
    else
        trace("Error create failed ", err)
    end
    
    su.close(env,conn)
?>