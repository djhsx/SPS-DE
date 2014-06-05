function metafilename = run_complete_cec11(nruns)
%
% Copyright (C) 2014 Chin-Chang Yang
% See the license at https://github.com/SPS-DE/SPS-DE

if matlabpool('size') == 0
	matlabpool('open');
end

solvers = {...
	'derand1bin', 'derand1bin_sps', ...
	'debest1bin', 'debest1bin_sps', ...
	'dcmaeabin', 'dcmaea_sps', ...
	'deglbin', 'degl_sps', ...
	'jadebin', 'jade_sps', ...
	'rbdebin', 'rbde_sps', ...
	'sadebin', 'sade_sps', ...
	'shade', 'shade_sps'};
Q = 32;
measureOptions.Runs = nruns;
solverOptions.F = 0.7;
solverOptions.CR = 0.5;
solverOptions.RecordPoint = 21;
solverOptions.ftarget = -inf;
solverOptions.TolX = 0;
solverOptions.TolStagnationIteration = Inf;

filenames = cell(numel(Q), numel(solvers));
outsidedate = datestr(now, 'yyyymmddHHMM');
metafilename = sprintf('filenames_%s.mat', outsidedate);
for isolver = 1 : numel(solvers)
	for iQ = 1 : numel(Q)
		startTime = tic;
		innerdate = datestr(now, 'yyyymmddHHMM');
		solver = solvers{isolver};
		solverOptions.Q = Q(iQ);
		[allout, allfvals, allfes] = complete_cec11(...
			solver, ...
			measureOptions, ...
			solverOptions); %#ok<*NASGU,*ASGLU>
		
		elapsedTime = toc(startTime);
		if elapsedTime < 60
			fprintf('Elapsed time is %f seconds\n', elapsedTime);
		elseif elapsedTime < 60*60
			fprintf('Elapsed time is %f minutes\n', elapsedTime/60);
		elseif elapsedTime < 60*60*24
			fprintf('Elapsed time is %f hours\n', elapsedTime/60/60);
		else
			fprintf('Elapsed time is %f days\n', elapsedTime/60/60/24);
		end
		
		filenames{iQ, isolver} = sprintf('cec11_%s_Q%d_%s.mat', ...
			solver, solverOptions.Q, innerdate);
		save(filenames{iQ, isolver}, ...
			'allout', ...
			'allfvals', ...
			'allfes', ...
			'solver', ...
			'measureOptions', ...
			'solverOptions', ...
			'elapsedTime');
	end
	
	save(metafilename, 'filenames');
end
