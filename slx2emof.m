% Simulink to Ecore exporter
%
% Matteo Morelli (ReTiSLab@SSSA), BSD 3-Clause License
%

% Fundamental model info
mdlStr = gcs;
mdlHdl = get_param(mdlStr,'handle');

%% Root node
doc_node = com.mathworks.xml.XMLUtils.createDocument('com.eu.evidence.functional:Model');
ee_node = doc_node.getDocumentElement;
ee_node.setAttribute('xmi:version','2.0');
ee_node.setAttribute('xmlns:xmi','http://www.omg.org/XMI');
ee_node.setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
ee_node.setAttribute('xmlns:com.eu.evidence.functional','http://www.evidence.eu.com/functional');
ee_node.setAttribute('name',mdlStr);

%% Export Subsystems
% Find all subsystems at the top level of model hierarchy
ssHdls = find_system(mdlHdl,'SearchDepth',1,'BlockType','SubSystem');
numSss = length(ssHdls);

% For each subsystem
for i = 1:numSss,

    % Define a new child node
    ss_node = doc_node.createElement('block');

    % Assign the right xsi:type attribute
    ss_node.setAttribute('xsi:type','com.eu.evidence.functional:Subsystem');

    % Set the attributes
    % # id
    ssStr = get_param(ssHdls(i),'Name');
    ss_node.setAttribute('id',ssStr);

    % # type -- subsystems do not have a "type";
    %           we assume that "type" coincides with "tag"
    ss_node.setAttribute('type',get_param(ssHdls(i),'Tag'));

    % # symbol
    % TODO

    % model compilation is required for a number of actions below
    set_param(mdlStr,'SolverPrmCheckMsg','none');
    eval([mdlStr,'([], [], [], ''compile'');']);
    % -----------------------------------------------------------

    % # sampletime
    sampletInfo = get_param(ssHdls(i),'CompiledSampleTime');
    ss_node.setAttribute('sampletime', num2str(1000*sampletInfo(1))); %implicitly in ms!

    % # feedthrough
    ftOutcome = {'true','false'};
    [ftInfo] = find_feedthrough([mdlStr,'/',get_param(ssHdls(i),'Name')], sampletInfo(1));
    ss_node.setAttribute('Feedthrough',ftOutcome{isempty(ftInfo)+1});

    % Common params/actions for hasinport/hasoutport (preamble)
    portHdls = get_param(ssHdls(i),'PortHandles');
    %
    % # hasinport
    % Get the IN port handles
    inPortHdls = portHdls.Inport; numInps = length(inPortHdls);
    % get this handle that returns other useful info (e.g., the port name)
    inPortBlkH = find_system(ssHdls(i),'SearchDepth',1,'Blocktype','Inport');
    % For each port
    for p = 1:numInps,
        % Create a node
        inport_node = doc_node.createElement('hasinport');
        % And set the attributes
        %
        % - id (from Block)
        inport_node.setAttribute('id', [ssStr,'_',get_param(inPortBlkH(p),'Name')]);
        % - type, sampletime, symbol, Feedthrough (from Block) ?!
        % - numDims
        cpDimens = get_param(inPortHdls(p),'CompiledPortDimensions');
        inport_node.setAttribute('numDims',num2str(cpDimens((cpDimens(1)<0)+1))); % virtual bus has cpDimens(1)==-2 (see http://goo.gl/rZQIfb)
        % - dims
        nMultiplexSignals = 1; % the classical one-/multi-dimensional signal
        cpDimensCurrInfoIdx = 1;
        if cpDimens(1) == -2,  % virtual bus signal
            nMultiplexSignals = cpDimens(2);
            cpDimensCurrInfoIdx = 3;
        end
        for j = 1:nMultiplexSignals,
            cpDimensNextInfoIdx = cpDimensCurrInfoIdx+cpDimens(cpDimensCurrInfoIdx)+1;
            for k = cpDimensCurrInfoIdx+1:cpDimensNextInfoIdx-1,
                dims_node = doc_node.createElement('dims');
                dims_node.appendChild(doc_node.createTextNode(num2str(cpDimens(k))));
                inport_node.appendChild(dims_node);
            end
            cpDimensCurrInfoIdx = cpDimensNextInfoIdx;
        end
        % - index
        inport_node.setAttribute('index',num2str(get_param(inPortHdls(p),'PortNumber')-1));
        % - datatypename
        inport_node.setAttribute('datatypename',get_param(inPortHdls(p),'CompiledPortDataType'));
        % - explicit
        % TODO
        ss_node.appendChild(inport_node);
    end
    %
    % # hasoutport
    outPortHdls = portHdls.Outport; numOutps = length(outPortHdls);
    outPortBlkH = find_system(ssHdls(i),'SearchDepth',1,'Blocktype','Outport');
    for p = 1:numOutps,
        outport_node = doc_node.createElement('hasoutport');
        % - id (from Block)
        outport_node.setAttribute('id', [ssStr,'_',get_param(outPortBlkH(p),'Name')]);
        % - type, sampletime, symbol, Feedthrough (from Block) ?!
        % - numDims
        cpDimens = get_param(outPortHdls(p),'CompiledPortDimensions');
        outport_node.setAttribute('numDims',num2str(cpDimens((cpDimens(1)<0)+1))); % virtual bus has cpDimens(1)==-2 (see http://goo.gl/rZQIfb)
        % - dims
        nMultiplexSignals = 1; % the classical one-/multi-dimensional signal
        cpDimensCurrInfoIdx = 1;
        if cpDimens(1) == -2,  % virtual bus signal
            nMultiplexSignals = cpDimens(2);
            cpDimensCurrInfoIdx = 3;
        end
        for j = 1:nMultiplexSignals,
            cpDimensNextInfoIdx = cpDimensCurrInfoIdx+cpDimens(cpDimensCurrInfoIdx)+1;
            for k = cpDimensCurrInfoIdx+1:cpDimensNextInfoIdx-1,
                dims_node = doc_node.createElement('dims');
                dims_node.appendChild(doc_node.createTextNode(num2str(cpDimens(k))));
                outport_node.appendChild(dims_node);
            end
            cpDimensCurrInfoIdx = cpDimensNextInfoIdx;
        end
        % - index
        outport_node.setAttribute('index',num2str(get_param(outPortHdls(p),'PortNumber')-1));
        % - datatypename
        outport_node.setAttribute('datatypename',get_param(outPortHdls(p),'CompiledPortDataType'));
        % - explicit
        % TODO
        % - const_value
        % TODO
        ss_node.appendChild(outport_node);
    end

    % terminate simulation of the model
    eval([mdlStr,'([],[],[],''term'');']);
    % ------------------------------------

    % Add the subsystem
    ee_node.appendChild(ss_node);
end

%% Export Blocks
% TODO

%% Export Connections
% For each subsystem & block (TODO: put them together in an array of handles)
for i = 1:numSss,
    % Extract the port-connectivity description structure
    ssPortConnInfo = get_param(ssHdls(i), 'PortConnectivity');
    numPci = length(ssPortConnInfo);

    % Jump to the connectivity description of the OUT ports
    p = 1;
    while p<=numPci && ~isempty(ssPortConnInfo(p).SrcBlock),
        p = p+1;
    end

    % For each conn descr of the out ports
    for p = p:numPci,
        % Read how many connections start from that port
        numOutPortConns = length(ssPortConnInfo(p).DstBlock);

        % And for each one of these connections, finally,
        for j = 1:numOutPortConns,
            % Define a new child node
            cn_node = doc_node.createElement('link');

            % Set the attributes
            % # source
            srcPort = find_system(ssHdls(i),'SearchDepth',1,'Blocktype','Outport');
            cn_node.setAttribute('source',[get_param(ssHdls(i),'Name'),'_',get_param(srcPort(str2double(ssPortConnInfo(p).Type)),'Name')]);

            % # destination
            dstPort = find_system(ssPortConnInfo(p).DstBlock(j),'SearchDepth',1,'Blocktype','Inport');
            cn_node.setAttribute('destination',[get_param(ssPortConnInfo(p).DstBlock(j),'Name'),'_',get_param(dstPort(ssPortConnInfo(p).DstPort(j)+1),'Name')]);

            % Add the subsystem
            ee_node.appendChild(cn_node);
        end
    end    
end

%% Export Total Order

%% Export Events

%% Write the DOM node and clean up the workspace
xmlwrite('Model.xmi',doc_node);
clear doc_node ee_node i p j mdlHdl mdlStr numSss ssHdls ssStr ftInfo ftOutcome inport_node inPortBlkH ...
    inPortHdls numDims cpDimens cpDimensCurrInfoIdx cpDimensNextInfoIdx nMultiplexSignals dims_node numInps numOutps outport_node outPortBlkH outPortHdls portHdls ss_node ...
    ssPortConnInfo numOutPortConns numPci srcPort dstPort cn_node