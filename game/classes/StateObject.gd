#Class for creating states
#It holds a reference to a function to be called
class StateObject:
	var name = ""
	#Holds a reference to a function
	#Call using stateFunc.call_func(args)
	var stateFunc =FuncRef
	var value = -1
	# Input types:
	#	n :: String
	#	s :: String
	#	b :: Int
	func _init(n,s,v,i):
		name = n
		stateFunc = funcref(i,s)
		value = v