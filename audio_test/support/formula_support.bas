const PI as double = 3.141592653589793238462643383279502884197#
const defaultThreshold as double = 0.86#

declare function fx_maxRadians() as double
declare function fx_ellipseX(a as integer, t as double) as integer
declare function fx_ellipseY(b as integer, t as double) as integer

declare function fx_blendSimple(currentProgress as double, threshold as double = defaultThreshold) as double
declare function fx_blendBezier(currentProgress as double) as double
declare function fx_blendParametric(currentProgress as double) as double
declare function fx_blendExponential(currentProgress as double, threshold as double = defaultThreshold) as double

function fx_maxRadians() as double
    return 2 * PI
end function

function fx_ellipseX(a as integer, t as double) as integer    
    return a * cos(t)
end function

function fx_ellipseY(b as integer, t as double) as integer    
    return b * sin(t)
end function

function fx_blendSimple(currentProgress as double, threshold as double = defaultThreshold) as double
    dim as double endProgress
    
    if (currentProgress <= threshold) then
        endProgress = 2.0# * currentProgress ^ 2
    else
        endProgress = 2.0# * currentProgress - threshold * (1.0# - currentProgress) + threshold
    end if
    
    return endProgress
end function

function fx_blendBezier(currentProgress as double) as double
    dim as double endProgress
    
    endProgress = currentProgress ^ 2 * (3.0# - 2.0# * currentProgress)
    
    return endProgress
end function

function fx_blendParametric(currentProgress as double) as double
    dim as double endProgress
    dim as double squared
    
    squared = currentProgress ^ 2
    endProgress = squared / (2.0# * (squared - currentProgress) + 1.0#)
    
    return endProgress
end function

function fx_blendExponential(currentProgress as double, threshold as double = defaultThreshold) as double
    dim as double endProgress, thresholdElapsed, thresholdProgress, newThresholdProgress, sqtp
    
    endProgress = 0
    if (currentProgress > threshold) then
        thresholdElapsed = (1.0# - threshold) - (1.0# - currentProgress)
        thresholdProgress = thresholdElapsed / (1.0# - threshold)
        sqtp = thresholdProgress ^ 2
        newThresholdProgress = sqtp / (2.0# * (sqtp - thresholdProgress) + 1.0#)
        endProgress = currentProgress + newThresholdProgress
    end if
    
    return endProgress
end function