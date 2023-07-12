function output = ahby_problem(param) 
% find the nearest initial param and make the actuation as fluent input


    if exist('save_runs/database.mat') == 2
        load('save_runs/database.mat')
        [existedFlag,existedIndex] = ismember(param, database(:,1:end-1), 'rows');
    else 
        database = [];
        existedFlag = false;
    end       
    if existedFlag
        output = database(existedIndex,end);    
    else
        
    %% Initialization.    
        % The input parameter limits are all [0 1]
        limUP_amp = 60*ones(1,5);
        limLOW_amp = 0*ones(1,5);
        limUP_dg = [90 90 145 90 90];
        limLOW_dg = [-35 -90 -90 -90 -90];    
        limUP_amp_dg = [limUP_amp limUP_dg];
        LimLOW_amp_dg = [limLOW_amp limLOW_dg];

        cd ..\Ahby_rans
        basC = load('basic.mat');%to adjust
    %% Decide the nearest basic condition.    
        [loc_ngb,~] = knnsearch(basC.basic,param);    

    %% Transfer the parameters and denote the condition.
    % For param
        param = round(param.*(limUP_amp_dg-LimLOW_amp_dg)+LimLOW_amp_dg);
        paramName = num2str(param(1));
        for i =2:length(param)
            paramName = [paramName,'_',num2str(param(i))];
        end

    % For basic condition  
        param_base = basC.basic(loc_ngb,:);
        param_base = round(param_base.*(limUP_amp_dg-LimLOW_amp_dg)+LimLOW_amp_dg);
        baseName = num2str(param_base(1));
        for i =2:length(param_base)
            baseName = [baseName,'_',num2str(param_base(i))];
        end

    %% change journal files    
          if exist(['CasDat\cd-',paramName,'.txt']) ~= 2
            cd Jou%%%%
            copyfile('standard.jou', [paramName,'.jou']);

            fidr = fopen([paramName,'.jou'],'r+');
            i = 0;
            while ~feof(fidr)
                tline = fgetl(fidr);
                i = i+1;    
                newtline{i} = tline; 
            end
            fclose(fidr);

%             newtline{1} = ['rcd D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\',baseName,'.cas'];
            newtline{1} = 'rcd D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\0_0_0_0_0_0_0_0_0_0.cas';

            for i = 1:5
                if param(i) == 0                    
                   if i==1 || i==3 || i==5
                      newtline{5+9*(i-1)/2} = 'wall';
                      for j = 25+60*(i-1)/2:25+60*(i-1)/2+18                     
                          newtline{j} = '';
                      end
                   else
                       newtline{8+9*(i-2)/2} = 'wall';
                       newtline{8+9*(i-2)/2+3} = 'wall';
                      for j = 45+60*(i-2)/2:45+60*(i-2)/2+18                     
                          newtline{j} = '';
                      end
                      for j = 65+60*(i-2)/2:65+60*(i-2)/2+18                     
                          newtline{j} = '';
                      end
                   end
                else
                    if i==1 || i==3 || i==5
                        uParam = round(param(i)*cos(param(i+5)/180*pi));
                        wParam = round(param(i)*sin(param(i+5)/180*pi));
                        newtline{34+60*(i-1)/2} = num2str(uParam);%u
                        newtline{34+60*(i-1)/2+4} = num2str(wParam);%w
                    end
                    if i==2 || i==4
                        uParamL = round(param(i)*cos(-param(i+5)/180*pi));
                        vParamL = round(param(i)*sin(-param(i+5)/180*pi));
                        uParamR = round(param(i)*cos(param(i+5)/180*pi));
                        vParamR = round(param(i)*sin(param(i+5)/180*pi));
                        newtline{54+60*(i-2)/2} = num2str(uParamL);%left u
                        newtline{56+60*(i-2)/2} = num2str(vParamL);%left v
                        newtline{74+60*(i-2)/2} = num2str(uParamR);%right u
                        newtline{76+60*(i-2)/2} = num2str(vParamR);%right v
                    end
                end
            end

            newtline{172} = ['D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\cl-',paramName,'.txt'];
            newtline{186} = ['D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\cd-',paramName,'.txt'];
            newtline{205} = ['D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\cdp-a12-',paramName,'.txt'];
            newtline{220} = ['D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\cdp-a345-',paramName,'.txt'];
            newtline{226} = ['"D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\',paramName,'"'];
            newtline{230} = ['wcd D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\CasDat\',paramName,'.cas'];

            fidw = fopen([paramName,'.jou'],'w+');
            for j = 1:length(newtline)
                fprintf(fidw,'%s\r\n',newtline{j});
            end
            fclose(fidw);
            command = ['"C:\ProgramFiles\ANSYS Inc\v202\fluent\ntbin\win64\fluent.exe"  3d -g -t100 -i "D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\Jou\',paramName,'.jou"'];% -o "D:\ComputationHERE\TUMCAI\AhbyEGM\0.txt"'];
            system([command, '> NUL']);   
            cd ..\              
          end

    % start CFD and read journal to compute   
    %   read the result of CFD  
        while 1
          if exist('restartCFD','file') == 2          
            command = ['"C:\ProgramFiles\ANSYS Inc\v202\fluent\ntbin\win64\fluent.exe"  3d -g -t100 -i "D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\Jou\',paramName,'.jou"'];% -o "D:\ComputationHERE\TUMCAI\AhbyEGM\0.txt"'];
            system([command, '> NUL']);
            delete('restartCFD')
          end
          cd CasDat\
          if exist(['cd-',paramName,'.txt']) == 2
              if exist('countlines.pl','file')~=2
                 fid=fopen('countlines.pl','w');
                 fprintf(fid,'%s\n%s','while(<>) {};','print $.,"\n";');
                 fclose(fid);
              end
              row = str2double(perl('countlines.pl', ['cd-',paramName,'.txt']) );
              if row < 4004
                delete(['cl-',paramName,'.txt']);
                delete(['cd-',paramName,'.txt']);
                delete(['cdp-a12-',paramName,'.txt']);
                delete(['cdp-a345-',paramName,'.txt']);
                delete([paramName,'.cas']);
                delete([paramName,'.dat']);
                command = ['"C:\ProgramFiles\ANSYS Inc\v202\fluent\ntbin\win64\fluent.exe"  3d -g -t100 -i "D:\ComputationHERE\TUMCAI\AhbyEGM\Ahby_rans\Jou\',paramName,'.jou"'];% -o "D:\ComputationHERE\TUMCAI\AhbyEGM\0.txt"'];
                system([command, '> NUL']);  
              end
              fidr0 = fopen(['cd-',paramName,'.txt'],'r');
              output0 = dlmread(['cd-',paramName,'.txt'],' ',[4002 1 4002 1]);
              fclose(fidr0);
              fidr1 = fopen(['cdp-a12-',paramName,'.txt'],'r');
              output1 = dlmread(['cdp-a12-',paramName,'.txt'],' ',[4002 1 4002 1]);
              fclose(fidr1);
              fidr2 = fopen(['cdp-a345-',paramName,'.txt'],'r');
              output2 = dlmread(['cdp-a345-',paramName,'.txt'],' ',[4002 1 4002 1]);
              fclose(fidr2);
              output = output0+output1+output2;
              if exist([paramName,'.dat']) == 2          
                delete([paramName,'.dat'])
                delete([paramName,'.cas'])
              end
              break;
          end
        end
        cd ..\..\EGM_v0.1.4.1
    end
    database = [database; param output];
    save('save_runs/database.mat', 'database')
end 
