function [ft_info] = find_feedthrough(block, block_sampletime)

% Copyright MathWorks Support Team 2009
% http://www.mathworks.com/matlabcentral/answers/102619-how-can-i-highlight-the-direct-feedthrough-paths-in-simulink

% Syntax: FIND_FEEDTHROUGH(BLOCK)
% Usage: FIND_FEEDTHROUGH(BLOCK) returns a list of all ports that have direct
% feedthrough. 

%% Check for early-return conditions
% Find inport and outports
inports = find_system(block,'SearchDepth',1,'Blocktype','Inport');
outports = find_system(block,'SearchDepth',1,'Blocktype','Outport');
lin = length(inports); lout = length(outports);

% Prepare the output
ft_info = zeros(2,lin*lout);

% Early return if there is no input or output
if lin*lout == 0,
    return;
end

%% Create a temporary model and copy the subsystem block to that model
% Temporary models (two models are actually needed to copy the subsystem as virtual subsystem)
tmpName1 = 'tempMdl1';
tmpName2 = 'tempMdl2';
tmpBlockName = [tmpName1, '/', get_param(block,'name')];
new_system(tmpName1);
%open_system(tmpName1);
new_system(tmpName2);
%open_system(tmpName2);
tmpFile1 = [tmpName1,'.slx'];
tmpFile2 = [tmpName2,'.slx'];

% Copy the content of the subsystem to tmp model #2
Simulink.SubSystem.copyContentsToBlockDiagram(block, tmpName2);
tmpMdl_blks = find_system(tmpName2, 'LookUnderMasks', 'all', 'SearchDepth', 1);
tmpMdl_blks = tmpMdl_blks(2:end);
cellfun(@(x) set_param(x, 'SampleTime', num2str(block_sampletime)), tmpMdl_blks(cellfun(@(y) isfield(get_param(y, 'ObjectParameters'), 'SampleTime'), tmpMdl_blks)));

% Copy the tmp model #2 into a virtual subsystem in tmp model #1
add_block('built-in/Subsystem', tmpBlockName);
Simulink.BlockDiagram.copyContentsToSubSystem(tmpName2, tmpBlockName);

% Close the tmp model #2 & Delete the temporary file 
save_system(tmpName2);
close_system(tmpName2);
delete(tmpFile2);

% Add a Scope Block
add_block('built-in/Scope',[tmpName1,'/Scope']);

%% Find the feedthroughs
parts = regexp(tmpBlockName, '[^/]*', 'match');
ind = 0;

% Set Algebraic Loop Error message On 
set_param(tmpName1,'AlgebraicLoopMsg','error');

% Set nonsignificant warning messages Off
set_param(tmpName1,'SolverPrmCheckMsg','none');
set_param(tmpName1,'UnconnectedInputMsg','none');
set_param(tmpName1,'UnconnectedLineMsg','none');
set_param(tmpName1,'UnconnectedOutputMsg','none');

% For each combination of in/out port
for ii=1:lin,
    for oo=1:lout,
        % Create tmp connections between ports
        in_name = [parts{end},'/',num2str(ii)];
        out_name = [parts{end},'/',num2str(oo)];
        %
        % Connect two ports
        add_line(tmpName1,out_name,in_name);
        add_line(tmpName1,out_name,'Scope/1');
        %
        % Compile the model.
        try
            eval([tmpName1,'([], [], [], ''compile'');']);
            eval([tmpName1,'([],[],[],''term'');']);
        catch me,
            % Make the cause a cell array
            me_cause = cell(me.cause);
            %
            % There is a feedthrough when
            %
            % me.identifier == 'Simulink:Engine:BadFeedbackConn' (see Simple3.slx)
            % any me.cause.identifier == 'Simulink:Engine:BlkInAlgLoopErrWithInfo' (see Simple1.slx)
            if strcmp(me.identifier,'Simulink:Engine:BadFeedbackConn') || ...
               any(cellfun(@(x) strcmp(x.identifier,'Simulink:Engine:BlkInAlgLoopErrWithInfo'),me_cause)),
                ind = ind+1;
                ft_info(1:2,ind) = [ii,oo]';
            end
        end
        %
        % Delete the connections
        delete_line(tmpName1,out_name,in_name);
        delete_line(tmpName1,out_name,'Scope/1');
    end
end

% Clean up the ft_info
ft_info(:,~any(ft_info,1)) = [];

% Print the results (log info)
for ind=1:size(ft_info,2),
    fprintf('Direct feedthrough between \nInport %d: %s\n',...
            ft_info(1,ind),...
                strrep(inports{ft_info(1,ind)},char(10),' '));
    fprintf('Outport %d: %s\n\n',...
            ft_info(2,ind),...
                strrep(outports{ft_info(2,ind)},char(10),' '));
end

% Close the model & Delete the temporary file 
save_system(tmpName1);
close_system(tmpName1);
delete(tmpFile1);