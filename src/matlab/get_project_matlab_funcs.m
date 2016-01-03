function [m_funcs] = get_project_matlab_funcs(path_to_project)

%% Get a list of the all MATLAB functions.
% This iterates over each of the subdirectories of the path and gets
% the .m files therein.
m_files = {};
all_dir = strsplit(genpath(path_to_project), pathsep);
for dir_i = 1:length(all_dir)
	m_files_in_dir = what(all_dir{dir_i});
	m_files = [m_files; m_files_in_dir.m];
end

m_funcs = cell(length(m_files), 1);
for m_files_i = 1:length( m_files )
	m_funcs{m_files_i} = regexprep(m_files{m_files_i} , '\.m$' , '');
	%disp( [m_files{m_files_i} ' -> ' m_funcs{m_files_i}]  );%DEBUG
end

end
