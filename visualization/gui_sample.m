function handle = gui_sample(base,currentSample)


% Main figure: create and set properies (relative size, color)
screensize = get(0,'Screensize');
rel = (screensize(3))/(screensize(4)); % relative screen size
maxRelHeight = 0.8;
posx = 0.2;
posy = 0.1;
width = ((16/12)/rel)*maxRelHeight; % use 16/12 window ratio on all computer screens
height = maxRelHeight;
gui_sample.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off');


%% Main title
gui_sample.title_axes = axes('Units','normalized','Position',[0.5 0.95 0.18 0.04]); axis off;
gui_sample.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} Sample Visualizer','Units','normalized','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels
% create panel for overview (top-left)
gui_sample.uiPanelOverview = uipanel('Parent',gui_sample.fig_main,...
                                     'Position',[0.023 0.712 0.689 0.222],...
                                     'Title','Overview','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.1,...
                                     'BackgroundColor',[1 1 1]);

% create panel for thumbnail gallery (bottom-left)
gui_sample.uiPanelGallery = uipanel('Parent',gui_sample.fig_main,...
                                    'Position',[0.023 0.021 0.689 0.669],...
                                     'Title','Cell Gallery','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.033,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
gui_sample.uiPanelScatter = uipanel('Parent',gui_sample.fig_main,...
                                    'Position',[0.731 0.021 0.245 0.913],...
                                     'Title','Marker Characterization','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);

                                 
%% Fill uiPanelOverview
% create table with sample properties as overview
rnames = properties(currentSample);
selectedProps = [1,2,3,5,6,8,9,10]; % properties of data sample to be visualized
rnames = rnames(selectedProps); % row titles
cnames = {}; % col titles
dat = cell(numel(rnames),1);
for i = 1:numel(rnames)
   dat{i} = eval(['currentSample.',rnames{i}]); %getfield(handles.currentFrame,rnames{i});
end
gui_sample.tableDetails = uitable('Parent',gui_sample.uiPanelOverview,...
                                  'Units','normalized','Position',[0.03 0.07 0.2 0.85],...
                                  'Data',dat,'ColumnName',cnames,'RowName',rnames);
% tabExtend = get(tableDetails,'Extent')
% tabPosition = get(tableDetails,'Position');
% tabPosition(3:4) = tabExtend(3:4);
% set(tableDetails,'Position',tabPosition);

% create overview image per channel
gui_sample.axesOverview = axes('Parent',gui_sample.uiPanelOverview,...
                               'Units','normalized','Position',[0.25 0.07 0.73 0.82]);
defCh = 2; % default channel for overview when starting the sample visualizer
gui_sample.imageOverview = imagesc(currentSample.overviewImage(:,:,defCh));
axis image; axis off;

% create choose button to switch color channel
gui_sample.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                    'Units','normalized','Position',[0.4 -0.09 0.08 0.85],...
                                    'FontUnits','normalized','FontSize',0.02,...
                                    'Value',defCh,...
                                    'Callback',{@popupChannel_callback});

                                
%% Fill uiPanelGallery
debug = 0;

% create slider for gallery
gui_sample.slider = uicontrol('Style','Slider','Parent',gui_sample.uiPanelGallery,...
                              'Units','normalized','Position',[0.98 0 0.02 0.95],...
                              'Value',1,'Callback',{@slider_callback});

% create panel for thumbnails next to slider                          
gui_sample.uiPanelThumbsOuter = uipanel('Parent',gui_sample.uiPanelGallery,...
                                        'Position',[0 0 0.98 0.95],...
                                        'BackgroundColor',[1 1 1]);
%-----
if ~debug
% compute relative dimension of the thumbnail grid
nbrAvailableRows = size(currentSample.priorLocations,1);
nbrColorChannels = 4; 
nbrImages        = nbrAvailableRows * (nbrColorChannels+1);
maxNumCols       = 5; % design decision, % maxNumCols = 1 (overlay) + nbrChannels
if nbrImages > maxNumCols^2
    cols  = maxNumCols;
    rows  = ceil(nbrImages/cols);
    set(gui_sample.slider,'enable','on','value',1); % enable and upper position
else % exceptional case
    cols = ceil( sqrt(nbrImages) );    % number of columns
    rows = cols - floor( (cols^2 - nbrImages)/cols );
    set(gui_sample.slider,'enable','off');
end
% pitch (box for axis) height and width
rPitch  = 0.98/rows;
cPitch  = 0.98/cols;
% axis height and width
axHight = 0.9/rows;
axWidth = 0.9/cols;
end
%-----
if ~debug
height = rows/cols;
end
if debug
height = 3; %3 means 300% size of inner panel containing the image axes
end
width  = 1;
gui_sample.uiPanelThumbsInner = uipanel('Parent',gui_sample.uiPanelThumbsOuter,...
                                        'Position',[0 1-height width height],...
                                        'BackgroundColor',[1 1 1]);
%-----
if ~debug
hAxes = zeros(nbrImages,1);
% define common properties and values for all axes
axesProp = {'dataaspectratio' ,...
            'Parent',...
            'PlotBoxAspectRatio', ...
            'xgrid' ,...
            'ygrid'};
axesVal = {[1,1,1] , ...
           gui_sample.uiPanelThumbsInner,...
           [1 1 1]...
           'off',...
           'off'};
       
% go through all thumbnails (resp. dataframes)
for thumbInd=1:nbrAvailableRows
    % specify row location for all columns
    y = 1-thumbInd*rPitch;
    % obtain dataFrame from io
    dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd,'prior');
    % plot overlay image in first column
    x = 0;
    ind = (thumbInd-1)*nbrColorChannels + nbrColorChannels + 1; % index for first column element
    hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
    plotImInAxis(dataFrame.rawImage,hAxes(ind));
    % plot image for each color channel in column 2 till nbrChannels
    for ch = 1:nbrColorChannels
        x = 1-(nbrColorChannels-ch+1)*cPitch;
        ind = (thumbInd-1)*nbrColorChannels + ch;
        hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
        plotImInAxis(dataFrame.rawImage(:,:,ch),hAxes(ind));
    end
