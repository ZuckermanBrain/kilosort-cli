%   GPLv2 License
%
%   Copyright (c) 2020, Jennifer Colonell, Marius Pachitariu
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


% This is a modified version of main_eMouse_drift.m.
% Original Source: https://github.com/MouseLand/Kilosort2/blob/master/eMouse_drift/main_eMouse_drift.m

function makeemousebatch(ksdir, data, numchans)
	useGPU = 1; % eMouse can run w/out GPU, but KS2 cannot.
	useParPool = 0; % with current version, always faster wihtout parPool

	if ~exist(data, 'dir'); mkdir(data); end

	% add paths to the matlab path
	addpath(genpath(ksdir)); % path to kilosort2 folder

	% path to config file; if running the default config, no need to change.
	config = fullfile(ksdir,'eMouse_drift','config_eMouse_drift_KS2.m'); % path to config file

	% Create the channel map for this simulation; default is a small 64 site
	% probe with imec 3A geometry.
	chanMapName = make_eMouseChannelMap_3B_short(data, numchans);

	% Run the configuration file, it builds the structure of options (ops)

	run(config);


	% This part simulates and saves data. There are many options you can change inside this 
	% function, if you want to vary the SNR or firing rates, # of cells, etc.
	% There are also parameters to set the amplitude and character of the tissue drift. 
	% You can vary these to make the simulated data look more like your data
	% or test the limits of the sorting with different parameters.

	make_eMouseData_drift(data, ksdir, chanMapName, useGPU, useParPool);
end
