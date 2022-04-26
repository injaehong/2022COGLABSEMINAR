% 2022 HUITHROUGH MATHROUGH COGLAB DATA ANALYSIS & STAT SEMINAR
% sample experiment & data: Hong, I., Jeong, S. K., & Kim, M. S. (2022). Implicit learning of a response-contingent task. Attention, Perception, & Psychophysics, 84, 540-552.
% Data sets are available at github: https://github.com/injaehong/2022COGLABSEMINAR 
% contact: Injae Hong, injae.hong@yonsei.ac.kr

%% -------------------- SET UP -------------------- %%
clear all; % clear all variables in the work space
clc; % clear all texts in the command window
ClockRandSeed(12345); % define random seed first to ensure replicability

%----- Load Files
fileList = dir('ResponseCue_*.mat'); % the ANALYZER should be included in the same folder as the data. If not, add directory with the file name.
fileN = size(fileList, 1); % How many files?

% Now, let's load and do first-level analysis for each file.
for fileP = 1:fileN 

    load(fileList(fileP).name); % load nth file among file lists
    expName = fileList(fileP).name;
    disp(expName); % let's check the file name. This code is very useful when you have some errors in the mat file. (e.g., no RAWDATA)
    
    %% -------------------- LABELING -------------------- %%
    % We will use 'RAWDATA' variable for the data analysis, which has no labels on its top.
    % It's okay, because we already know which column means which factor.
    % We will separate the matrix to columns and label each to recognize them easily.

    %---------- Experiment Indexing ----------%
    if strncmpi(expName, 'ResponseCue_control', 13) == 1 % if the first 13 letters of the expName matches the string, then it is control experiment.
        expNum = 1; % control
    else % if it doesn't match, then the data set is from the response-contingent group.
        expNum = 2; % response-contingent
    end

    % For me, there are two different names and experiment tag(expNum) was not originally included in the mat file,
    % so, I created the experiment tag with the code above.
    % In most of the case, this kind of work would not be needed!

    % %%%%%%%%%%~~~~~~~~~~~LABEL ZONE~~~~~~~~~~%%%%%%%%%%
    % copy & paste your rawdata writing line. It is very useful!
    % RAWDATA(T,:) = [T, blockT, taskT, respT, numT, numStim, respKey, RT, respCor];
    % %%%%%%%%%%~~~~~~~~~~~LABEL ZONE~~~~~~~~~~%%%%%%%%%%

    DATA = RAWDATA; % copy the rawdata. We will leave the rawdata as it is, and use the copied one instead.

    % Label each column. You can refer to the copied and pasted line above.
    TT        = DATA(:,1); %trial number
    blockTT   = DATA(:,2); %block number
    taskTT    = DATA(:,3); % task; 1= parity 2= magnitude
    respTT    = DATA(:,4); % required response; 1= left, 2= right
    balTT     = DATA(:,5); % number balancing (This was for the controlling purpose.)
    stimTT    = DATA(:,6); % number stimulus used
    respKeyTT = DATA(:,7); % key pressed; 1= left, 2= right
    RTT       = DATA(:,8); % reaction time
    resp_Ans  = DATA(:,9); % correctness; 1= correct, 0= incorrect(wrong)
    DATA(:,10) = 1; % Make a new column to label RTUse(Are you going to use all trials? or Are you excluding several trials?) with 1s filled. As a default, RTUse is 1 (use all trials)
    DATA(:,11) = 99; % Count task performed

    %---------- RT Trimming ----------%
    DATA(RTT > 10, 10) = 0; %For several rows with RTT above trimming Limit(e.g., 10s), change the 10th column of the row to 0, which means "I won't use the trials's RT").
    RTUse = DATA(:,10); % name 10th column as 'RTUse'.
    % if you don't include these two lines, you will use every RTs.
    
    %---------- Preformed Task Index ----------%
    % : quality check for Testing Phase
    % For me, I checked the data quality with the number of actual taskss conducted in the testing phase.
    % This kind of works is very very important, because poor quality of data does not guarantee good results.

    for TN = 1:length(DATA)
        DATA((RTUse == 1 & TT == TN & resp_Ans == 1),11) = taskTT(TN); % if trial was correct, it means that they have conducted the response-contingent task.
        DATA((RTUse == 1 & TT == TN & resp_Ans == 0),11) = 3-taskTT(TN); % if the trial was incorrect, it means that they have conducted wrong task.
        % this kind of checking is conducted line by line (I mean, trial by trial).
        % So, don't forget to include (TN) with taskTT! taskTT is a 720 x 1 size matrix, not a single value.
    end

    taskUse = DATA(:,11);

    %---------- Phase Index ----------%
    % In my case, I have only block index, and now I need to divide the blocks into phases (training phase, testing phase).
    DATA(:,12) = 2;
    DATA([1:blockSize*(block-1)],12) = 1; %training phase
    % DATA([blockSize*(block)+1:end],12) = 2; %testing phase
    phaseTT = DATA(:,12);

    % Think of these primary works that should be done before the 1st-level analysis.
    % If you need phase index but if you don't have (like the phase index in my case), reconstruct it!
    % If you cannot technically reconstruct important variable you need, that's a pity!

    %---------- Participant Number Matrix ----------%
    % This is my style... I save participant information as a separate matrix, and put this at anywhere I need.
    info(fileP,:) = [str2num(Ptag), str2num(Stag), expNum];

    
    %% -------------------- Quality Check -------------------- %%
    % This part is super important... Don't forget to make a qualification check!
    % Participants are not under your control. They sometimes (in fact, usually) make weird and unexpected behaviors...
    % So let's screen them out, and we need evidence for participant exclusion.
    %
    % How do you measure the quality? It depends on your design!
    % In my case, I measured the total experiment time, the total RTs in use, and the number of
    % tasks selected in the testing phase (see above).
    % (RT info is useful, because you can screen out some too-slow-responsers or too-fast-responsers).
    % Do the quality check before you look into accuracy and RT data.

    %---------- Experiment Time ----------%
    QUAL.exptimes(fileP,1)= EXPTIME;
    QUAL.ttimes(fileP,1) = sum(RTT);

    %---------- TrialInUse Index ----------%
    for blk = 1:25
        countUse = mean(RTUse(blockTT == blk)); %RTUse can be found in line 58.
        numUseTrials(fileP, blk) = countUse;
    end


    %% -------------------- BEGIN ANALYSIS -------------------- %%
    %Let's make descriptive values for each participant.
    % One participant would have one total accuracy, one total RT, one block1 accuracy, one block2 accuracy....
    % All the values are obtained from one participant, and the values can be retrieved from a DATA matrix.
    %
    %The basic structure that you should remember is
    % "mean(VARIABLE_OF_INTEREST(CONSIDER1 == 1 & CONSIDER2 == 2 & CONSIDER3 == 3))"
    % This format consists most of the analyzer!!!
    %
    % What information do you need? You will need accuracy and RT's summary value, basically.
    % I prefer to use 'structure' to segregate dependent variables. So, I made 'ACC' and 'ReT' structures, and put sub-variables into the structures.
    % Advantage of it? Structure provides you an overall view of DVs.
    % When you open 'ACC' structure, you can access all DVs that are related to accuracy.
    % If you don't use structure, you need to find 'ACC_total', then 'ACC_block' independently,
    % which is very annoying, when you have many many variables to check.


    %---------- TOTAL: ACC & RT ----------%
    ACC.BLK(fileP,1) = mean(resp_Ans(RTUse == 1 & blockTT ~= 25));
    ReT.BLK(fileP,1) = mean(RTT(RTUse == 1 & resp_Ans == 1 & blockTT ~= 25))*1000;

    %---------- BLOCK: ACC & RT ----------%
    % Let's calculate accuracy and RT by each block. Use FOR loop to avoid annoying 25 lines (because there are 25 blocks).
    for blk = 1:25
        % 1st column of ACC.BLK is occupied by total accuracy(lines above).
        % So, we will insert block RTs in columns 2 ~ 26.
        ACC.BLK(fileP,blk+1) = mean(resp_Ans(blockTT == blk & RTUse == 1));
        ReT.BLK(fileP,blk+1) = mean(RTT(blockTT == blk & RTUse == 1)) * 1000;
    end

    % QUIZ!
    % Let's make by-phase RT summaries. How can you do that?
   

    % I prefer to make a single ANALYSIS matrix, and that's why I created 'info' matrix in line 88. 
    % I put all the lines I need into one matrix, and save only ANALYSIS mat into a csv file.
    % In fact, the DV of my interest was accuracy, so I only put accuracies in the analysis mat. 
    ANALYSIS(fileP,:) = [info(fileP,:), ACC.BLK(fileP,1), ReT.BLK(fileP,1), ACC.BLK(fileP,[2:end])];

    % header names:
    %     SN, Stag, expNum, totalAcc, totalRT, Acc_1, Acc_2, Acc_3, Acc_4 ...
  
    % This process will be repeated until you scan the final data set. When you are done, the ANALYSIS mat now will be N x M matrix.
    % If you want to test your code line by line, don't run the loop(from for fileP = 1:fileN, line 16), 
    % but run each line right after you define fileP = 1).
    % The code you generated will not be perfect at first hand.
    % Debug the lines before you finalize your code execution.
    % Check if the summary values are real(?).
    % See if you have NaN in some cells.
    % See if you have some repeated values...
