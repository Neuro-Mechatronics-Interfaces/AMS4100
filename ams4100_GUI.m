%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Filename:    ams4100_GUI.m
%
% Copyright:   A-M Systems
%
% Author:      DHM
%
% Description:
%   This is a MATLAB script that creates the Model 4100 user interface
%   No inputs or outputs to the function
%   
% Required functions that must be in the same folder or in your MATLAB
% path.
%   CLASSES:
%   ams4100_hClass.m -  The class that communicates with the instrument
%   ComConstants.m -    The sturcture with that enumerates the constats.
%  
%  FUNCTIONS:
%  checkTimes.m  - verifies AMS4100 time values are valid. Returns string error. 
%  controlsGUI.m - Cell of GUI cotrols, each row has Name, Label, and type
%  defaultData.m  -  Fills the AMS4100 GUI with default data.
%  DrawBiphasic.m  - Draws the interactive Biphasic Event Graph
%  DrawMonophasic.m  - Draws the interactive Monophasic Event Graph
%  DrawRamp.m  - Draws the interactive Ramp Event Graph
%  getOffsetAmps.m  - Returns the pre-train, train, amp1 and amp2 values
%                     based on the train event level and offset type.
%  getTimeValues.m  -  Returns the event time values for the desired event. 
%  getValueNames.m  -  Generates a valid variable name based on the
%                       comConstants stucture.
%  IDnum.m  -  Processes changes to the EventID, LibID and EventList
%              uicontrols
%  LoadWindow.m - Loads the window uicontrols with data from the instrument,
%                 or local Data if there is no instrument connection
%  Plotit.m  -  Plots the time response for the events.
%  processUserInput.m  - takes a change to the uicontrol, and updates the
%                        localData and sends info to the instrument.
%  RetAmp1.m and RetAmp3.m  -  Given the graphical Y value of a line it 
%                               returns the Event aplitude
%  SetCom.m  -  Sets the serial port communication for the instrument
%  SetTimeAMS.m  - Takes the time values from the instrument and converts
%                  it to a string for the uicontrols
%  timeNum.m  -  Takes a uicontrol time value and makes sure it is in the
%                appropriate range
%  trainNum.m -  Takes a uicontrol train number and makes sure it is in the
%                appropriate range
%  UpdateEvents.m  - Updates the uicontrol event data when there is a
%                    change to the libID, or EventID.
%
% GLOBALS:
%  myAMS;  -  The object for the connection to the instrument
%  WindowW;  - The user interface window width
%  WindowH;  - The user interface window height
%  OKtoGraph; - A boolean to control when it is ok to update the graph 
%  lData;  - local data for the controls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function Main4100GUI
% Main4100GUI UI control for the Model 4100
global myAMS;
global lData;
global cntrls;
global OKtoGraph;
cntrls=controlsGUI;
lData=defaultData;
OKtoGraph=1;

WindowH=650;
WindowW=1150;

%%
% Build User Interface
    MainWindow=makeFigure(WindowW,WindowH);  % Main window width,height
    handles=makePanel(MainWindow,WindowW,WindowH);
    guidata(MainWindow, handles);  
    myAMS=ams4100_hClass;
    pause(0.05);
    LoadWindow(); 
    Plotit();
    handles.TimerA = timer('ExecutionMode','fixedrate','Period',66,...
                    'TimerFcn',{@ReaderA});
%     if myAMS.PortSuccess
%         start(handles.TimerA);
%     end
    set(MainWindow,'Name',['AMS4100 Revision:' myAMS.Revision '  Serial Number:' myAMS.SerialNumber  '   Matlab Revision:' myAMS.MatlabRev ] );
    guidata(MainWindow,handles) ;%save graphic data
end  

