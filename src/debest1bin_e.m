function [xmin, fmin, out] = debest1bin_e(fitfun, lb, ub, maxfunevals, options)
% DEBEST1BIN_E DE/BEST/1/BIN for experiments
% DEBEST1BIN_E(fitfun, lb, ub, maxfunevals) minimize the function fitfun in
% box constraints [lb, ub] with the maximal function evaluations
% maxfunevals.
% DEBEST1BIN_E(..., options) minimize the function by solver options.
%
% Copyright (C) 2014 Chin-Chang Yang
% See the license at https://github.com/SPS-DE/SPS-DE
if nargin <= 4
	options = [];
end

defaultOptions.NP = 100;
defaultOptions.F = 0.7;
defaultOptions.CR = 0.5;
defaultOptions.Display = 'off';
defaultOptions.RecordPoint = 100;
defaultOptions.ftarget = -Inf;
defaultOptions.TolStagnationIteration = Inf;
defaultOptions.initial.X = [];
defaultOptions.initial.f = [];

options = setdefoptions(options, defaultOptions);
F = options.F;
CR = options.CR;
isDisplayIter = strcmp(options.Display, 'iter');
RecordPoint = max(0, floor(options.RecordPoint));
ftarget = options.ftarget;
TolStagnationIteration = options.TolStagnationIteration;

D = numel(lb);

if ~isempty(options.initial)
	options.initial = setdefoptions(options.initial, defaultOptions.initial);
	X = options.initial.X;
	fx = options.initial.f;
else
	X = [];
	fx = [];
end

if isempty(X)	
	NP = options.NP;
else
	[~, NP] = size(X);
end

% Initialize variables
counteval = 0;
countiter = 1;
countStagnation = 0;
out = initoutput(RecordPoint, D, NP, maxfunevals, ...
	'FC', ...
	'mSFC', ... % Mean of successful FC
	'mFC'...	% Mean of all FC
	);

% Initialize contour data
if isDisplayIter
	[XX, YY, ZZ] = advcontourdata(D, lb, ub, fitfun);
end

% Initialize population
if isempty(X)
	X = zeros(D, NP);
	for i = 1 : NP
		X(:, i) = lb + (ub - lb) .* rand(D, 1);
	end
end

% Evaluation
if isempty(fx)
	fx = zeros(1, NP);
	for i = 1 : NP
		fx(i) = feval(fitfun, X(:, i));
		counteval = counteval + 1;
	end
end

% Sort
[fx, fidx] = sort(fx);
X = X(:, fidx);

% Initialize variables
V = X;
U = X;
fu = zeros(1, NP);
FC = zeros(1, NP);		% Consecutive Failure Counter
r1 = zeros(1, NP);
r2 = zeros(1, NP);
mSFC = 0;
mFC = 0;

% Display
if isDisplayIter
	displayitermessages(...
		X, U, fx, countiter, XX, YY, ZZ);
end

% Record
out = updateoutput(out, X, fx, counteval, countiter, ...
	'FC', FC, ...
	'mSFC', mSFC, ...
	'mFC', mFC);

% Iteration counter
countiter = countiter + 1;

while true
	% Termination conditions
	outofmaxfunevals = counteval > maxfunevals - NP;
	reachftarget = min(fx) <= ftarget;
	stagnation = countStagnation >= TolStagnationIteration;	
	if outofmaxfunevals || reachftarget || stagnation
		break;
	end
	
	for i = 1 : NP		
		% Generate r1
		r1(i) = floor(1 + NP * rand);
		while i == r1(i)
			r1(i) = floor(1 + NP * rand);
		end
		
		% Generate r2
		r2(i) = floor(1 + NP * rand);
		while i == r2(i) || r1(i) == r2(i)
			r2(i) = floor(1 + NP * rand);
		end
	end
	
	% Mutation
	[~, best] = min(fx);
	for i = 1 : NP		
		V(:, i) = X(:, best) + ...
			F .* (X(:, r1(i)) - X(:, r2(i)));
	end
	
	for i = 1 : NP
		% Binominal Crossover
		jrand = floor(1 + D * rand);
		for j = 1 : D
			if rand < CR || j == jrand
				U(j, i) = V(j, i);
			else
				U(j, i) = X(j, i);
			end
		end
	end
	
	% Correction for outside of boundaries
	for i = 1 : NP
		for j = 1 : D
			if U(j, i) < lb(j)
				U(j, i) = 0.5 * (lb(j) + X(j, i));
			elseif U(j, i) > ub(j)
				U(j, i) = 0.5 * (ub(j) + X(j, i));
			end
		end
	end
	
	% Display
	if isDisplayIter
		displayitermessages(...
			X, U, fx, countiter, XX, YY, ZZ);
	end
	
	% Evaluation
	for i = 1 : NP
		fu(i) = feval(fitfun, U(:, i));
		counteval = counteval + 1;
	end
	
	% Selection
	FailedIteration = true;
	S_SFC = [];
	mFC = mean(FC);
	for i = 1 : NP		
		if fu(i) < fx(i)
			X(:, i)		= U(:, i);
			fx(i)		= fu(i);
			FailedIteration = false;
			S_SFC		= [S_SFC, FC(i)];
			FC(i)		= 0;
		else
			FC(i) = FC(i) + 1;
		end
	end
	
	if ~isempty(S_SFC)
		mSFC = mean(S_SFC);
	end
	
	% Sort	
	[fx, fidx] = sort(fx);
	X = X(:, fidx);
	FC = FC(fidx);
	
	% Record
	out = updateoutput(out, X, fx, counteval, countiter, ...
		'FC', FC, ...
		'mSFC', mSFC, ...
		'mFC', mFC);
	
	% Iteration counter
	countiter = countiter + 1;
	
	% Stagnation iteration
	if FailedIteration
		countStagnation = countStagnation + 1;
	else
		countStagnation = 0;
	end	
end

[fmin, minindex] = min(fx);
xmin = X(:, minindex);

out = finishoutput(out, X, fx, counteval, countiter, ...
	'FC', zeros(NP, 1), ...
	'mSFC', mSFC, ...
	'mFC', mFC);
end
