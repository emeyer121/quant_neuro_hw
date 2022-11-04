clear all;clc
warning off
set(0,'defaultfigurecolor',[1 1 1])

%% pull the filenames and details from googledoc sheet
ID = '1s0pxZ-ggmf41ZXeSuexsRzIPXt3rdKVTceK4RtOP_fY'; % the long string in the URL
sheet_name = 'Camels';

url_name = sprintf('https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s',...
    ID, sheet_name);
% sheet_data is the entire thing pulled from google sheets
sheet_data = webread(url_name);

%% Run this code to get each shrew's performance on each task with number of sessions
addpath('./plotSpread')
allTasks = {'Camel_v2_test_nn','Camel_novel_v2_test_nn','Camel_background_matrix','Camel_Rhino_test_nn'};
%also add camel_novel_v2_test
%only grab test images somehow and not catch trials
%"test target/distractor" - not rewarded
%"novel target/distractor" - rewarded

% Determine which shrews to use
shrewname={'Seymour','Dominic','Ryker'};
shrewsymbol = {'o','o','o'};

shrewcolor1 = [0.38,0.19,0.71;...
    0.04,0.25,0.73;...
    0.28,0.52,0.15];

shrewcolor2 = [0.72,0.57,0.98;...
    0.6,0.78,0.96;...
    0.62,0.89,0.48];

% set figure color to white
set(0,'defaultfigurecolor',[1 1 1])

% Initialize variables
sessions = table('Size',[10,4],...
    'VariableNames',{'sessionID','shrewID','shrewname','date'},...
    'VariableTypes',{'double','double','string','string'});

dataVars = {'T_Expt_ID','D_Expt_ID','correct','ctch'};
big_Tab = [];
SID = 1;

figure; hold on;
for task = 1:length(allTasks)
big_Tab = [];
SID = 1;
bg_rows = find(strcmp(sheet_data.CODE, allTasks{task}));

% Just extracting the necessary columns, could also be adjusted if more
% info is needed
bgTab = sheet_data(bg_rows,contains(sheet_data.Properties.VariableNames,...
    {'TREESHREW','DATE','CODE','TARGET_IDs','DIST_IDs','TESTTARGETS'}));