%%
function fig=makeFigure(w,h)
%Returns a figure of width(w) and height(h) in the middle of the screen
% w and h must be even for now
    scrsz = get(0,'ScreenSize');
    fig=figure('position', ...
    [(scrsz(3)/2-w/2) (scrsz(4)/2-h/2) w h], ...
    'toolbar', 'none',...
    'menubar', 'none','DeleteFcn', @Closing, ...
    'NumberTitle','off','Name','AMS4100');
end
%%
function handles=makePanel(mywindow,WindowW,WindowH)
%makePanel Makes the  user interface
%% Set up an array of how I want to order the controls
global cntrls;
cntrl_name=1;
cntrl_label=2;
cntrl_type=3;

 %% Channel labels
   h=guihandles(mywindow);
   sizeCntrls=size(cntrls,1);
   Ptop=WindowH-55; %625 0,0 is lower left corner
   Top=WindowH-75;  %595 
   hgt=18;
   h.PlotGraphs=uicontrol('Style','pushbutton', ...
                      'Tag', 'button', ...
                      'Position',[450,WindowH-45,60,40], ...
                      'String','Plotit', ...
                      'Callback',@Plotit);
   h.Go=uicontrol('Style','pushbutton', ...
                      'Tag', 'button', ...
                      'Position',[220,WindowH-45,40,40], ...
                      'String','Go', ...
                      'Callback',@Go);    
   h.Stop=uicontrol('Style','pushbutton', ...
                        'Tag', 'button', ...
                      'Position',[270,WindowH-45,50,40], ...
                      'String','Stop', ...
                      'Callback',@Stop);  
   h.ManTrig=uicontrol('Style','pushbutton', ...
                        'Tag', 'button', ...
                      'Position',[330,WindowH-45,50,40], ...
                      'String','ManTrig', ...
                      'Callback',@ManTrig);  
   h.FreeRun=uicontrol('Style','togglebutton', ...
                       'Tag', 'button', ...
                      'Position',[390,WindowH-45,50,40], ...
                      'String','FreeRun', ...
                      'Callback',@FreeRun); 
   h.ReLoad=uicontrol('Style','pushbutton', ...
                        'Tag', 'button', ...
                      'Position',[310,WindowH-78,70,25], ...
                      'String','Reload', ...
                      'Callback',@Reload); 
   h.CloseRelay=uicontrol('Style','pushbutton', ...
                       'Tag', 'button', ...
                      'Position',[20,WindowH-550,90,40], ...
                      'String','CloseRelay', ...
                      'Callback',@CloseRelay);                
   h.OpenRelay=uicontrol('Style','pushbutton', ...
                       'Tag', 'button', ...
                      'Position',[20,WindowH-600,90,40], ...
                      'String','OpenRelay', ...
                      'Callback',@OpenRelay);                     
   h.SendCmdText=uicontrol('Style','edit', ...
        'Position',[10,WindowH-620,200,15],...
        'BackgroundColor','white', ...
        'HorizontalAlignment', 'left', ...
        'String','1001 g a');   
   h.SendCmd=uicontrol('Style','pushbutton', ...
                       'Tag', 'button', ...
                      'Position',[220,WindowH-630,50,30], ...
                      'String','Send', ...
                      'Callback',@SendCommandText); 
   avPorts=cellstr(serialportlist)';  % note might be good to use serialportlist('available')
   avPorts=['None';'Ethernet'; avPorts];
   h.Sport=uicontrol('Style','popupmenu', ...
                      'Position',[100,WindowH-41,100,40], ...
                      'String',avPorts, ...
                      'Callback',@SetCom);               
   h.Sportlbl=uicontrol('Style','text',...
        'Position',[10,WindowH-18,80,15],...
        'String','Port');               
   h.Etherlbl=uicontrol('Style','text',...
        'Position',[10,WindowH-40,80,15],...
        'String','Ethernet');       
  h.Ethernet=uicontrol('Style','edit',...
        'Position',[100,WindowH-43,80,20],...
        'BackgroundColor','white', ...
        'HorizontalAlignment', 'left', ...
        'String','10.0.0.81');                
   % Put Control labels for each row ************************************
   vt=WindowH-75;
   for lbl=1:sizeCntrls
       if lbl > find(strcmp(cntrls(:,cntrl_name), 'OffsetOrHold')) 
           xlblpos=240;  % move to next collumn after offset or hold
       else
           xlblpos=5;
       end
        nstr=cell2mat(cntrls(lbl,cntrl_name));
       vt=vertAdj(vt, cell2mat(cntrls(lbl,cntrl_name)),cell2mat(cntrls(lbl,cntrl_type)));
       
      if cell2mat(cntrls(lbl,cntrl_type))==3 %times
           if strfind(cell2mat(cntrls(lbl,1)),'Freq')
                h.( matlab.lang.makeValidName([nstr 'Units']))= ...
                uicontrol('Style','text',...
                'Tag', 'FreqUnit', ...
                'Position',[xlblpos+200 vt 20 hgt-2],...
                'HorizontalAlignment', 'Left',...
                'String','kHz');
           else
                h.( matlab.lang.makeValidName([nstr 'Units']))= ...
                uicontrol('Style','text',...
                'Tag', 'TimeUnit', ...
                'Position',[xlblpos+200 vt 20 hgt-2],...
                'HorizontalAlignment', 'Left',...
                'String','ms');               
           end
       end
       if cell2mat(cntrls(lbl,cntrl_type))==5  %amplitudes
           if strfind(cell2mat(cntrls(lbl,1)),'Y')
           else
                h.( matlab.lang.makeValidName([nstr 'Units']))= ...
                 uicontrol('Style','text',...
                'Tag', 'AmpUnit', ...
                'Position',[xlblpos+200 vt 20 hgt-2],...
                'HorizontalAlignment', 'Left',...
                'String','V'); 
           end  
       end       
       h.( matlab.lang.makeValidName([nstr 'lbl']))= ...
         uicontrol('Style','text',...
        'Tag', 'lbl', ...
        'Position',[xlblpos vt 60 hgt-2],...
        'HorizontalAlignment', 'Left',...
        'String',cntrls(lbl,cntrl_label));
   end  