end

% remove all variables except for several ones you need.
clearvars -except ACC ReT num SUMM ST numUseTrials QUAL info ANALYSIS DATA

% Now, you copy & past ANALYSIS values to your excel, and save it as a csv file.
% If you are upgraded, you will learn by yourself how to create a csv file with headers included with several matlab codes!

% % % % Make a header list.
% % % Names = {'SN',  'Stag', 'expNum', 'totalACC', 'totalRT', 'acc1', 'acc2', 'acc3', 'acc4', 'acc5', 'acc6', 'acc7', 'acc8', 'acc9', 'acc10',...
% % %     'acc11', 'acc12', 'acc13', 'acc14', 'acc15', 'acc16', 'acc17', 'acc18', 'acc19', 'acc20',...
% % %     'acc21', 'acc22', 'acc23', 'acc24', 'acc25'};
% % % 
% % % % separate the ANALYSIS columns and label them.
% % % % This code will generate 30 columns from A1 to A30
% % % for N = 1:30 %size of the Names
% % %     eval(['A', num2str(N), '= ANALYSIS(:,N);']);
% % % end
% % % 
% % % % combined separated names together as a table
% % % Analysis_csv = table(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10,...
% % %     A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, ...
% % %     A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, 'VariableNames', Names);
% % % 
% % % TotalTable = Analysis_csv;
% % % TotalName = ['ResponseCue_makecsvtest.csv'];
% % % writetable(TotalTable, TotalName); type = TotalName;
% % % 
% % % clearvars -except ACC ReT num SUMM ST numUseTrials QUAL info ANALYSIS DATA


%Answer to QUIZ
% ReT.PHASE(fileP,1) = mean(RTT(RTUse == 1 & respAns == 1 & phaseTT == 1)) * 1000;
% ReT.PHASE(fileP,2) = mean(RTT(RTUse == 1 & respAns == 2 & phaseTT == 2)) * 1000;