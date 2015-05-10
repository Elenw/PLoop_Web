require "PLoop_nginx"

import "System"
import "System.Web"

tinsert = table.insert
tconcat = table.concat

WebSettings.SetLogLevel(WebSettings.LogLevel.Debug)
WebSettings.AddLogHandler(print)

WebSettings.LineBreak = "\n"

class "CacheWriter" { IWriter,
	Write = function(self, text) if text then tinsert(self, text) end end,
	Close = function(self) print(tconcat(self, "")) end,
}

function main(writer)
	local st = os.clock()

	__FileLoader__.OutputPhysicalFiles("index", writer)
	writer:Close()

	print("Cost", os.clock() - st)
end

main( FileWriter("output.html") )
main( CacheWriter() )
