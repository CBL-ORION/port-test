function isOut = tracer( varargin )
% tracer is used in conditional to transfer information to a log 
% 
% See also: TraceHistory 

%   author:     per isakson
%   e-mail:     per-ola-isakson(at)gmail-com
%   created:    2008-11-11
%   modified:   2010-10-03

%{
  2009-10-28
  Thread Subject: How to get debug to catch errors in listener callbacks?
  Subject: How to get debug to catch errors in listener callbacks?
  Date: 6 Dec, 2008 01:14:17

  Say I add a listener to an event called 'hello', defined for some object, 'obj':
      addlistener(obj, 'hello', @(src, evnt) MyLazyCallback(src, evnt, data));
  Now, if there is an error in MyLazyCallback, my Matlab only catches the error at 
  the line where obj is notified:
      ->notify(obj, 'hello')
  My question:  Is there any way to get Matlab to error inside MyLazyCallback? 
  It's a bit of a pain right now as I have to go through every callback listening 
  to that event to find the error...
  ....
  ....
  From: Ryan Ollos
  Date: 28 Oct, 2009 04:46:01
  I believe this has been fixed as of r2009b. poi: No, it is not fixed
%} 
    assert( nargin == 2                                             ...
        ,   'tracer:WrongNumberInputArguments'                      ...
        ,   'Wrong, "%u", number of input arguments. Must be two.'  )
    
    stack   = dbstack(1);
    if numel( stack ) >= 2
        name    = stack(1).name; 
        caller  = stack(2).name; 
    else
        name    = stack(1).name; 
        caller  = 'base'; 
    end
    
    if isobject( varargin{1} )
        obj     = varargin{1};
        mobj    = metaclass( obj );
        mprops  = mobj.Properties;
        for ii = 1 : numel( mprops )
            if strcmp( 'ID', mprops{ii}.Name )
                ID  = obj.ID;
                break
            end
        end
    else
        ID = varargin{1};
    end
    if not( exist( 'created', 'var' ) )
        ID = '----';
    end
    log = TraceHistory.Instance;
%   log = TraceLogger.getUniqueInstance;
    log.add( caller, name, ID, varargin{2} )
    
    isOut = true;
end