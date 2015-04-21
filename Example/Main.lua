require "PLoop_nginx"

import "System"
import "System.Web"

pageCls = __FileLoader__.LoadPhysicalFiles("Description")

f = FileWriter("output.html")

local st = os.clock()

page = pageCls()

page:OnLoad()

page:Render(f)

f:Close()

print("Cost", os.clock() - st)