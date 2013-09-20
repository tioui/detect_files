note
	description: "Summary description for {SCANNING_CONTROLLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SCANNING_CONTROLLER

inherit
	ANY
		redefine
			default_create
		end

create
	default_create

feature -- Implementation

	default_create
		do
			is_running:=False
		end

feature -- Access

	is_running:BOOLEAN

	start
		do
			is_running:=True
		end

	stop
		do
			is_running:=False
		end


end
