classdef ( Sealed )  TraceHistory < handle    
% Store and displays a trace of calls (/messages) to functions and methods
%
%   Public properties   none
%
%   Public methods
%       add             -   used by the function, tracer, to add info on calls   
%       clearHistory    -   remove trace of calls
%       disp            -   overloaded 
%       Instance        -   returns handle to the TraceHistory object (Singleton)
%       setup           -   registers file(s) for tracing, i.e. sets breakpoints  
%   
%   Singleton pattern  
%
%   See also: tracer, tracer4m_demo

%{
%   Example: 
    log = TraceHistory.Instance;
    log.setup( { 'testfile4tracer' } )  
    testfile4tracer;
    disp( log )
    report = log.get;
%}

%   author:     per isakson
%   e-mail:     per-ola-isakson(at)gmail-com
%   created:    2008-11-11
%   modified:   2010-10-03

%#ok<*PRTCAL> allow output to command screen
%#ok<*AGROW>  allow grow inside loop

    properties ( Access = private )     
        History
    end   
    methods ( Access = private )        
        function  this = TraceHistory()                      
            this.History  = cell( 5, 0 );    
        end
    end
    methods ( Access = public )         
        
        function    add( this, caller, name, created, pic )  
            called = datestr( now, 'HH:MM:SS,FFF' );
            this.History = cat( 2, this.History, {caller; name; created; called; pic });
            pause( 0.001 )
        end
        function    clearHistory( this )    % the name "clear" is taken - overload - no                   
            this.History  = cell( 5, 0 );
        end
        function    disp( this )
% FIXME: Overloading to show the trace of calls might be nice when debugging, but ...            
            intent  = '';
            fprintf( 1, '%s\n', '--- tracer4m ---' )
            for ca = this.History

                if isempty( intent )
                    fprintf( 1, '%s\n', ca{1} )                         % caller
                end
                if strcmp( ca{5}, 'begin' )
                    intent( end+1 : end+4 )  = ' ';
                    fprintf( 1, '%s%s\n', intent, ca{2} )               % called

                elseif  strcmp( ca{5}, 'end' )
                    intent  = intent( 1 : end-4 );
                else
                    error( 'TraceHistory:disp: ') 
                end
                if  strcmp( ca{3}, 'A' )            
                    intent  = intent( 1 : end-4 );
                end
            end
        end
        function    log = get( this )                   
            log = this.History;
        end
        function    setup( this, caFileList )           
            for caFL = caFileList
                %   this.curStatus = dbstatus( caFL{:} ) and
                %   dbstop( this.curStatus ) at the "end" is more professional.  
                %   However, for now I want to keep the trace-breakpoints to have a 
                %   chance to inspect them. 
                saStatus = transpose( dbstatus( caFL{:} ) );
                for sa = saStatus
                    for ii = 1 : numel( sa.expression )
                        if not( isempty( sa.expression{ii} ) )
                            dbclear( 'in', caFL{:}, 'at', num2str( sa.line(ii) ) )
                        end
                    end
                end
                calls = MethodInfo( caFL{:} ); 

                for s = calls
                    switch s.FunctionType
                        case { 'Constructor' }
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,1}                    ...
                                ,   'if',   'tracer( ''C'', ''begin'' )'    )
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,2}                    ...
                                ,   'if',   'tracer( this,  ''end''  )'     )
                            
                        case { 'Method', 'Property' }
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,1}                    ...
                                ,   'if',   'tracer( this,  ''begin'' )'     )
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,2}                    ...
                                ,   'if',   'tracer( ''M'', ''end''   )'    )
                            
                        case { 'Main', 'Sub', 'Nested' }

                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Name{2}                       ...
                                ,   'if',   'tracer( ''F'', ''begin'' )'    )
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,2}                    ...
                                ,   'if',   'tracer(''F'',  ''end''   )'    )
                            
                        case { 'Static' }
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,1}                    ...
                                ,   'if',   'tracer( ''S'', ''begin''  )'   )
                            
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   s.Range{1,2}                    ...
                                ,   'if',   'tracer( ''S'', ''end''   )'    )
                            
                        case { 'Anonymous' }
% FIXME: Anonymous function on continuation lines causes trouble. mlint returns  
%        the continuation line number, which when used by dbstop puts the break  
%        on first executable following the continuation line. Skip anonymous 
%        function for now!                               
%{
                            dbstop( 'in',   s.Name{1}                       ...
                                ,   'at',   [s.Range{1,1},'@']              ...
                                ,   'if',   'tracer( ''A'', ''begin'' )'    )
%}                        
                        otherwise
                            warning('TraceHistory:setup:FunctionType'   ...
                                ,   'Unknown function type: "%s"'       ...
                                ,   s.FunctionType                      )
                    end
                end
            end
            this.clearHistory()
        end
    end
    methods ( Static )                  
        function    this = Instance()
            persistent  Instance
            if isempty( Instance ) || not( isvalid( Instance ) )
                Instance = TraceHistory;
            end
            this = Instance;
        end
    end
