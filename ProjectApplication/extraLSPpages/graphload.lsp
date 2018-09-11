<!DOCTYPE HTML> 
<html>
<head>  
  <script type="text/javascript">
      // Code used to generate graph through reading from database. iterates through
      // list of values using the reading start time and the device's IP along with the reading number
      
      <?lsp
      deviceData=request:data()
       local su=require("sqlutil")
        local sql = selectQueryWhereMult({"readings"},"devicereadings",{"deviceIP","readingstarttime"},{deviceData.deviceIP,deviceData.timeofrun})
        local graphinput={}
        local function execute(cur)
            local count = 0
            readingValue = cur:fetch()
            while readingValue do
                count = count + 1
                table.insert(graphinput, readingValue)
                readingValue = cur:fetch()
            end
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
      // Creates graph using database values 
  function renderchart() {
    var chart = new CanvasJS.Chart("chartContainer",
    {      
      title:{
        text: "Device readings"
      },
      axisY :{
        title: "Torque ( N \u22C5 m )",
        includeZero: false
       
      },
      axisX: { 
      title: "Time (s)",
        interval: 1,includeZero: false
      },
      data: [
      {        
        type: "spline",  
        indexLabelFontColor: "orangered",      
        dataPoints: [
        <?lsp for value, graphinput in ipairs(graphinput) do ?>

        { x: <?lsp=value?>, y: <?lsp=graphinput?> },
        <?lsp end ?>
        ]
      }
      ]
    });

    chart.render();
  }
  </script>
  <script type="text/javascript" src="https://canvasjs.com/assets/script/canvasjs.min.js"></script></head>
  <body>
      <br>
    <div id="chartContainer" style="height: 300px; width: 100%;">
        <script>
            renderchart()
        //Function used to actually generate chart. If the graph wasn't created before the page was loaded, the graph
        // will not work
        </script>
    </div>
  </body>
  </html>
