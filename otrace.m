function otrace(path_to_project, code_to_eval)
	%% Add the top level of the path to the MATLAB path.
	addpath(genpath(path_to_project));
	addpath(genpath('tracer4m'));

	%% Get a list of the all MATLAB functions.
	% This iterates over each of the subdirectories of the path and gets
	% the .m files therein.
	m_files = {};
	all_dir = strsplit(genpath(path_to_project), pathsep);
	for dir_i = 1:length(all_dir)
		m_files_in_dir = what(all_dir{dir_i});
		m_files = [m_files; m_files_in_dir.m];
	end

	m_funcs = cell(size(m_files));
	for m_files_i = 1:length( m_files )
		m_funcs{m_files_i} = regexprep(m_files{m_files_i} , '\.m$' , '');
		%disp( [m_files{m_files_i} ' -> ' m_funcs{m_files_i}]  );%DEBUG
	end

	%% Set up tracer for debugging
	log = TraceHistory.Instance;
	for m_funcs_i = 1:size( m_funcs, 1 )
		% This needs to be run one at a time otherwise dbstatus
		% complains about too many input arguments.

		m_func_current = m_funcs{m_funcs_i,1};

		% get the number of files in the path with the same name
		filespec = which( m_func_current, '-all' );
		if numel( filespec ) == 1
			% only add to debugging if there is a single instance
			log.setup( { m_func_current } );
		else
			warning('Function %s has %d files with the same name in the path.',...
				m_func_current, numel( filespec ));
		end
	end

	%% Run the code.
	eval(code_to_eval);
end
