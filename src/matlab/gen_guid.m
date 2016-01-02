function [guid] = gen_guid()
% Generate globally unique ID.
%
% This requires the JVM.

import java.util.UUID;

guid = char(UUID.randomUUID());
end
