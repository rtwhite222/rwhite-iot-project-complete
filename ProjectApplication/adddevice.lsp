<!DOCTYPE html>
<!-- Add Device Page - This page is designed for users to add new devices to the system -->
 
<html>
    <head>
        <link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
        <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>
        <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
        <link rel="stylesheet" href="cssfiles/devicepages.css?version=23">
        <script src="https://use.fontawesome.com/1e803d693b.js"></script>
        <meta charset="UTF-8" />
        <title>Devices Page</title>
        <meta name=viewport content="width=device-width, initial-scale=1" />
        <script src="/rtl/smq.js"></script>
        <script src="/rtl/jquery.js"></script>
        
        <?lsp
    -- Code used to make sure the user has signed in correctly
    usersession = request:session()
    if not usersession then response:forward"index.lsp" end
    function checkLogin()
        if not usersession.loggedin then
            print "not logged in"
            response:forward"index.lsp"
        end
    end
    checkLogin()
    -- If user doesn't have permission to access this page, don't allow the functionality,
    -- Otherwise allow them access
    if (tonumber(usersession.addNewDevice) == 0) then
        print("ACCESS DENIED") 
        else
    ?>
        
    <script>
        
        // Script used to build the allowed companies that the user is able to register a device under
        // If given permission for all companies, selects them all, otherwise only select the company
        // the user is registered under
        function getCompanyName(){
            html = ""
            
            <?lsp
             if tonumber(usersession.viewAllDevices) == 1 then
             local su=require"sqlutil"
                    local sql=string.format("companyName FROM company")
                    
                    local function execute(cur)
                        local company = cur:fetch()
                        while company do 
                        ?>
                           html+="<option value='<?lsp=company ?>'><?lsp=company?></option>"
                           <?lsp 
                           company = cur:fetch()
                        end
                        return true
                    end
                    
                    local function opendb() 
                        return su.open"file" 
                    end
                    
                    local ok,err=su.select(opendb,string.format(sql), execute)
                    
                    
            else ?>
             html+="<option value=<?lsp=usersession.company?>><?lsp=usersession.company?></option>"        
            <?lsp end ?>
            
            return html
        }
            // Code adapted from Mako Server example - cleans code to ensure
            // no possibility of scripting attacks
        function escapeHtml(unsafe) {
            return unsafe
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#039;");
        };
        
        // Gets company the signed in user is part of
        function getCompany(){
            var company = "<?lsp=usersession.company?>"
        return company
        };
         // If no devices are connected to the registry topic, print this message in place of the device list
        function printNoDevs() {
            $("#nodev").html('<h2 align="center">There are currently no devices connected</h2><br><h3 align="center">'+
            'Please make sure that the device you wish to register has an internet connection</h3>').show();
        };
        // Start of main SMQ code
        $(function() {
        // Number of connected devices
            var connectedDevs=0;
        
            // If browser is unable to support websockets, stops here
            if(! SMQ.websocket() ) {
                $('#nodev').html('<h2>Please update your browser or install one which supports websockets</h2>');
                return; 
            }
            
            // Connects to server side broker
            var smq = SMQ.Client(SMQ.wsURL("/Server-Broker-Test8/"));
        
            smq.onmsg=function(data,ptid,tid,subtid) {
                console.log("Received unexpected data:", data,", from",ptid,", tid=",tid,
                            ", subtid=",subtid);
                console.log("  data string:",SMQ.utf8.decode(data))
            };
        
            // On WebSocket close, removes all device data & gives a reason for disconnect to be fixed
            smq.onclose=function(message,canreconnect) {
                connectedDevs=0;
                $("#nav").empty();
                $("#devices").empty();
                $('#nodev').html('<h2>Disconnected!</h2><p>'+(message ? message : '')+'</p>').show();
                if(canreconnect) return 3000;
            };
            // On initial startup, prints that no devices are connected while waiting for devices to connect
            smq.onconnect=printNoDevs();
        
            // On reconnect of browser, tells devices it's back to get their information again
            smq.onreconnect=function() {
                printNoDevs(); 
                smq.publish("Hello", "nocompany");
            };
            
            // On transmission of device's information, builds the device profile in the device registration list
            function devInfo(info, ptid) {
                var html=        
                ("<tr class='clickable-row nohover' id = 'dev-"+ptid+"' data-href='usersettings.lsp'>"+
                    "<td width='10' align='center'>"+
                        
                    "</td>"+
                    "<td>"+
                        escapeHtml(info.devname)+"<br>"+
                    "</td>"+
                    "<td>"+
                        escapeHtml(info.ipaddr)+
                    "</td>"+
                    "<td align='center' class='row-format'>"+
                        "Register to company:   <select id='companyInput"+ptid+"'>"+getCompanyName()+"</select>"+
                        "<button class='submit-btn' type = 'submit' id = 'submit"+ptid+"'>Register Device</button>"+
                    "</td>"+
                "</tr> ");
                $("#devicesList").append(html);
                
                // On press of register device button, the device is sent the registration information
                // and the server is given the device information to store for the device's next connection
                // The device is removed from all registation pages currently connected
                $("#submit"+ptid).click(function(ev) {
                    var message = '#dev-'+ptid;
                    smq.publish($("#companyInput"+ptid).val()+"\0",ptid);
                    smq.publish(message,"deviceremove")
                    $.ajax({
                      type: "POST",
                      url: "extraLSPpages/deviceaddservercode.lsp",
                      data: {deviceModel: info.devname,companyName: $("#companyInput"+ptid).val(),deviceIP:info.ipaddr},
                    success: function(output) {
                          alert(output);
                          if(--connectedDevs == 0)
                        printNoDevs();
                      }
                    });
                    
                });
                // Used to observe if a device disconnects - if so, removes the device's information.
                smq.observe(ptid, function() {
                    $('#dev-'+ptid).remove();
        
                    if(--connectedDevs == 0)
                        printNoDevs();
                });
                // If a new device connects and the number of devices is changed from 0 to 1, 
                // hides the message displaying no device connected to the discovery queue
                if(++connectedDevs == 1) {
                    $("#nodev").hide(); 
                }
            } //devInfo
            
            
            //Devices that connect after browser has already connected- Sends device info
            smq.subscribe("nocompany", {"datatype":"json", "onmsg":devInfo});
            // If response message is sent from device to this browser, builds the device info sent
            smq.subscribe("self", {"datatype":"json", "onmsg":devInfo});
            // On message, removes the device information from the list
            smq.subscribe("deviceremove", {"datatype":"text","onmsg":function(message,ptid) { 
                    $(message).remove()
                }
            });
        
            // Message indicating the browser has connected, prompting devices to send their info
            smq.publish("Hello", "discovery");
        
        });
    
        </script>
    </head>
<body>
<div id="new-header"><!-- Loads navbar and sets device discovery page to active -->
    <script>
    $("#new-header").load("header.lsp?version=9", function() {
        $('#header-addDevices').addClass('active');
    });
    </script>
</div>


  <div class="container">
	<div class="row">
	     <!-- Container for devices list -->
        <div class="panel panel-default user_panel">
            <div class="panel-heading">
                
                <h3 class="panel-title">Devices list</h3>
            </div>
            <div id="nodev">
                <h2>Connecting....</h2>
            </div>
            <div class="panel-body">
				<div class="table-container" >
                    <table class="table-users table"   border="0">
                        <tbody id = "devicesList" >
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

	</div>
</div>
</body>
</html>
<?lsp end -- ends the if statement for if the user is allowed access to the page
?>