end
end
%-----
if debug
% TEST: a test axis and image to check scrolling behaviour
gui_sample.bigTestAxes = axes('Parent',gui_sample.uiPanelThumbsInner,...
                   'Position',[0 0 1 1],'xgrid','off','ygrid','off');
imagesc(imread('eight.tif'),'parent',gui_sample.bigTestAxes); axis image;
end
%-----


%% Fill uiPanelScatter
% TODO: make font size in choose buttons relativ
%
sampleFeatures = currentSample.results.features;
marker_size = 30;
% create data for scatter plot at the top
axes('Parent',gui_sample.uiPanelScatter,'Units','normalized','Position',[0.17 0.72 0.75 0.23]); %[left bottom width height]
topFeatureIndex1 = 1; topFeatureIndex2 = 1;
gca; gui_sample.axesScatterTop = scatter(sampleFeatures.(topFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                      sampleFeatures.(topFeatureIndex2+1),marker_size,'filled');
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
popupFeatureSelectTopIndex1 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[0.39 -0.16 0.6 0.85],...
            'FontSize',10,...
            'Value',topFeatureIndex1,...
            'Callback',{@popupFeatureTopIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
popupFeatureSelectTopIndex2 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[-0.01 0.14 0.6 0.85],...
            'FontSize',10,...
            'Value',topFeatureIndex2,...
            'Callback',{@popupFeatureTopIndex2_Callback});
%----
% create data for scatter plot in the middle
axes('Parent',gui_sample.uiPanelScatter,'Units','normalized','Position',[0.17 0.39 0.75 0.23]); %[left bottom width height]
middleFeatureIndex1 = 2; middleFeatureIndex2 = 2;
gca; gui_sample.axesScatterMiddle = scatter(sampleFeatures.(middleFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(middleFeatureIndex2+1),marker_size,'filled');
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
popupFeatureSelectMiddleIndex1 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[0.39 -0.49 0.6 0.85],...
            'FontSize',10,...
            'Value',middleFeatureIndex1,...
            'Callback',{@popupFeatureMiddleIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
popupFeatureSelectMiddleIndex2 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[-0.01 -0.19 0.6 0.85],...
            'FontSize',10,...
            'Value',middleFeatureIndex2,...
            'Callback',{@popupFeatureMiddleIndex2_Callback});
%----
% create scatter plot at the bottom
axes('Parent',gui_sample.uiPanelScatter,'Units','normalized','Position',[0.17 0.06 0.75 0.23]); %[left bottom width height]
bottomFeatureIndex1 = 3; bottomFeatureIndex2 = 3;
gca; gui_sample.axesScatterBottom = scatter(sampleFeatures.(bottomFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(bottomFeatureIndex2+1),marker_size,'filled');
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
popupFeatureSelectBottomIndex1 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[0.39 -0.82 0.6 0.85],...
            'FontSize',10,...
            'Value',bottomFeatureIndex1,...
            'Callback',{@popupFeatureBottomIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
popupFeatureSelectBottomIndex2 = uicontrol('Parent',gui_sample.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',sampleFeatures.Properties.VariableNames(2:end),...
            'Position',[-0.01 -0.52 0.6 0.85],...
            'FontSize',10,...
            'Value',bottomFeatureIndex2,...
            'Callback',{@popupFeatureBottomIndex2_Callback});


                                
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    set(gui_sample.imageOverview,'CData',currentSample.overviewImage(:,:,selectedChannel));
end

% --- Executes on selection in topFeatureIndex1 (x-axis)
function popupFeatureTopIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterTop,'XData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in topFeatureIndex2 (y-axis)
function popupFeatureTopIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterTop,'YData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in middleFeatureIndex1 (x-axis)
function popupFeatureMiddleIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterMiddle,'XData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in middleFeatureIndex2 (y-axis)
function popupFeatureMiddleIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterMiddle,'YData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in bottomFeatureIndex1 (x-axis)
function popupFeatureBottomIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterBottom,'XData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in bottomFeatureIndex2 (y-axis)
function popupFeatureBottomIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(gui_sample.axesScatterBottom,'YData',currentSample.results.features.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on slider movement.
function slider_callback(hObject,~,~)
    val = get(hObject,'Value');
    set(gui_sample.uiPanelThumbsInner,'Position',[0 -val*(height-1) width height])
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,hAx)
    if size(im,3) > 1
        % create overlay image here
        imagesc(sum(im,3),{'ButtonDownFcn'},{'openSpecificImage( gcf )'},'parent',hAx);
    else
        imagesc(im,{'ButtonDownFcn'},{'openSpecificImage( gcf )'},'parent',hAx);
    end
    axis(hAx,'image');
    axis(hAx,'off');
    colormap(gray);
    %drawnow;
end


% return handle 
handle = gui_sample;

end