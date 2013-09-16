note
	description: "Summary description for {FILES_DETECTOR}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	FILES_DETECTOR

inherit
	DISPOSABLE
	THREAD
	rename
		make as make_thread
	end

create
	make,
	make_and_initialise

feature {NONE} -- Initialization

	make(a_directory:attached READABLE_STRING_GENERAL)
			-- Initialization for `Current'.
		do
			make_thread
			is_initialise:=False
			has_error:=False
			error_text:=""
			create on_new_file.default_create
			create on_deleted_file.default_create
			create working_directory.make (a_directory)
			if working_directory.exists then
				if working_directory.is_readable then

				else
					has_error:=True
					error_text:="Directory "+a_directory+" is not readable."
				end
			else
				has_error:=True
				error_text:="Directory "+a_directory+" does not exist."
			end
		end

	make_and_initialise(a_directory:attached READABLE_STRING_GENERAL)
			-- Initialization for `Current'.
		do
			make(a_directory)
			if not has_error then
				initialise
			end
		end


feature -- Access

	stop_thread
		do
			must_stop:=True
		end

	directory_name:READABLE_STRING_GENERAL
		do
			Result:=working_directory.path.name
		end

	is_initialise:BOOLEAN

	initialise_in_thread
		do
			is_initialise:=False
			must_stop:=False
			launch
		end

	initialise
		local
			l_file:RAW_FILE
		do
			if not has_error then
				create l_file.make_with_path(working_directory.path)
				files_tree:=loading_files(l_file)
			end
		end

	checking_for_file_change
		do

			if attached files_tree as l_files_tree then
				checking_iteration(working_directory,l_files_tree)
			end
		end

	on_new_file:attached ACTION_SEQUENCE[TUPLE[file:attached FILE]]

	on_deleted_file: attached ACTION_SEQUENCE[TUPLE[file:attached FILE]]

	dispose
		do
			if not working_directory.is_closed then
				working_directory.close
			end
		end

feature -- Errors

	has_error:BOOLEAN

	error_text:READABLE_STRING_GENERAL

feature{NONE} -- Implementation

	must_stop:BOOLEAN

	execute
		do
			if is_initialise then
				initialise
			else

			end
		end

	files_tree:TREE[FILE]

	working_directory: attached DIRECTORY

	loading_files(a_current_file:FILE):TREE[FILE]
		require
			A_Current_File_Not_Void:a_current_file/=Void
			A_Current_File_Exist:a_current_file.exists
		local
			l_entries:LIST[PATH]
			l_directory:DIRECTORY
			l_file:RAW_FILE
		do
			create {LINKED_TREE[FILE]} Result.make(a_current_file)
			if a_current_file.exists and then (a_current_file.is_directory and a_current_file.is_readable) then
				create l_directory.make_with_path (a_current_file.path)
				if l_directory.exists and then l_directory.is_readable then
					l_entries:=l_directory.entries
					from
						l_entries.start
					until
						l_entries.exhausted or
						must_stop
					loop
						if attached l_entries.item as l_filename then
							if not (l_filename.is_current_symbol or l_filename.is_parent_symbol) then
								create l_file.make_with_path (l_filename.absolute_path_in (l_directory.path))
								Result.put_child (loading_files(l_file))
							end
						end

						l_entries.forth
					end
					if not l_entries.exhausted then
						has_error:=True
						error_text:="Initialisation has been interrupted."
					end
				end

			end
		end

	checking_new_files(current_directory_path:attached PATH;a_entries:attached LIST[PATH];a_files:attached TREE[FILE])
		local
			l_file:RAW_FILE
			l_directory:DIRECTORY
			l_found:BOOLEAN
			i:INTEGER
		do
			from a_entries.start
			until a_entries.exhausted
			loop
				if attached a_entries.item as l_entry_path then
					if not (l_entry_path.is_current_symbol or l_entry_path.is_parent_symbol) then
						create l_file.make_with_path (l_entry_path.absolute_path_in (current_directory_path))
						from
							i:=1
							l_found:=False
						until
							l_found or i>a_files.arity
						loop
							a_files.child_go_i_th (i)
							if attached a_files.child_item as l_child then
								if attached l_child.path as l_child_path then
									if l_child_path.is_equal (l_file.path) then
										l_found:=True
									end
								end

							end
							if not l_found then
								i:=i+1
							end
						end
						if not l_found then
							a_files.put_child (loading_files(l_file))
							on_new_file.call ([l_file])
						else
							if l_file.exists and then (l_file.is_directory and l_file.is_readable) then
								create l_directory.make_with_path (l_file.path)
								if attached a_files.child as l_child_tree then
									checking_iteration(l_directory,l_child_tree)
								end
							end
						end
					end
				end

				a_entries.forth
			end
		end

	checking_deleted_files(current_directory_path:attached PATH;a_entries:attached LIST[PATH];a_files:attached TREE[FILE])
		local
			l_file:RAW_FILE
			l_found:BOOLEAN
		do
			from
				a_files.child_start
			until
				a_files.child_off
			loop
				from
					l_found:=False
					a_entries.start
				until
					l_found or a_entries.exhausted
				loop
					if attached a_entries.item as l_entry then
						create l_file.make_with_path (l_entry.absolute_path_in (current_directory_path))
						if attached a_files.child_item as l_child then
							if attached l_child.path as l_child_path then
								if l_file.path.is_equal (l_child_path) then
									l_found:=True
								end
							end
						end
					end
					a_entries.forth
				end
				if not l_found then
					if attached a_files.child as l_child then
						if attached l_child.item as l_file_item then
							on_deleted_file.call ([l_file_item])
						end
						a_files.prune (l_child)
					end
				else
					a_files.child_forth
				end
			end
		end

	checking_iteration(a_directory:attached DIRECTORY;a_files:attached TREE[FILE])
		require
			A_Directory_Exists: a_directory.exists
			A_Directory_Is_Readable: a_directory.is_readable
		local
			l_entries:LIST[PATH]
			l_path:PATH
		do
			l_path:=a_directory.path
			l_entries:=a_directory.entries
			checking_new_files(l_path, l_entries,a_files)
			checking_deleted_files (l_path, l_entries,a_files)
		end

end
