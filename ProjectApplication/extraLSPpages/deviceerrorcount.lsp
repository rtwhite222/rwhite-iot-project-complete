 <?lsp -- Server side code used to look up the number of unresolved errors the specified device contains
        deviceData = request:data()
        local su=require("sqlutil")
        local sql = selectQueryWhereMult({"COUNT(*)"},"deviceerrors",{"deviceIP","resolved"},{deviceData.deviceIP,0})

        local function execute(cur)
            errorCount = cur:fetch()
            print(errorCount)
            return true
        end
        
        local function opendb() 
            return su.open("file")
        end
        local ok,err=su.select(opendb,string.format(sql), execute)
        
        if not ok then 
            response:write("DB err: "..err) 
        end
      ?>