end
function    calls = MethodInfo( mfile ) 

    filespec = which( mfile, '-all' );   
    
    assert( not( isempty( filespec ) )              ...
        ,   'TraceHistory:MethodInfo:FileNotFound'  ...
        ,   'File not found: "%s"'                  ...
        ,   filespec                                )

    assert( numel( filespec ) == 1                      ...
        ,   'TraceHistory:MethodInfo:ShadowFile'        ...
        ,   'There are more than one file named: "%s"'  ...
        ,   mfile                                       )
    
    sam = transpose( mlint( '-calls', char( filespec ) ) );
    
    calls = struct( 'Name'          ,   {}  ...        
                ,   'MlintType'     ,   {}  ...
                ,   'FunctionType'  ,   {}  ...     Main, Sub, Nested, Anonymous 
                ,   'MlintLevel'    ,   {}  ...
                ,   'Range'         ,   {}  );
    
    for ii = 1 : numel( sam )
        s1  = regexp( sam(ii).message                                               ...
            , '^(?<type>\w)(?<level>\d) (?<line>\d+) (?<column>\d+) (?<name>.+)$'   ...
            , 'names'                                                               );
       
        if  any( strcmp( s1.type, {'E','U'} ) ),    continue
        end
        
        if not( strcmp( s1.type, 'A' ) )    % Increment the number; 
            s1.line = sprintf( '%.0f', sscanf( s1.line, '%u' ) + 1 );
        else
            % do nothing
        end
        
        s2  = regexp( sam(ii+1).message                                             ...
            , '^(?<type>\w)(?<level>\d) (?<line>\d+) (?<column>\d+) (?<name>.+)$'   ...
            , 'names'                                                               );
        
        if strcmp( s1.type, 'A' ),  calls(end+1).Name = { mfile; 'anonymous'        };
        else                        calls(end+1).Name = { mfile; strtrim(s1.name)   };
        end                 
        calls(end).MlintType    = s1.type;
        calls(end).MlintLevel   = s1.level;
        calls(end).Range        = { s1.line, s2.line ; s1.column, s2.column };   
    end
    
    cac         = NameParts( mfile );
    metaobject  = meta.class.fromName( cac{end} );
    
    if not( isempty( metaobject ) )
        MethodNames   = cellfun( @(obj) obj.Name , metaobject.Methods   , 'uni', false );
        PropertyNames = cellfun( @(obj) obj.Name , metaobject.Properties, 'uni', false );
        SetGetNames   = [ cellfun( @(c) ['get.',c], PropertyNames, 'uni', false )
                          cellfun( @(c) ['set.',c], PropertyNames, 'uni', false ) ];
    else
        MethodNames   = {''};
        SetGetNames   = {''};
    end
    
    for ii = 1 : numel( calls )
        ism = strcmp( calls(ii).Name{2}, MethodNames );
        isp = strcmp( calls(ii).Name{2}, SetGetNames );
        if any( ism )
            if metaobject.Methods{ism}.Static
                calls(ii).FunctionType              = 'Static';
            else
                if  strcmp( calls(ii).Name{1} ...  
                        ,   calls(ii).Name{2} )      
                    calls(ii).FunctionType          = 'Constructor';
                else
                    calls(ii).FunctionType          = 'Method';
                end
            end
        elseif any( isp )
            calls(ii).FunctionType                  = 'Property';
        else
            switch calls(ii).MlintType
                case 'M',   calls(ii).FunctionType  = 'Main';   
                case 'S',   calls(ii).FunctionType  = 'Sub';   
                case 'N',   calls(ii).FunctionType  = 'Nested';   
                case 'A',   calls(ii).FunctionType  = 'Anonymous';   
                otherwise
                    warning('TraceHistory:MethodInfo:UnknownMlintType'  ...
                        ,   'Unknown mlint function type: "%s"'         ...
                        ,   calls(ii).MlintType                         )
            end
        end
    end
end

function    cac = NameParts( fullname ) 

%   Doc says: Packages are special folders that can contain class folders, function   
%   and class definition files, and other packages. ...  mypack.mysubpack.myfcn 
%   Assumption: 
%   1.  "set" and "get" are not used as package names! 
%   2.  No packages in packages

    cac = textscan( fullname, '%s', 'delimiter', '.', 'whitespace', '' );
    cac = cac{:};
    ism = ismember( cac, { 'set', 'get' } );
    
    if any( ism )
        ix  = find( ism );
        assert( numel( ix == 1 )                                ... 
            ,   'TraceHistory:NameParts:SetGetTrouble'           ...
            ,   'More than on occurance of "set/get" in "%s"'   ...
            ,   fullname                                        )
        if ix == numel( ism )
            % fine - do nothing
        else
            cac{ ix+1 } = cat( 2, cac{ix}, '.', cac{ix+1} );
            cac( ix   ) = [];
        end
    end
end