function parse_project_matlab_funcs(path_to_project, target_file)
addpath(genpath(path_to_project));

m_funcs = get_project_matlab_funcs(path_to_project);

%m_funcs

func_data = struct(...
	'name', {},...
	'input_param', {},...
	'output_param', {});

skipped = {};

for m_funcs_i = 1:size( m_funcs, 1 )
	current_func = struct();

	current_func.name = m_funcs{ m_funcs_i, 1 };

	disp( sprintf('Processing function %s...',current_func.name) );

	try
		[input_param, output_param] = get_arg_names(current_func.name);
	catch ME
		skipped = [ skipped, current_func.name ];
		continue
	end

	current_func.input_param = input_param;
	current_func.output_param = output_param;

	func_data = [ func_data, current_func ];
end

data = struct();
data.functions = func_data;
data.skipped_functions = skipped;

save( target_file, 'data', '-v7' );

end
