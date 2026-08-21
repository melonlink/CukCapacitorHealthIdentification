function value = convergence_time(t, estimate, truth, toleranceFraction, holdCount)
%CONVERGENCE_TIME First time an estimate enters and remains in tolerance.

if nargin < 5, holdCount = 100; end
errorFraction = abs(estimate - truth) ./ max(abs(truth), eps);
value = NaN;
lastStart = numel(errorFraction) - holdCount + 1;
for k = 1:max(lastStart, 0)
    if all(errorFraction(k:k+holdCount-1) <= toleranceFraction)
        value = t(k) - t(1);
        return;
    end
end
end

