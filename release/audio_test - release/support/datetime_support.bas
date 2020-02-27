#include once "datetime.bi"

const MillisecondsPerDay as integer = 86400000

declare function datetime_now() as double
declare function datetime_elapsedMilliseconds(dt1 as double, dt2 as double) as integer

function datetime_now() as double
    return now
end function

function datetime_elapsedMilliseconds(dt1 as double, dt2 as double) as integer
    return int(abs(dt1 - dt2) * MillisecondsPerDay)
end function