% Load in corresponding files
pathname = split(pwd,filesep);
computer_path = [strjoin(pathname(1:3),'\'),filesep,'Box'];
file_dir = [char(computer_path) filesep 'Tree Shrews' filesep 'Analysis' filesep 'Kell_mats' filesep];

for i=1:height(bgTab)
    if exist([file_dir char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'])==2
        try
        load([file_dir filesep char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'],'opTab');
        end
        if sum(contains(opTab.Properties.VariableNames,dataVars))==length(dataVars)
        
            shrewID = find(strcmp(shrewname,bgTab.TREESHREW{i}));

            % this creates 'sessions' which has all the info needed for each
            % session (day)
            sessions.sessionID(SID) = SID;
            sessions.shrewID(SID) = shrewID;
            sessions.shrewname(SID) = bgTab.TREESHREW{i};
            sessions.date(SID) = datestr(bgTab.DATE(i));

            SessID = array2table([ones(height(opTab),1)*SID, ones(height(opTab),1)*shrewID, [1:height(opTab)]'],...
                'VariableNames',{'SessionID','ShrewID','Trial_in_sess'});

            temp_optab =[SessID opTab(:,contains(opTab.Properties.VariableNames,...
                dataVars))];

            % join temp_optab to big_tab
            % this creates 'big_Tab' which has all the individual trials
            big_Tab = [big_Tab; temp_optab];

            clear temp_optab opTab novelTD

            SID=SID+1; % increment session
        end
    end
end

sessionAcc_Catch = cell(1,length(shrewname));
sessionAcc_nonCatch = cell(1,length(shrewname));

if ~isempty(big_Tab)
for ts = 1:length(shrewname)
    sessionIdx = unique(big_Tab.SessionID(big_Tab.ShrewID==ts));
    sessionNTrials = zeros(1,length(sessionIdx));
    sessionNTarg = zeros(1,length(sessionIdx));
    disp([allTasks{task},', ',shrewname{ts},', NTarg = ',num2str(length(unique(big_Tab.T_Expt_ID(big_Tab.ShrewID==ts))))])
    disp([allTasks{task},', ',shrewname{ts},', NDist = ',num2str(length(unique(big_Tab.D_Expt_ID(big_Tab.ShrewID==ts))))])
    for ss = 1:length(sessionIdx)
        catchTrials = big_Tab.ctch == 1;
        noncatchTrials = big_Tab.ctch == 0;
        sessionAcc_Catch{ts}(ss) = mean(big_Tab.correct(big_Tab.SessionID==sessionIdx(ss) & catchTrials),'omitnan');
        sessionAcc_nonCatch{ts}(ss) = mean(big_Tab.correct(big_Tab.SessionID==sessionIdx(ss) & noncatchTrials),'omitnan');
        sessionNTrials(ss) = sum(big_Tab.SessionID==sessionIdx(ss));
        sessionNTarg(ss) = length(unique(big_Tab.T_Expt_ID(big_Tab.SessionID==sessionIdx(ss))));
    end
    sessionAcc_Catch{ts} = sessionAcc_Catch{ts}(sessionNTrials>100 & sessionNTarg>=4);
    sessionAcc_nonCatch{ts} = sessionAcc_nonCatch{ts}(sessionNTrials>100 & sessionNTarg>=4);
end

xvalues = 5*task-4:5*task-2;
mean_noncatch = cellfun(@nanmean,sessionAcc_nonCatch);
mean_catch = cellfun(@nanmean,sessionAcc_Catch);
ax = plotSpread(sessionAcc_nonCatch,'distributionMarkers',shrewsymbol,...
    'distributionColors',shrewcolor1,...
    'xValues',xvalues,...
    'xNames',{' ',allTasks{task},' '},...
    'categoryLabels',shrewname,...
    'binWidth',0.2);

plotSpread(sessionAcc_Catch,'distributionMarkers',shrewsymbol,...
    'distributionColors',shrewcolor2,...
    'xValues',xvalues,...
    'xNames',{' ',allTasks{task},' '});
plot(xvalues,mean_noncatch,'_k','Color','k','MarkerSize',15,'linewidth',1.7);
plot(xvalues,mean_catch,'_k','Color',[0.4 0.4 0.4],'MarkerSize',15,'linewidth',1.7);
end
end

ax{3}.XTick = [1:3,6:8,11:13,16:18];
ax{3}.XTickLabel = {' ',strrep(allTasks{1},'_',' '),' ',' ',strrep(allTasks{2},'_',' '),' ',' ',strrep(allTasks{3},'_',' '),' ',' ',strrep(allTasks{4},'_',' '),' '};
ylim([0.45 1.05])
yticks(0.5:0.1:1)
ylabel('Proportion Correct','fontsize',15)

%% Look at correlations of image pairs across shrews
% Initialize variables
sessions = table('Size',[10,4],...
    'VariableNames',{'sessionID','shrewID','shrewname','date'},...
    'VariableTypes',{'double','double','string','string'});

dataVars = {'T_Expt_ID','D_Expt_ID','correct','ctch'};
allTasks = {'Camel_v2_test_nn','Camel_novel_v2_test_nn','Camel_background_matrix'};

shrewname={'Seymour','Dominic','Ryker'};
cmap = [107,181,107;170,154,192;233,172,114] / 255;

big_Tab = [];
SID = 1;

for task = 1:length(allTasks)
big_Tab = [];
SID = 1;
bg_rows = find(strcmp(sheet_data.CODE, allTasks{task}));

% Just extracting the necessary columns, could also be adjusted if more
% info is needed
bgTab = sheet_data(bg_rows,contains(sheet_data.Properties.VariableNames,...
    {'TREESHREW','DATE','CODE','TARGET_IDs','DIST_IDs','TESTTARGETS'}));

% Load in corresponding files
pathname = split(pwd,filesep);
computer_path = [strjoin(pathname(1:3),'\'),filesep,'Box'];
file_dir = [char(computer_path) filesep 'Tree Shrews' filesep 'Analysis' filesep 'Kell_mats' filesep];

for i=1:height(bgTab)
    if exist([file_dir char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'])==2
        try
        load([file_dir filesep char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'],'opTab');
        end
        if sum(contains(opTab.Properties.VariableNames,dataVars))==length(dataVars)
        
            shrewID = find(strcmp(shrewname,bgTab.TREESHREW{i}));

            % this creates 'sessions' which has all the info needed for each
            % session (day)
            sessions.sessionID(SID) = SID;
            sessions.shrewID(SID) = shrewID;
            sessions.shrewname(SID) = bgTab.TREESHREW{i};
            sessions.date(SID) = datestr(bgTab.DATE(i));

            SessID = array2table([ones(height(opTab),1)*SID, ones(height(opTab),1)*shrewID, [1:height(opTab)]'],...
                'VariableNames',{'SessionID','ShrewID','Trial_in_sess'});

            temp_optab =[SessID opTab(:,contains(opTab.Properties.VariableNames,...
                dataVars))];

            % join temp_optab to big_tab
            % this creates 'big_Tab' which has all the individual trials
            big_Tab = [big_Tab; temp_optab];

            clear temp_optab opTab novelTD

            SID=SID+1; % increment session
        end
    end
end

nShrews = length(unique(big_Tab.ShrewID));
nTarg = length(unique(big_Tab.T_Expt_ID));
nDist = length(unique(big_Tab.D_Expt_ID));

shrewID = unique(big_Tab.ShrewID);
targID = unique(big_Tab.T_Expt_ID);
distID = unique(big_Tab.D_Expt_ID);

perfMat = {};
for s = 1:nShrews
    perfMat{s} = nan(nTarg,nDist);
    for tt = 1:nTarg
        for dd = 1:nDist
            if sum(big_Tab.ShrewID==shrewID(s) & big_Tab.T_Expt_ID==targID(tt) & big_Tab.D_Expt_ID==distID(dd)) >= 10
                perfMat{s}(tt,dd) = mean(big_Tab.correct(big_Tab.ShrewID==shrewID(s) & big_Tab.T_Expt_ID==targID(tt) & big_Tab.D_Expt_ID==distID(dd)),'omitnan');
            end
        end
    end
end


if nShrews==3
    p1 = perfMat{1}(:);perf1 = p1;
    p2 = perfMat{2}(:);perf2 = p2;
    perf1 = perf1(~isnan(p1) & ~isnan(p2));
    perf2 = perf2(~isnan(p1) & ~isnan(p2));
    figure;hold on;
    scatter(perf1,perf2,50,...
        'marker','o',...
        'markeredgecolor',cmap(1,:),...
        'markerfacecolor',cmap(1,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf2, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(1,:),'linewidth',1.5)
    corr(perf1,perf2,'rows','complete')
    
    p1 = perfMat{1}(:);perf1 = p1;
    p3 = perfMat{3}(:);perf3 = p3;
    perf1 = perf1(~isnan(p1) & ~isnan(p3));
    perf3 = perf3(~isnan(p1) & ~isnan(p3));
    scatter(perf1,perf3,50,...
        'marker','o',...
        'markeredgecolor',cmap(2,:),...
        'markerfacecolor',cmap(2,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf3, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(2,:),'linewidth',1.5)
    corr(perf1,perf3,'rows','complete')
    
    p2 = perfMat{2}(:);perf2 = p2;
    p3 = perfMat{3}(:);perf3 = p3;
    perf2 = perf2(~isnan(p2) & ~isnan(p3));
    perf3 = perf3(~isnan(p2) & ~isnan(p3));
    scatter(perf2,perf3,50,...
        'marker','o',...
        'markeredgecolor',cmap(3,:),...
        'markerfacecolor',cmap(3,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf2,perf3, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(3,:),'linewidth',1.5)
    corr(perf2,perf3,'rows','complete')
    
    minval = round(min([perf1;perf2;perf3],[],'all'),1)-0.1;
    xline(0.5,'--')
    yline(0.5,'--')
    
%     xlabel('Image Pair Proportion Correct','fontsize',15)
%     ylabel('Image Pair Proportion Correct','fontsize',15)
    xlim([minval 1])
    ylim([minval 1])
    xticks([0.5 1])
    yticks([0.5 1])
    ax = gca;
    ax.FontSize = 16;
    
elseif nShrews==2
    figure;hold on;
    p1 = perfMat{1}(:);perf1 = p1;
    p2 = perfMat{2}(:);perf2 = p2;
    perf1 = perf1(~isnan(p1) & ~isnan(p2));
    perf2 = perf2(~isnan(p1) & ~isnan(p2));
    scatter(perf1,perf2,50,...
        'marker','o',...
        'markeredgecolor',cmap(1,:),...
        'markerfacecolor',cmap(1,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf2, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(1,:),'linewidth',1.5)
    corr(perf1,perf2,'rows','complete')
    
    minval = round(min([perf1;perf2],[],'all'),1)-0.1;
    xline(0.5,'--')
    yline(0.5,'--')
    
%     xlabel('Image Pair Proportion Correct','fontsize',15)
%     ylabel('Image Pair Proportion Correct','fontsize',15)
    xlim([minval 1])
    ylim([minval 1])
    xticks([0.5 1])
    yticks([0.5 1])
    ax = gca;
    ax.FontSize = 16;
end
    
end

%% Look at correlations of target performance across shrews
% Initialize variables
sessions = table('Size',[10,4],...
    'VariableNames',{'sessionID','shrewID','shrewname','date'},...
    'VariableTypes',{'double','double','string','string'});

dataVars = {'T_Expt_ID','D_Expt_ID','correct','ctch'};
allTasks = {'Camel_v2_test_nn','Camel_novel_v2_test_nn','Camel_background_matrix'};

shrewname={'Seymour','Dominic','Ryker'};
cmap = [107,181,107;170,154,192;233,172,114] / 255;

big_Tab = [];
SID = 1;

for task = 1:length(allTasks)
big_Tab = [];
SID = 1;
bg_rows = find(strcmp(sheet_data.CODE, allTasks{task}));

% Just extracting the necessary columns, could also be adjusted if more
% info is needed
bgTab = sheet_data(bg_rows,contains(sheet_data.Properties.VariableNames,...
    {'TREESHREW','DATE','CODE','TARGET_IDs','DIST_IDs','TESTTARGETS'}));

% Load in corresponding files
pathname = split(pwd,filesep);
computer_path = [strjoin(pathname(1:3),'\'),filesep,'Box'];
file_dir = [char(computer_path) filesep 'Tree Shrews' filesep 'Analysis' filesep 'Kell_mats' filesep];

for i=1:height(bgTab)
    if exist([file_dir char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'])==2
        try
        load([file_dir filesep char(bgTab.TREESHREW{i}(1:2)) datestr(bgTab.DATE(i),'yyyymmdd') '_op.mat'],'opTab');
        end
        if sum(contains(opTab.Properties.VariableNames,dataVars))==length(dataVars)
        
            shrewID = find(strcmp(shrewname,bgTab.TREESHREW{i}));

            % this creates 'sessions' which has all the info needed for each
            % session (day)
            sessions.sessionID(SID) = SID;
            sessions.shrewID(SID) = shrewID;
            sessions.shrewname(SID) = bgTab.TREESHREW{i};
            sessions.date(SID) = datestr(bgTab.DATE(i));

            SessID = array2table([ones(height(opTab),1)*SID, ones(height(opTab),1)*shrewID, [1:height(opTab)]'],...
                'VariableNames',{'SessionID','ShrewID','Trial_in_sess'});

            temp_optab =[SessID opTab(:,contains(opTab.Properties.VariableNames,...
                dataVars))];

            % join temp_optab to big_tab
            % this creates 'big_Tab' which has all the individual trials
            big_Tab = [big_Tab; temp_optab];

            clear temp_optab opTab novelTD

            SID=SID+1; % increment session
        end
    end
end

nShrews = length(unique(big_Tab.ShrewID));
nTarg = length(unique(big_Tab.T_Expt_ID));
nDist = length(unique(big_Tab.D_Expt_ID));

shrewID = unique(big_Tab.ShrewID);
targID = unique(big_Tab.T_Expt_ID);
distID = unique(big_Tab.D_Expt_ID);

perfMat = {};
for s = 1:nShrews
    perfMat{s} = nan(1,nTarg);
    for tt = 1:nTarg
        if sum(big_Tab.ShrewID==shrewID(s) & big_Tab.T_Expt_ID==targID(tt)) >= 10
            perfMat{s}(tt) = mean(big_Tab.correct(big_Tab.ShrewID==shrewID(s) & big_Tab.T_Expt_ID==targID(tt)),'omitnan');
        end
    end
end


if nShrews==3
    p1 = perfMat{1}(:);perf1 = p1;
    p2 = perfMat{2}(:);perf2 = p2;
    perf1 = perf1(~isnan(p1) & ~isnan(p2));
    perf2 = perf2(~isnan(p1) & ~isnan(p2));
    figure;hold on;
    scatter(perf1,perf2,50,...
        'marker','o',...
        'markeredgecolor',cmap(1,:),...
        'markerfacecolor',cmap(1,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf2, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(1,:),'linewidth',1.5)
    disp([allTasks{task},': ',shrewname{1},' vs ',shrewname{2},', corr = ',num2str(corr(perf1,perf2,'rows','complete'))])
    
    p1 = perfMat{1}(:);perf1 = p1;
    p3 = perfMat{3}(:);perf3 = p3;
    perf1 = perf1(~isnan(p1) & ~isnan(p3));
    perf3 = perf3(~isnan(p1) & ~isnan(p3));
    scatter(perf1,perf3,50,...
        'marker','o',...
        'markeredgecolor',cmap(2,:),...
        'markerfacecolor',cmap(2,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf3, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(2,:),'linewidth',1.5)
    disp([allTasks{task},': ',shrewname{1},' vs ',shrewname{3},', corr = ',num2str(corr(perf1,perf3,'rows','complete'))])
    
    p2 = perfMat{2}(:);perf2 = p2;
    p3 = perfMat{3}(:);perf3 = p3;
    perf2 = perf2(~isnan(p2) & ~isnan(p3));
    perf3 = perf3(~isnan(p2) & ~isnan(p3));
    scatter(perf2,perf3,50,...
        'marker','o',...
        'markeredgecolor',cmap(3,:),...
        'markerfacecolor',cmap(3,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf2,perf3, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(3,:),'linewidth',1.5)
    disp([allTasks{task},': ',shrewname{2},' vs ',shrewname{3},', corr = ',num2str(corr(perf2,perf3,'rows','complete'))])
    
    minval = round(min([perf1;perf2;perf3],[],'all'),1)-0.1;
    xline(0.5,'--')
    yline(0.5,'--')
    
%     xlabel('Image Pair Proportion Correct','fontsize',15)
%     ylabel('Image Pair Proportion Correct','fontsize',15)
    xlim([minval 1])
    ylim([minval 1])
    xticks([0.5 1])
    yticks([0.5 1])
    ax = gca;
    ax.FontSize = 16;
    
elseif nShrews==2
    figure;hold on;
    p1 = perfMat{1}(:);perf1 = p1;
    p2 = perfMat{2}(:);perf2 = p2;
    perf1 = perf1(~isnan(p1) & ~isnan(p2));
    perf2 = perf2(~isnan(p1) & ~isnan(p2));
    scatter(perf1,perf2,50,...
        'marker','o',...
        'markeredgecolor',cmap(1,:),...
        'markerfacecolor',cmap(1,:),...
        'markerfacealpha',0.5,...
        'linewidth',1.1);
    coefficients = polyfit(perf1,perf2, 1);
    xFit = linspace(0, 2500, 1000);
    yFit = polyval(coefficients , xFit);
    plot(xFit,yFit,'color',cmap(1,:),'linewidth',1.5)
    disp([allTasks{task},': ',shrewname{1},' vs ',shrewname{2},', corr = ',num2str(corr(perf1,perf2,'rows','complete'))])
    
    minval = round(min([perf1,perf2],[],'all'),1)-0.1;
    
    xline(0.5,'--')
    yline(0.5,'--')
    
%     xlabel('Image Pair Proportion Correct','fontsize',15)
%     ylabel('Image Pair Proportion Correct','fontsize',15)
    xlim([minval 1])
    ylim([minval 1])
    xticks([0.5 1])
    yticks([0.5 1])
    ax = gca;
    ax.FontSize = 16;
end
    
end

