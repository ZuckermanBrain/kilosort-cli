% This is a modified version of main_kilosort.m.
% https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m
% As such it is released under the GPLv2.
% Modifications are Copyright (c) 2020, Trustees of Columbia University in the City of New York.

function kilosortbatch(ksdir,phydir,data,tmp,config,chanmap,numchans,start,stop)
    % Sanity checks
    if ~(exist('ksdir','var'))
        error(['ksdir not defined'])
    end
    if ~(exist('phydir','var'))
        error(['phydir not defined'])
    end
    if ~(exist('data','var'))
        error(['data not defined'])
    end
    if ~(exist('tmp','var'))
        error(['tmp not defined'])
    end
    if ~(exist('config','var'))
        error(['config not defined'])
    end
    if ~(exist('chanmap','var'))
        error(['chanmap not defined'])
    end
    if ~(exist('numchans','var'))
        error(['numchans not defined'])
    end
    if ~(exist('start','var'))
        error(['start not defined'])
    end
    if ~(exist('stop','var'))
        error(['stop not defined'])
    end

    % Actual program here.
    % Import dependencies.
    addpath(genpath(ksdir));
    addpath(phydir);
    
    % Set up config.
    ops.trange = [ start stop ];
    ops.NchanTOT = numchans;
    run(config);
    ops.fproc = fullfile(tmp, 'temp_wh.dat');
    ops.chanMap = chanmap;
    
    % Run Kilosort
    fprintf('Looking for data inside %s \n', data);
    fs = dir(fullfile(data, 'chan*.mat'));
    if ~isempty(fs)
    	ops.chanMap = fullfile(data, fs(1).name);
    end

    % find the binary file
    fs          = [dir(fullfile(data, '*.bin')) dir(fullfile(data, '*.dat'))];
    ops.fbinary = fullfile(data, fs(1).name);
    
    % preprocess data to create temp_wh.dat
    rez = preprocessDataSub(ops);
    
    % time-reordering as a function of drift
    rez = clusterSingleBatches(rez);
    
    % saving here is a good idea, because the rest can be resumed after loading rez
    save(fullfile(data, 'rez.mat'), 'rez', '-v7.3');
    
    % main tracking and template matching algorithm
    rez = learnAndSolve8b(rez);
    
    % final merges
    rez = find_merges(rez, 1);
    
    % final splits by SVD
    rez = splitAllClusters(rez, 1);
    
    % final splits by amplitudes
    rez = splitAllClusters(rez, 0);
    
    % decide on cutoff
    rez = set_cutoff(rez);
    
    fprintf('found %d good units \n', sum(rez.good>0))
    
    % write to Phy
    fprintf('Saving results to Phy  \n')
    rezToPhy(rez, data);
    
    %% if you want to save the results to a Matlab file...
    
    % discard features in final rez file (too slow to save)
    rez.cProj = [];
    rez.cProjPC = [];
    
    % final time sorting of spikes, for apps that use st3 directly
    [~, isort]   = sortrows(rez.st3);
    rez.st3      = rez.st3(isort, :);
    
    % Ensure all GPU arrays are transferred to CPU side before saving to .mat
    rez_fields = fieldnames(rez);
    for i = 1:numel(rez_fields)
        field_name = rez_fields{i};
        if(isa(rez.(field_name), 'gpuArray'))
            rez.(field_name) = gather(rez.(field_name));
        end
    end
    
    % save final results as rez2
    fprintf('Saving final results in rez2  \n')
    fname = fullfile(data, 'rez2.mat');
    save(fname, 'rez', '-v7.3');
end