%% Channel Controls
    vt=WindowH-75;
   for cntrl=1:sizeCntrls 
        % UserData= name, type, myValue, index
      if cntrl > find(strcmp(cntrls(:,cntrl_name), 'OffsetOrHold')) 
           xcntrpos=240+100;
      else
           xcntrpos=5+100;
       end
          vt=vertAdj(vt, cell2mat(cntrls(cntrl,cntrl_name)),cell2mat(cntrls(cntrl,cntrl_type)));
            nstr=cell2mat(cntrls(cntrl,cntrl_name));
            cntlType=cell2mat(cntrls(cntrl,cntrl_type));
            switch cntlType 
                case 2
                   h.( matlab.lang.makeValidName(nstr))=uicontrol(...
                        'Tag', [nstr ], ...
                        'UserData', { nstr cntlType 1 0}, ...
                        'style', 'popupmenu'   ,...
                        'FontSize', 8 , ...
                        'position',[xcntrpos vt 100 hgt] ,...
                        'string', getValueNames(nstr), ...
                        'Callback',{@processUserInput} );
                         if strcmp(nstr,'EventID')
                            % build the EventID with the default of 1, and
                            % myValue is the previous value of 1
                            set(h.EventID,'UserData',{nstr cntlType 1 0},'Value',1);
                         end
                case 3
                    h.(matlab.lang.makeValidName(nstr))=uicontrol( ...
                        'Tag', [nstr ], ...
                        'UserData', { nstr cntlType 0 0}, ...
                        'style', 'edit' ,...
                        'position',[xcntrpos vt 100 hgt] ,...
                        'BackgroundColor','white', ...
                        'HorizontalAlignment', 'right', ...
                         'Callback',{@processUserInput} );
                case 4
                    h.(matlab.lang.makeValidName(nstr))=uicontrol( ...
                        'Tag', [nstr ], ...
                        'UserData', { nstr cntlType 0 0}, ...
                        'style', 'edit' ,...
                        'position',[xcntrpos vt 60 hgt] ,...
                        'BackgroundColor','white', ...
                        'HorizontalAlignment', 'right', ...
                        'Callback',{@processUserInput} );            
                case 5
                    h.(matlab.lang.makeValidName(nstr))=uicontrol( ...
                        'Tag', [nstr ], ...
                        'UserData', { nstr cntlType 0 0}, ...
                        'style', 'edit' ,...
                        'position',[xcntrpos vt 100 hgt] ,...
                        'BackgroundColor','white', ...
                        'HorizontalAlignment', 'right', ...
                        'Callback',{@processUserInput} );
                case 6
                    inc=-1;
                    nlbl=0;
                    vAdjust=20;
                    vtp=vt;
                    for chk=1:1:20
                        inc=inc+1;
                        nlbl=nlbl+1;
                        slbl=num2str(nlbl);
                        if chk==4 || chk==7|| chk==10 || chk==13|| chk==16 || chk==19
                            vt=vt-vAdjust;
                            inc=0;
                        end
                        if chk==1
                            spots='1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20';
                        else
                            spots=' |1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20';
                        end
                         h.(matlab.lang.makeValidName(nstr))(chk)=uicontrol( ...
                            'Tag', [nstr ], ...
                            'string', spots, ...
                            'UserData', {nstr cntlType 1 chk}, ...
                            'style', 'popupmenu' ,...
                            'position',[xcntrpos+35*inc vt 35 hgt], ...
                            'Callback',{@processUserInput} );
                        if chk>2
                            set( h.(matlab.lang.makeValidName(nstr))(chk), 'Enable','inactive','BackgroundColor',[0.4,0.4,0.4])
                        end
                    end
                    vt=vtp;
                case 9  %Display only text
                     h.(matlab.lang.makeValidName(nstr))=uicontrol( ...
                        'Tag', [nstr ], ...
                        'UserData', { nstr cntlType 0 0}, ...
                        'style', 'text' ,...
                        'position',[xcntrpos vt 130 hgt] ,...
                        'BackgroundColor','white', ...
                        'HorizontalAlignment', 'left');
            end           
   end
 %% Data
