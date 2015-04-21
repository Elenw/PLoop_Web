require "PLoop_nginx"

import "System"
import "System.Web"

local st = os.clock()

f = FileWriter("output.html")

pageCls = __FileLoader__.OutputPhysicalFiles("index", f, "")

f:Close()

print("Cost", os.clock() - st)