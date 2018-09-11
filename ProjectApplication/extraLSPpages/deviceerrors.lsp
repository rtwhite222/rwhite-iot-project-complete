<!DOCTYPE HTML>
<html>
<!-- Code used to generate errors list to be appended to device list page -->
  <body>
            <?lsp
        local su=require("sqlutil")
        -- Code used to find all errors associated with the device
        local sql = selectQueryWhereMult({"COUNT(*)"},"deviceerrors",{"deviceIP","resolved"},{"172.20.20.107",0})

        local function execute(cur)
            errorCount = cur:fetch()
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
        <!-- It's easiest to build the error list on this page to be pasted in the device later
        It also allows for a slightly more 'updated' version of the error lost as it's loaded on 
        clicking on the device's error logs tab and not on device connect. This means it can also be 
        refreshed on clickin on the tab again -->
    <div class="table-container">
        <table class="table-users table" border="0">
            <tbody>
            <?lsp 
                deviceData=request:data()
                local su=require"sqlutil"
                local sql = selectQueryWhereMult({"error","errortime"},"deviceerrors",{"deviceIP","resolved"},{deviceData.deviceIP,0})
                
                local function opendb() 
                    return su.open"file" 
                end
                
                local function execute(cur)
                    local errorType, errorTime,ptid = cur:fetch()
                    if not errorType then ?>
                    This device has no unresolved errors
                    <?lsp else
                        ?>
                        <tr class='clickable-row nohover'><td>Error Type</td><td>Time</td><td align='center'>Resolve Error</td></tr>
                    <?lsp end
                    while errorType do
                    ?>
                    <tr class='clickable-row nohover' id="row-<?lsp=errorTime?><?lsp=deviceData.ptid?>">

                        <td>
                            <?lsp=errorType?> <br>
                        </td>
                        <td>
                            <?lsp=(os.date("%c", errorTime))?>
                        </td>
                        <td align='center'>
                            <button type="submit" onclick="errorResolve('<?lsp=deviceData.deviceIP?>','<?lsp=errorTime?>','<?lsp=deviceData.ptid?>')">resolve</button>
                            </td>
                        </tr> 

                    <?lsp
                        errorType, errorTime = cur:fetch()
                    end
                    return true
                end
                        
                local ok,err=su.select(opendb,string.format(sql), execute)
                        ?>
                    </tbody>
            </table>
        </div>

  </body>

    
  </html>