h.TrainDurAuto=uicontrol('Style','text','Position',get(h.TrainDur,'position'),...
                        'HorizontalAlignment', 'Center','String','** Auto **');
h.TrainPeriodAuto=uicontrol('Style','text','Position',get(h.TrainPeriod,'position'),...
                        'HorizontalAlignment', 'Center','String','** Auto **');
h.EventQuantityAuto=uicontrol('Style','text','Position',get(h.EventQuantity,'position'),...
                        'HorizontalAlignment', 'Center','String','** Auto **');    
set(h.TrainDurAuto,'Visible','off');
set(h.TrainPeriodAuto,'Visible','off'); 
set(h.EventQuantityAuto,'Visible','off'); 
set(h.Ymax, 'string','20','Visible','on');
set(h.Ymin, 'string','-20','Visible','on');
set(h.LibID, 'FontSize', 8 , 'FontWeight', 'bold','ForegroundColor','red');
set(h.EventID, 'FontSize', 8 , 'FontWeight', 'bold','ForegroundColor','magenta');
set(h.LibIDlbl,'FontSize', 10 , 'FontWeight', 'bold','ForegroundColor','red');
set(h.EventIDlbl, 'FontSize', 10 , 'FontWeight', 'bold','ForegroundColor','magenta');

%% Graphs
    h.Igraph= axes('Units','Pixels','Position',[WindowW-610,440,600,200]);
    h.showSignal= axes('Units','Pixels','Position',[WindowW-610,190,600,200]); 
    h.thingy=axes('Units','Pixels','Position',[WindowW-610,30,600,130]);
    set(h.Igraph,'Tag', 'graph');
    set(h.showSignal,'Tag', 'graph');
    set(h.thingy,'Tag', 'graph');
    %Graph labels
    ybase=40;
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676 ybase 40 15],...
            'String','EW');
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676  ybase+20 40 15],...
            'String','EP');     
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676 ybase+40 40 15],...
            'String','ED');  
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676 ybase+60 40 15],...
            'String','TW');  
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676 ybase+80 40 15],...
            'String','TP');  
     uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-676 ybase+100 40 15],...
            'String','TD');     
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-680 541 40 15],...
            'String','moveY');  
    uicontrol('Style','text',...
            'Tag', 'lbl', ...
            'Position',[WindowW-441 403 40 15],...
            'String','moveX');  
    h.ySteps=uicontrol('style', 'edit' ,...
            'Tag', 'lbl', ...
         'String', '0.5', ...
        'UserData', {'ySteps' 3 0 0}, ...
        'position',[WindowW-683 520 50 20] ,...
        'BackgroundColor','white', ...
        'HorizontalAlignment', 'right', ...
         'Callback',{@processUserInput} );
    h.xSteps=uicontrol('style', 'edit' ,...
        'Tag', 'lbl', ...
         'String', '0.2', ...
         'UserData', {'xSteps' 3 0 0}, ...
        'position',[WindowW-400 400 50 20] ,...
        'BackgroundColor','white', ...
        'HorizontalAlignment', 'right', ...
         'Callback',{@processUserInput} );
