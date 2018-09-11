 <?lsp
 -- Server side code used to resolve errors of device depending on the error time and the IP it's associated with
 deviceData=request:data()
    local su=require("sqlutil")
    local env,conn = su.open"file"

    local sql = updateQueryWhereMult({resolved = 1},"deviceerrors", {"deviceIP","errortime"},{deviceData.deviceIP,deviceData.errorTime})
    local function execute(cur)
        errorCount = cur:fetch()
        print(errorCount)
        return true
    end
        
    local function opendb() 
        return su.open("file")
    end
    ok, err = conn:execute(string.format(sql))
    if ok then 
        print("User settings updated")
    else
        print("SQL update failed ",err)
    end

?>