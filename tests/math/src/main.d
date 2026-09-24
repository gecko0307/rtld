module main;

import rtld;
import rtld.math.fallback;

void main()
{
    assert(copysignFallback( 3.0,  -1.0) == -3.0);
    assert(copysignFallback(-3.0,   1.0) ==  3.0);
    assert(copysignFallback( 3.0f, -0.0f) == -3.0f);
    assert(signbitFallback(copysignFallback(0.0, -0.0)));
    assert(!signbitFallback(copysignFallback(-0.0L, 2.0L)));
    assert(copysignFallback(double.infinity, -1.0) == -double.infinity);
}