handles=h;
end    

function ypos=vertAdj( ypre, cntrNam, ctrType)   
    vA=0;
    if ctrType==2
        vS=25;
    else
        vS=22;
    end
    switch cntrNam
        case  'TrainType'
            vA = 15; %move down an additional 15
        case'TrainFrequency'
            vA=-vS; %don't move down    
        case 'EventID'
            ypre=650-75;
        case 'EventType'
            vA = 15;
        case 'EventFrequency'
            vA=-vS;  %don't move down 
        case 'EventList'
            vA = 15;            
        case 'Ymax'
            vA = 140;   
    end
    ypos=ypre-vS-vA;
end
%%
function Go(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    myAMS.Run;
    set(h.Active,'String',myAMS.Active);
end
function Stop(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    myAMS.Stop;
    set(h.Active,'String',myAMS.Active);
end
function ManTrig(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    myAMS.GoOnce;
    set(h.Active,'String',myAMS.Active);
end
function FreeRun(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    button_state = get(hObject,'Value');
    if button_state == get(hObject,'Max')
          % toggle button is pressed, perform action1
          myAMS.GoFreeRun;
    elseif button_state == get(hObject,'Min')clc
          % toggle button is not pressed, perform action2
          myAMS.StopFreeRun;
    end
    set(h.Active,'String',myAMS.Active);
end

function OpenRelay(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    myAMS.OpenRelay;
    set(h.Active,'String',myAMS.Active);
end
function CloseRelay(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    myAMS.CloseRelay;
    set(h.Active,'String',myAMS.Active);
end

function SendCommandText(hObject, eventdata)
    global myAMS;
    h=guidata(gcf); %get graphic data
    mycmd=get(h.SendCmdText,'String');
    myAMS.SendReceiveString(mycmd);
end

function Reload(hObject, eventdata)
    LoadWindow;
end
function Closing(hObject, eventdata)
global myAMS;
    h=guidata(gcf); %get graphic data
    if myAMS.PortSuccess
        stop(h.TimerA);
        delete(h.TimerA);
    end
    delete(myAMS);
end
function ReaderA(obj,event)
    global myAMS;
    h=guidata(gcf); %get graphic data
    if ~myAMS.ActiveComms
    set(h.Active,'String',myAMS.Active);
    end
end

 