% From <http://stackoverflow.com/questions/10431577/how-do-i-retrieve-the-names-of-function-parameters-in-matlab>,
% <http://stackoverflow.com/a/10746936>
function [inputNames,outputNames] = get_arg_names(functionFile)
    %# get some random file name
    tmp_folder = tempdir;
    fname = tempname;
    [~,fname] = fileparts(fname);
    full_fname = fullfile( tmp_folder, [ fname '.m' ] );

    %# read input function content as string
    str = fileread(which(functionFile));

    %# build a class containing that function source, and write it to file
    fid = fopen(full_fname, 'w');
    fprintf(fid, 'classdef %s; methods;\n %s\n end; end', fname, str);
    fclose(fid);

    %# terminating function definition with an end statement is not
    %# always required, but now becomes required with classdef
    missingEndErrMsg = 'An END might be missing, possibly matching CLASSDEF.';
    c = checkcode(full_fname);     %# run mlint code analyzer on file
    if ismember(missingEndErrMsg,{c.message})
        % append "end" keyword to class file
        str = fileread(full_fname);
        fid = fopen(full_fname, 'w');
        fprintf(fid, '%s \n end', str);
        fclose(fid);
    end

    %# refresh path to force MATLAB to detect new class
    addpath(  tmp_folder );
    rehash;

    %# introspection (deal with cases of nested/sub-function)
    m = meta.class.fromName(fname);
    idx = find(ismember({m.MethodList.Name},functionFile));
    inputNames = m.MethodList(idx).InputNames;
    outputNames = m.MethodList(idx).OutputNames;

    rmpath(tmp_folder);
    rehash;

    %# delete temp file when done
    delete(full_fname)
end
