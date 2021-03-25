%   GPLv2 License
%
%   Copyright (c) 2020, Paul Botros, Marius Pachitariu
%   Copyright (c) 2020, Trustees of Columbia University in the City of New York.
%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License along
%   with this program; if not, write to the Free Software Foundation, Inc.,
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


% This is a modified version of main_kilosort.m.
% Original Source: https://github.com/MouseLand/Kilosort2/blob/master/main_kilosort.m

function kilosortbatch(ksdir,phydir,data,tmp,config,chanmap,numchans,start,stop,sig,fshigh,nblocks)
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
    if ~(exist('sig','var'))
        error(['sig not defined'])
    end
    if ~(exist('fshigh','var'))
        error(['fshigh not defined'])
    end
    if ~(exist('nblocks','var'))
        error(['nblocks not defined'])
    end

    % Silly CUDA 9 Error workaround (only happens on Turing and above cards)
    % See https://www.mathworks.com/matlabcentral/answers/437756-how-can-i-recompile-the-gpu-libraries
    % Program will break at the following line otherwise:
    % rez                = template_learning(rez, tF, st3);
    warning off parallel:gpu:device:DeviceLibsNeedsRecompiling
    try
	gpuArray.eye(2)^2;
    catch ME
    end
    try
        nnet.internal.cnngpu.reluForward(1);
    catch ME
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

    ops.sig        = sig;  % spatial smoothness constant for registration
    ops.fshigh     = fshigh; % high-pass more aggresively
    ops.nblocks    = nblocks; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

    % find the binary file
    fs          = [dir(fullfile(data, '*.bin')) dir(fullfile(data, '*.dat'))];
    ops.fbinary = fullfile(data, fs(1).name);
    

    rez                = preprocessDataSub(ops);
    rez                = datashift2(rez, 1);

    [rez, st3, tF]     = extract_spikes(rez);

    rez                = template_learning(rez, tF, st3);

    [rez, st3, tF]     = trackAndSort(rez);

    rez                = final_clustering(rez, tF, st3);

    rez                = find_merges(rez, 1);

    % save final results as rez2
    fprintf('Saving final results in phy \n')
    rezToPhy2(rez, data);
end
