<!DOCTYPE html>
<!-- Device list page - This page is designed to allow the browser to connect to and 
     change settings of devices currently connected to the system. This includes changing pins,
     viewing device settings, statistics (currently not implemented device side),
     error logs (currently not implemented device side). Functionality to be included: current
     device run values -->

    <head>
        <script type="text/javascript" src="https://canvasjs.com/assets/script/canvasjs.min.js"></script>
        <link href="//maxcdn.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css" rel="stylesheet">
        <link rel="stylesheet" href="cssfiles/devicepages.css?version=41">
        <meta charset="UTF-8" />
        <title>Devices Page</title>
        <meta name=viewport content="width=device-width, initial-scale=1" />
        <script src="/rtl/smq.js"></script>
        <script src="/rtl/jquery.js"></script>
    
        <script>
            <?lsp
                usersession = request:session()
                
                if not usersession then response:forward"index.lsp" end
                function checkLogin()
                    if not usersession.loggedin then
                        print "not logged in"
                        response:forward"index.lsp"
                    end
                end
                checkLogin()
            ?>
            // This code has aspects adapted from the Mako Server example
            // found at https://simplemq.com/m2m-led/
            // In particular, the builder functions for the LEDs, the escapeHtml function, the temp function
            
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
            // Code used to make LEDs was adapted from Mako Server example:
            // 
            /////////////////////////////////////////////MAKE LEDS ////////////////////////////////
            function mkLedName(name) {
                return '<td>'+name+'</td>';
            }
            
            function mkLed(ptid,ledId,color,on) {
                return '<td><div id="led-'+ptid+ledId+'" class="led'+
                    (on ? '' : ' led-off')+'"></div></td>';
            }
            
            function mkLedSwitch(ptid,ledId,on) {
            var ledswitch = ""
             <?lsp if tonumber(usersession.changeDeviceSettings)==1 then ?>
                ledswitch =
                    '<td>'+
                    '<div class="onoffswitch">'+
                    '<input type="checkbox" name="onoffswitch" class="onoffswitch-checkbox" id="switch-'+
                    ptid+'-'+ledId+'" '+(on ? "checked" : "")+'/>'+
                    '<label class="onoffswitch-label" for="switch-'+ptid+'-'+ledId+'">'+
                    '<span class="onoffswitch-inner"></span>'+
                    '<span class="onoffswitch-switch"></span>'+
                    '</label>'+
                    '</div>'+
                    '</td>';
                    <?lsp end ?>
                return ledswitch;
            } // If user doesn't have permission to change device settings, remove ability to change LED state
              // otherwise build the switch
            
            function temp2html(temp) {
                temp /= 10;
                return "Temperature: " + temp + "  &#x2103; <span>(" + 
                    Math.round(temp*9/5+32) + " &#x2109; )</span>";
            } // displays temp (which needs to be scaled by a factor of 10 as this is how the device sends it) in both celsius and fahrenheit
            //////////////////////////////////////////////////////////////////////////////////////////////
            function torque2html(torque) {
                return "Torque: " + torque + " N \u22C5 m "
            }
            // Displays a string concatenating torque to its recommended SI units of Nm. Rest of these functions are similar
            function runtime2html(runtime) {
            
                return "Run time: " + runtime + "s"
            }
            // If no devices are connected, print this message in place of the device list
            function printNoDevs() {
                $("#nodev").html('<h2 align="center">There are currently no devices connected</h2>').show();
            };
            
            
            
            // Posts to server to resolve the given error using AJAX
            function errorResolve(ipaddr, errorTimes,ptid) {
            $.ajax({
                    type: "POST",
                    url: "extraLSPpages/deviceerrorupdate.lsp",
                    data: {deviceIP: escapeHtml(ipaddr), errorTime: errorTimes},
                    success: function(output) {
                        $("#row-"+errorTimes+ptid).remove();
                        errorCount(ipaddr,ptid)
                    }
                });
            } 
            
            // Post to server asking for the count of errors associated with the device. Sets the warning light on
            // if there is at least one error, otherwise makes it hidden
            function errorCount(ipaddr,ptid){
                $.ajax({
                    
                    type: "POST",
                    url: "extraLSPpages/deviceerrorcount.lsp",
                    data: {deviceIP: escapeHtml(ipaddr)},
                    success: function(output) {
                        if(output > 0){
                            $('#device-warning-'+ptid).removeClass("white-warning").addClass("red-warning");
                        }
                        else{
                            $('#device-warning-'+ptid).removeClass("red-warning").addClass("white-warning");
                            $("#deviceLogs-"+ptid).html("This device has no unresolved errors");
                        }
                    }
                });
            
            }
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
            
                // On WebSocket close, removes all device data & gives a reason for disconnect to be fixed
                smq.onclose=function(message,canreconnect) {
                    connectedDevs=0;
                    $("#nav").empty();
                    $("#devices").empty();
                    $("#devicesList").empty();
                    $('#nodev').html('<h2>Disconnected!</h2><p>'+(message ? message : '')+'</p>').show();
                    if(canreconnect) return 3000;
                };
            
                // On initial startup, prints that no devices are connected while waiting for devices to connect
                smq.onconnect=printNoDevs();
                
                // On device message of its parameters, builds the device profile browser side
                function devInfo(info, ptid) {
                    var html=        
                    ("<tr class='clickable-row' id = 'device-"+ptid+"'>"+
                        "<td width='10' align='center'>"+
                            "<i class='fa fa-2x fa-warning fw white-warning' id='device-warning-"+ptid+"'></i>"+   
                        "</td>"+
                        "<td>"+
                            escapeHtml(info.devname)+"<br>"+
                        "</td>"+
                        "<td>"+
                            escapeHtml(info.ipaddr)+
                        "</td>"+
                        "<td align='center'>"+
                            "Product registered to:<br><small class='text-muted'>"+escapeHtml(info.company)+"</small>"+
            
                    "</tr> ");
                    
                    $("#devicesList").append(html);
                    
                    // Counts number of errors to see if the device needs the warning light
                    errorCount(info.ipaddr,ptid);
                    
                    // Puts the device contents into a container div, to be made visible on button click
                            var tablisthtml=        
                        ('<div class="tab" id = "deviceContents-'+ptid+'">'+
                            '<button class="tablinks active" id ="deviceInfoTab-'+ptid+'">Device Info</button>'+
                            '<button class="tablinks" id ="deviceStatisticsTab-'+ptid+'">Device Statistics</button>'+
                            '<button class="tablinks" id ="deviceRunParamsTab-'+ptid+'">Device Parameters</button>'+
                            '<button class="tablinks" id ="deviceLogsTab-'+ptid+'">Error Logs</button>'+
                            '<button class="tablinks backtab" id ="backtab-'+ptid+'">Go back</button>'+
                        '</div>'+
                        '<div id="deviceInfo-'+ptid+'" class="tabcontent">'+
                        '</div>'+
                        '<div id="deviceStatistics-'+ptid+'" class="tabcontent">'+
                        '</div>'+
                        '<div id="deviceRunParams-'+ptid+'" class="tabcontent">'+
                        '</div>'+
                        '<div id="deviceLogs-'+ptid+'" class="tabcontent">'+
                        '</div>')
                    $("#deviceSettingInjection").append(tablisthtml);
                    
                    
                    // Hides contents of device until needed
                    $("#deviceContents-"+ptid).hide();
                    
                    // Shows device information and built device tab
                    $("#deviceInfoTab-"+ptid).click(function(ev) {
                        $("#deviceInfo-"+ptid).show();
                        $("#deviceStatistics-"+ptid).hide();
                        $("#deviceRunParams-"+ptid).hide();
                        $("#deviceLogs-"+ptid).hide();
                        $("#deviceInfoTab-"+ptid).removeClass("").addClass("active");
                        $("#deviceStatisticsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceRunParamsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceLogsTab-"+ptid).removeClass("active").addClass("");
                        
                    });
                    // Div that will contain the device graph and graph search
                    devicetabhtml ='<div id = "graph-options-'+ptid+'"></div>';
                    devicetabhtml+= '<div id = "deviceStatisticsGraph-'+ptid+'"><br><h2 align="center">No device reading selected</h2><br><h3 align="center">'+
                                    'Choose a time from the list to view the readings</h3></div>';
                    $("#deviceStatistics-"+ptid).html(devicetabhtml);
                    
                    // On click of device statistics tab, performs a database search for the device's run list and creates a search bar
                    $("#deviceStatisticsTab-"+ptid).click(function(ev) {
                        $.ajax({
                          type: "POST",
                          url: "extraLSPpages/devicegraphselect.lsp",
                          data: {deviceIP: escapeHtml(info.ipaddr), ptid: ptid},
                          
                        success: function(output) {
                              $("#graph-options-"+ptid).html(output);
                              var devicebutton ='<button class="submit-btn" type = "submit" id = "deviceRunSelectbtn'+ptid+'">View Readings</button></div>';
                              $("#graph-options-"+ptid).append(devicebutton);
                              // On click of the search bar, performs a database search for the device's run settings corresponding to the selected time
                              // and builds the graph to be posted below the search bar
                              $("#deviceRunSelectbtn"+ptid).click(function(ev) {
                                    $.ajax({
                                        type: "POST",
                                        url: "extraLSPpages/graphload.lsp",
                                        data: {deviceIP: escapeHtml(info.ipaddr), timeofrun: $("#deviceRunSelect"+ptid).val()},
                                        success: function(output) {
                                            $("#deviceStatisticsGraph-"+ptid).html(output);
                                        }
                                        });
                                });
                          }});
                        // Show device statistics tab and closes the rest
                        $("#deviceInfo-"+ptid).hide();
                        $("#deviceStatistics-"+ptid).show();
                        $("#deviceRunParams-"+ptid).hide();            
                        $("#deviceLogs-"+ptid).hide();
                        $("#deviceInfoTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceStatisticsTab-"+ptid).removeClass("").addClass("active");
                        $("#deviceRunParamsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceLogsTab-"+ptid).removeClass("active").addClass("");
                        
            
                    });
                    // On click shows device's error logs and hides other tabs
                    $("#deviceLogsTab-"+ptid).click(function(ev) {
                        $("#deviceInfo-"+ptid).hide();
                        $("#deviceStatistics-"+ptid).hide();
                        $("#deviceRunParams-"+ptid).hide();
                        $("#deviceLogs-"+ptid).show();
                        $("#deviceInfoTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceStatisticsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceRunParamsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceLogsTab-"+ptid).removeClass("").addClass("active");
                        
                            // Performs server search create list of most up to date errors
                            $.ajax({
                          type: "POST",
                          url: "extraLSPpages/deviceerrors.lsp",
                          data: {deviceIP: escapeHtml(info.ipaddr), ptid: ptid},
                        success: function(output) {
                              $("#deviceLogs-"+ptid).html(output);
                          }
                        });
                    });
                    
                    // Shows run parameters tab - currently holding the information used to generate errors, device runs and the button to 
                    // disconnect the device
                    $("#deviceRunParamsTab-"+ptid).click(function(ev) {
                        $("#deviceInfo-"+ptid).hide();
                        $("#deviceStatistics-"+ptid).hide();
                        $("#deviceRunParams-"+ptid).show();
                        $("#deviceLogs-"+ptid).hide();
                        $("#deviceInfoTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceStatisticsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceRunParamsTab-"+ptid).removeClass("").addClass("active");
                        $("#deviceLogsTab-"+ptid).removeClass("active").addClass("");
                    });
                    
                    // On click of device in main list, shows its information and hides the list container
                    $("#device-"+ptid).click(function(ev) {
                        $("#devicesListContainer").hide();
                        $("#deviceContents-"+ptid).show();
                        $("#deviceInfo-"+ptid).show();
                    });
                    
                    // On back button from the device's list, closes whatever tab the user is on, resets the 
                    // highlighted tab on next showing (if no page reset) and displays the devices list again
                    $("#backtab-"+ptid).click(function(ev) {
                        $("#devicesListContainer").show();
                        $("#deviceContents-"+ptid).hide();
                        $("#deviceInfo-"+ptid).hide();
                        $("#deviceStatistics-"+ptid).hide();
                        $("#deviceRunParams-"+ptid).hide();
                        $("#deviceLogs-"+ptid).hide();
                        $("#deviceInfoTab-"+ptid).removeClass("").addClass("active");
                        $("#deviceStatisticsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceRunParamsTab-"+ptid).removeClass("active").addClass("");
                        $("#deviceLogsTab-"+ptid).removeClass("active").addClass("");
                        
                    });
                    
                    // Device information sent from the device is built on this device info tab. Built by adapting the Mako Server tutorial
                    var devicetabhtml='<div id="dev-'+ptid+'">'; 
                    devicetabhtml+='<div class="device-reading-container"><h1>'+(escapeHtml(info.devname))+'<span class ="right-align-span">'+escapeHtml(info.ipaddr)+'<span></h1></div>'
                    devicetabhtml += '<div class ="device-gpio-container"><table>';
                    //Loop over all LEDS and create a TR element for each LED
                    var leds=info.leds;
                    for(var i=0 ; i < leds.length; i++) {
                        // TR contains: TD for name + TD for LED + TD for LED on/off switch
                        devicetabhtml += 
                                        ('<tr class = "nohover">' + mkLedName(leds[i].name) + 
                                            mkLed(ptid, leds[i].id, leds[i].color,leds[i].on) +
                                            mkLedSwitch(ptid, leds[i].id, leds[i].on) +
                                        '</tr>');
                    }
                   devicetabhtml += '</table></div>';
                     
                     
                     // Current values are not used, set to 0 to be adapted in later possible versions

            
                    
            
                    devicetabhtml+= '<div class = "readout-container" >'
                        devicetabhtml+='<div class="device-reading" id="temp-'+ptid+'">'+temp2html(info.temp)+'</div><br>'
                        devicetabhtml+='<div class="device-reading" id="torque-'+ptid+'">'+torque2html(info.torque)+'</div><br>'
                        devicetabhtml+='<div class="device-reading" id="runtime-'+ptid+'">'+runtime2html(info.runTime)+'</div><br>'
                    devicetabhtml+= '</div>'
                    devicetabhtml+= '</div>';
                    $("#deviceInfo-"+ptid).append(devicetabhtml);
                    
                    // Builds the buttons used to store the device error, device runtime test generators. Also builds the button for 
                    // removing the device from the database
                    devicetabhtml = '<table class="table-users table small-margin" border="0"><tbody>'
                    
                    devicetabhtml += '<div>';
                    devicetabhtml += '<tr class="nohover">'
                    devicetabhtml +='<td>Set Device Torque:</td>';
                    devicetabhtml +='<td><input type="number" min=300 max=1600 class="small-btn" id = "torque-value-'+ptid+'" placeholder = "Enter Torque (N \u22C5 m)"></td>';
                    devicetabhtml +='<td><button class="small-btn" type = "submit" id = "torque-sub'+ptid+'">Set Torque</button></td></tr>';
                    
                    devicetabhtml += '<tr class="nohover">'
                    devicetabhtml += '<td>Set Run Duration:</td>';
                    devicetabhtml +='<td><input type="number" min=30 max=240 class="small-btn" id = "duration-'+ptid+'" placeholder = "Enter Run Duration (s)"></td>';
                    devicetabhtml +='<td><button class="small-btn" type = "submit" id = "duration-sub'+ptid+'">Set Duration</button></td></tr>';
                    devicetabhtml += '</tbody></table>'
            
                    devicetabhtml += '<table class="table-users table small-margin" border="0"><tbody>'
                    devicetabhtml +='<tr class="nohover"><td><button class="settings-btn" type = "submit" id = "test-error-sub'+ptid+'">Generate Error</button></td></tr>';
                    devicetabhtml +='<tr class="nohover"><td><button class="settings-btn" type = "submit" id = "test-settings-sub'+ptid+'">Generate device run settings</button></td></tr>';
                    devicetabhtml +='<tr class="nohover"><td><button class="settings-btn" type = "submit" id = "removeDevice'+ptid+'">Remove Device</button></td><tr>';
                    devicetabhtml += '</tbody></table>'
                    devicetabhtml +='</div>';
                    $("#deviceRunParams-"+ptid).append(devicetabhtml);
                    
                    // On click generates a test error for the device set to the current time. Updates the warning message on the current
                    // browser
                    $("#test-error-sub"+ptid).click(function(ev) {
                        $.ajax({
                          type: "POST",
                          url: "extraLSPpages/deviceadderror.lsp",
                          data: {deviceIP:info.ipaddr},
                        success: function(output) {
                              $('#device-warning-'+ptid).removeClass("white-warning").addClass("red-warning");
                          }
                        });
                        
                    });
                    
                    $("#torque-sub"+ptid).click(function(ev) {
                        // this is where you would publish to the device
                        var torqueVal = $("#torque-value-"+ptid).val()
                        if (torqueVal >= 300 && torqueVal <= 1600){
                            var torquedata = '{"ptid":"'+ptid+'", "value":"'+torqueVal+'"}'
                            
                            smq.publish(torquedata,"/m2m/torque/display");
                            smq.publish(torqueVal+ "\0",ptid,"/m2m/torque");
                            $.ajax({
                                type: "POST",
                                url: "extraLSPpages/changedevicesettings.lsp",
                                data: {deviceIP:info.ipaddr, deviceModel:escapeHtml(info.devname),setting:"torque", value:torqueVal},
                                success: function(output) {
                                    alert(output);
                                }
                            });
                            var torqueId='#torque-'+ptid;
                            $(torqueId).html(torque2html(torqueVal));
                            }
                        else{
                            alert("Please enter a valid torque value in the range 300 to 1600");
                        }
                    });
                    
                    $("#duration-sub"+ptid).click(function(ev) {
                        var durationVal = $("#duration-"+ptid).val();
                        if (durationVal >= 30 && durationVal <= 240){
                            var timedata = '{"ptid":"'+ptid+'", "value":"'+durationVal+'"}';
                            
                            smq.publish(timedata,"/m2m/time/display");
                            smq.publish(durationVal+ "\0",ptid,"/m2m/time");
                            $.ajax({
                                type: "POST",
                                url: "extraLSPpages/changedevicesettings.lsp",
                                data: {deviceIP:info.ipaddr, deviceModel:escapeHtml(info.devname),setting:"run time", value:durationVal},
                                success: function(output) {
                                    alert(output);
                                }
                            });
                            var timeId='#runtime-'+ptid; 
                            $(timeId).html(runtime2html(durationVal));
                            }
                        else{
                            alert("Please enter a valid time value in the range 30 to 240");
                        }
                    });
                    
                    // Generates new data run results
                    $("#test-settings-sub"+ptid).click(function(ev) {
                        $.ajax({
                          type: "POST",
                          url: "extraLSPpages/creategraph.lsp",
                          data: {deviceIP:info.ipaddr},
                        success: function(output) {
                              alert("New test settings generated for device");
                          }
                        });
                        
                    });
            
                    // Used to publish state changes of the device from the browser using checkboxes.
                    // Adapted from the Mako Server tutorial
                    $('#dev-'+ptid+' :checkbox').click(function(ev) {
                        var id = $(this).prop('id').match(/(\d+)-(\d+)/);
                        var ptid = parseInt(id[1]);
                        var ledId = parseInt(id[2]);
                        var data = new Uint8Array(2);
                        data[0] = ledId;
                        data[1] = this.checked ? 1 : 0;
                        smq.publish(data,ptid);
                    });
                    
                    // Code used to remove device from database so it needs to be re-registered on
                    // device restart
                    $("#removeDevice"+ptid).click(function(ev) {
                        $.ajax({
                          type: "POST",
                          url: "extraLSPpages/removedevicecode.lsp",
                          data: {deviceIP:info.ipaddr, deviceModel:escapeHtml(info.devname)},
                        success: function(output) {
                              alert(output);
                          }
                        });
                        
                    });
            
                    // Used to observe if a device disconnects - if so, removes the device's information.
                    smq.observe(ptid, function() {
                        $('#dev-'+ptid).remove();
                        $('#device-'+ptid).remove();
                        $('#deviceContents-'+ptid).html('<div class="header-div">The device has disconnected</div><button class="tablinks backtab" id ="backtabdelete-'+ptid+'">Go back</button>');
                        $("#deviceInfo-"+ptid).remove();
                        $("#deviceStatistics-"+ptid).remove();
                        $("#deviceRunParams-"+ptid).remove();
                        $("#deviceLogs-"+ptid).remove();
                        $("#backtabdelete-"+ptid).click(function(ev) {
                            $("#devicesListContainer").show();
                            $("#deviceContents-"+ptid).hide();
                        });
                        if(--connectedDevs == 0)
                            printNoDevs();
                    });
                    
                    
            
                    
                    
                    // If 1 or more devices are shown
                    if(++connectedDevs == 1) {
                        $("#nodev").hide(); 
                    }
                } //devInfo
                
                    // On received state change of device hardware, toggles the associated checkbox
                    function onLED(data, ptid) {
                    var ledId='#switch-'+ptid+'-'+data[0];
                    var checked = data[1] ? true : false;
                    $(ledId).prop('checked',checked);
                    ledId ='#led-'+ptid+data[0];
                    if(checked)
                        $(ledId).removeClass('led-off')
                    else
                        $(ledId).addClass('led-off');
                };
            
                // On temp change, posts new temp
                function onTemp(data, ptid) {
                    var b = new Uint8Array(data,0,2);
                    var temp = (new DataView(b.buffer)).getInt16(0);
                    var tempId='#temp-'+ptid;
                    $(tempId).html(temp2html(temp));
                };
                // Currently unused - On torque change, changes torque in device info
                function onTorque(data, ptid) {
                    var torqueId='#torque-'+data.ptid;
                    $(torqueId).html(torque2html(data.value));
                };
                // Currently unused - Countdown for device run time
                function onTimeLeft(data, ptid) {
                    var timeId='#runtime-'+data.ptid; 
                    $(timeId).html(runtime2html(data.value));
            
                };
                
                    
                    // Subscribes to device's temperatures
                    smq.subscribe("/m2m/temp", {"onmsg":onTemp});
                    // Currently unused ///////////
                    smq.subscribe("/m2m/torque/display", {"datatype":"json","onmsg":onTorque});
                    smq.subscribe("/m2m/time/display", {"datatype":"json","onmsg":onTimeLeft});
                    ///////////////////////////////
                    
                    // If response message is sent from device to this browser, builds the device info sent
                    smq.subscribe("self", {"datatype":"json", "onmsg":devInfo});
                    <?lsp -- Logoc used to determine which devices the user can view and change settings for
                    if tonumber(usersession.viewAllDevices)== 1 then 
                        local su=require"sqlutil"
                        local sql=string.format("companyName FROM company")
                
                        local function execute(cur)
                            local company = cur:fetch()
                            while company do ?>
                            //Devices that connect after browser has already connected- Sends device info
                                smq.subscribe("<?lsp=company?>", "devinfo", {"datatype":"json", "onmsg":devInfo}); 
                                // On device hardware state change, receives this and updates the UI
                                smq.subscribe("<?lsp=company?>", {"onmsg":onLED});
                                // Message indicating the browser has connected, prompting devices to send their info
                                smq.publish("Hello", "/m2m/led/display/"+"<?lsp=company?>");
                               <?lsp company = cur:fetch()
                            end
                            return true
                        end
                        
                        local function opendb() 
                            return su.open"file" 
                        end
                        
                        local ok,err=su.select(opendb,string.format(sql), execute)
                    else --If only 1 company is allowed to be accessed, the company the user is part of
                        -- Then only show devices relating to that company
                        ?>
                        smq.subscribe(getCompany(), "devinfo", {"datatype":"json", "onmsg":devInfo});
                                smq.subscribe(getCompany(), {"onmsg":onLED});
                                smq.publish("Hello", "/m2m/led/display/"+getCompany());
                        <?lsp
                        
                    end ?>
                });
            </script>
        </head>
        
        
    <body> <!-- Loads navbar and sets devicelist to active -->
        <div id="new-header">
            <script>
            $("#new-header").load("header.lsp", function() {
                $('#header-deviceList').addClass('active');
            });
            </script>
        </div>
    
        
        <div class="container">
            <div class="row">
                <!-- Container for devices list -->
                <div class="panel panel-default user_panel" id = "devicesListContainer">
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
                
                <!-- Container for devices information -->
                <div id ="deviceSettingInjection"></div>
    	    </div>
        </div>
    </body>
</html>
