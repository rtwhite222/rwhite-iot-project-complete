<!DOCTYPE html>
<?lsp deviceData = request:data() ?>
<body>
Device Run Time: <select name="deviceGraphSelect" id = "deviceRunSelect<?lsp=deviceData.ptid?>">
<?lsp 
    -- Server side code used to generate dropdown select statement containing device reading times
        
        local su=require"sqlutil"
        local sql=selectQueryWhere({"DISTINCT readingstarttime"},"devicereadings","deviceIP",deviceData.deviceIP)
        local function execute(cur)
            local runTime = cur:fetch()
            while runTime do
               ?>
               <option value='<?lsp=runTime?>'><?lsp=(os.date("%c", runTime))?></option>
               <?lsp
               runTime = cur:fetch()
            end
            return true
        end
        
        local function opendb() 
            return su.open"file" 
        end
        
        local ok,err=su.select(opendb,string.format(sql), execute)
        
        
        ?>
        </select></body>
        
