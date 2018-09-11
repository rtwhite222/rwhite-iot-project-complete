
<?lsp  -- Server side code used to generate test device outputs. Used through inserting randomly generated values
       -- for 60 iterations, all with the same device start time as this and the IP are the composite primary key
    local sql
    local startTime = os.time()
    local deviceData=request:data()
        local su=require"sqlutil"
    local env,conn = su.open"file"
    for value = 1, 60 do
    sql="INSERT INTO devicereadings VALUES('"..deviceData.deviceIP.."',"..math.random(800,1600)..","..startTime..","..value..");"
      ok, err = conn:execute(sql)
    end

?>