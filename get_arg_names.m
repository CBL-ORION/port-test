% From <http://stackoverflow.com/questions/10431577/how-do-i-retrieve-the-names-of-function-parameters-in-matlab>,
% <http://stackoverflow.com/a/10746936>
function [inputNames,outputNames] = get_arg_names(functionFile)
    %# get some random file name
    fname = tempname;
    [~,fname] = fileparts(fname);

    %# read input function content as string
    str = fileread(which(functionFile));

    %# build a class containing that function source, and write it to file
    fid = fopen([fname '.m'], 'w');
    fprintf(fid, 'classdef %s; methods;\n %s\n end; end', fname, str);
    fclose(fid);

    %# terminating function definition with an end statement is not
    %# always required, but now becomes required with classdef
    missingEndErrMsg = 'An END might be missing, possibly matching CLASSDEF.';
    c = checkcode([fname '.m']);     %# run mlint code analyzer on file
    if ismember(missingEndErrMsg,{c.message})
        % append "end" keyword to class file
        str = fileread([fname '.m']);
        fid = fopen([fname '.m'], 'w');
        fprintf(fid, '%s \n end', str);
        fclose(fid);
    end

    %# refresh path to force MATLAB to detect new class
    rehash

    %# introspection (deal with cases of nested/sub-function)
    m = meta.class.fromName(fname);
    idx = find(ismember({m.MethodList.Name},functionFile));
    inputNames = m.MethodList(idx).InputNames;
    outputNames = m.MethodList(idx).OutputNames;

    %# delete temp file when done
    delete([fname '.m'])
end
