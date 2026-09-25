module main;

import rtld;
import rtld.math.fallback;

alias TSeq(A...) = A;
alias TFloatTypes = TSeq!(float, double, real);

// Built via copysignFallback so the compiler can't fold away the sign.
T negZero(T)() { return copysignFallback(cast(T) 0, cast(T) -1); }
T negNaN(T)()  { return copysignFallback(T.nan,     cast(T) -1); }

bool approx(A, B)(A got, B want, real relTol = 1e-9, real absTol = 0)
{
    immutable real g = got, w = want;
    if (g != g || w != w)
        return false;
    if (g == w)
        return true;
    if (isInfinity(g) || isInfinity(w))
        return false;
    immutable real d = abs(g - w);
    return d <= relTol * abs(w) || d <= absTol;
}

T pow2(T)(int n)
{
    T r = 1;
    if (n >= 0) foreach (i; 0 .. n)  r *= 2;
    else        foreach (i; 0 .. -n) r /= 2;
    return r;
}

// Tolerance for tests whose expected value is only known to double precision
enum real loose(T) = T.mant_dig <= 24 ? 1e-6L : 1e-14L;

void main()
{
    // abs
    {
        assert(absFallback(-5) == 5);
        assert(absFallback(5) == 5);
        assert(absFallback(0) == 0);
        assert(absFallback(int.min + 1) == int.max);
        assert(absFallback(-2.5) == 2.5);
    }
    
    // copysign
    {
        assert(copysignFallback( 3.0,  -1.0) == -3.0);
        assert(copysignFallback(-3.0,   1.0) ==  3.0);
        assert(copysignFallback( 3.0f, -0.0f) == -3.0f);
        assert(signbitFallback(copysignFallback(0.0, -0.0)));
        assert(!signbitFallback(copysignFallback(-0.0L, 2.0L)));
        assert(copysignFallback(double.infinity, -1.0) == -double.infinity);
    }
    
    // fabs
    static foreach (T; TFloatTypes)
    {{
        assert(fabsFallback(cast(T) -3.5) == 3.5);
        assert(fabsFallback(cast(T)  3.5) == 3.5);
        assert(fabsFallback(cast(T)  0)   == 0);
        assert(!signbitFallback(fabsFallback(cast(T)0)));
        assert(!signbitFallback(fabsFallback(negZero!T)));
        assert(fabsFallback(-T.infinity) == T.infinity);
        assert(fabsFallback(T.max) == T.max);
        assert(fabsFallback(-T.max) == T.max);
        assert(isNaN(fabsFallback(T.nan)));
        auto n = fabsFallback(negNaN!T); // sign bit of a NaN must be cleared too
        assert(isNaN(n) && !signbitFallback(n));
    }}
    
    // sqrt
    {
        assert(sqrtFallback(0.0) == 0 && !signbitFallback(sqrtFallback(0.0)));
        assert(signbitFallback(sqrtFallback(negZero!double))); // IEEE 754: sqrt(-0) == -0
 
        assert(approx(sqrtFallback(1.0),  1.0, 1e-15));
        assert(approx(sqrtFallback(4.0),  2.0, 1e-15));
        assert(approx(sqrtFallback(0.25), 0.5, 1e-15));
        assert(approx(sqrtFallback(2.0),  1.41421356237309504880, 1e-15));
        assert(approx(sqrtFallback(1e300),  1e150,  1e-14));
        assert(approx(sqrtFallback(1e-300), 1e-150, 1e-14));
        assert(approx(sqrtFallback(double.max), 1.3407807929942596e154, 1e-14));
 
        // subnormal input: 2^-1024 -> 2^-512
        assert(approx(sqrtFallback(double.min_normal / 4), pow2!double(-512), 1e-14));
 
        foreach (i; 1..1000) // perfect squares
            assert(approx(sqrtFallback(cast(double)(i * i)), i, 1e-15));
 
        assert(sqrtFallback(double.infinity) == double.infinity);
        assert(isNaN(sqrtFallback(-1.0)));
        assert(isNaN(sqrtFallback(-double.infinity)));
        assert(isNaN(sqrtFallback(double.nan)));
 
        assert(approx(sqrtFallback(9.0f), 3.0f, 1e-6));
        assert(approx(sqrtFallback(2.0L), 1.41421356237309504880L, 1e-15));
    }

    // sin
    {
        assert(sinFallback(0.0) == 0);
        assert(signbitFallback(sinFallback(negZero!double))); // sin(-0) == -0
        assert(approx(sinFallback(PI / 6), 0.5, 1e-12));
        assert(approx(sinFallback(PI / 2), 1.0, 1e-12));
        assert(approx(sinFallback(PI), 0.0, 0, 1e-15));
        assert(approx(sinFallback(-PI / 2), -1.0, 1e-12));
        assert(approx(sinFallback(1.0), 0.8414709848078965, 1e-12));
        assert(approx(sinFallback(-1.0), -0.8414709848078965, 1e-12));
        assert(approx(sinFallback(1e6), -0.3499935021712930, 1e-6)); // argument reduction
        assert(isNaN(sinFallback(double.infinity)));
        assert(isNaN(sinFallback(-double.infinity)));
        assert(isNaN(sinFallback(double.nan)));
        assert(approx(sinFallback(1.0f), 0.84147098f, 1e-6));
    }
    
    // cos
    {
        assert(cosFallback(0.0) == 1);
        assert(cosFallback(negZero!double) == 1);
        assert(approx(cosFallback(PI / 3), 0.5, 1e-12));
        assert(approx(cosFallback(PI / 2), 0.0, 0, 1e-15));
        assert(approx(cosFallback(PI), -1.0, 1e-12));
        assert(approx(cosFallback(1.0), 0.5403023058681398, 1e-12));
        assert(approx(cosFallback(-1.0), 0.5403023058681398, 1e-12));
        assert(approx(cosFallback(1e6), 0.9367521275331447, 1e-6));

        assert(isNaN(cosFallback(double.infinity)));
        assert(isNaN(cosFallback(-double.infinity)));
        assert(isNaN(cosFallback(double.nan)));

        assert(approx(cosFallback(1.0f), 0.5403023f, 1e-6));
    }
    
    // tan
    {
        assert(tanFallback(0.0) == 0);
        assert(signbitFallback(tanFallback(negZero!double)));
        assert(approx(tanFallback(PI / 4),  1.0, 1e-12));
        assert(approx(tanFallback(-PI / 4), -1.0, 1e-12));
        assert(approx(tanFallback(PI / 6),  0.57735026918962576451, 1e-12));
        assert(approx(tanFallback(1.0), 1.5574077246549023, 1e-12));
        assert(abs(tanFallback(PI / 2)) > 1e15); // huge, but finite

        assert(isNaN(tanFallback(double.infinity)));
        assert(isNaN(tanFallback(double.nan)));

        assert(approx(tanFallback(1.0f), 1.5574077f, 1e-6));
    }
    
    // sin / cos / tan: identities over a sweep
    {
        foreach (i; -200..201)
        {
            double x = i * 0.05;
            double s = sinFallback(x);
            double c = cosFallback(x);

            assert(approx(s * s + c * c, 1.0, 1e-12));                       // Pythagoras
            assert(approx(sinFallback(-x), -s, 1e-12, 1e-15));               // odd
            assert(approx(cosFallback(-x),  c, 1e-12));                      // even
            assert(approx(sinFallback(2 * x), 2 * s * c,     1e-9, 1e-12));  // double angle
            assert(approx(cosFallback(2 * x), c * c - s * s, 1e-9, 1e-12));
            if (abs(c) > 0.05)
                assert(approx(tanFallback(x), s / c, 1e-9, 1e-12));          // tan = sin/cos
        }
    }
    
    // ceil / floor / round / trunc / rint / nearbyint
    {
        static foreach (fn; TSeq!(ceilFallback, floorFallback, roundFallback,
                                  truncFallback, rintFallback, nearbyintFallback))
        static foreach (T; TFloatTypes)
        {{
            foreach (i; -100..101)                         // integers are fixed points
                assert(fn(cast(T) i) == cast(T) i);

            assert(!signbitFallback(fn(cast(T) 0)));       // +0 stays +0
            assert( signbitFallback(fn(negZero!T)));       // -0 stays -0

            assert(fn(T.infinity)  ==  T.infinity);
            assert(fn(-T.infinity) == -T.infinity);
            assert(isNaN(fn(T.nan)));

            T big = pow2!T(T.mant_dig - 1) + 1;  // already integral, must not change
            assert(fn(big)  == big);
            assert(fn(-big) == -big);
            assert(fn(T.max)  == T.max);
            assert(fn(-T.max) == -T.max);

            for (T x = -10; x <= 10; x += cast(T) 0.125)    // idempotent, within 1 of input
            {
                T r = fn(x);
                assert(fn(r) == r);
                assert(abs(r - x) <= 1);
            }
        }}
    }
    
    // pow
    {
        assert(approx(powFallback(2.0, 10.0), 1024.0, 1e-12));
        assert(approx(powFallback(2.0, -1.0), 0.5, 1e-12));
        assert(approx(powFallback(2.0, 0.5), 1.41421356237309504880, 1e-12));
        assert(approx(powFallback(9.0, 0.5), 3.0, 1e-12));
        assert(approx(powFallback(10.0, 2.0), 100.0, 1e-12));
        assert(approx(powFallback(10.0, -3.0), 1e-3, 1e-12));
        assert(approx(powFallback(E, 2.0), 7.38905609893065, 1e-12));
        assert(approx(powFallback(2.0, 1023.0), pow2!double(1023), 1e-12));

        // negative base, integral exponent
        assert(approx(powFallback(-2.0,  3.0), -8.0,   1e-12));
        assert(approx(powFallback(-2.0,  2.0),  4.0,   1e-12));
        assert(approx(powFallback(-2.0, -3.0), -0.125, 1e-12));

        // overflow / underflow
        assert(powFallback(10.0,  400.0) == double.infinity);
        assert(powFallback(10.0, -400.0) == 0);

        // negative base, non-integral exponent
        assert(isNaN(powFallback(-2.0, 0.5)));
        assert(isNaN(powFallback(-8.0, 1.0 / 3.0)));
    }
    
    // pow: IEEE 754 / C99 special cases
    {
        enum double inf = double.infinity;
        enum double nan = double.nan;

        // pow(x, +-0) == 1 for every x, even NaN
        static foreach (x; TSeq!(0.0, 2.0, -2.0, inf, -inf, nan))
        {
            assert(powFallback(x,  0.0) == 1.0);
            assert(powFallback(x, -0.0) == 1.0);
        }
        // pow(1, y) == 1 for every y, even NaN
        static foreach (y; TSeq!(0.0, 5.0, -5.0, inf, -inf, nan))
            assert(powFallback(1.0, y) == 1.0);
        assert(powFallback(-1.0,  inf) == 1.0);
        assert(powFallback(-1.0, -inf) == 1.0);

        // zero base
        assert(powFallback(0.0, 1.0) == 0 && !signbitFallback(powFallback(0.0, 1.0)));
        assert(powFallback(0.0, 2.0) == 0);
        assert(powFallback(0.0, 0.5) == 0);
        assert(powFallback(0.0, -1.0) ==  inf);
        assert(powFallback(0.0, -2.0) ==  inf);
        assert(powFallback(-0.0, -1.0) == -inf);
        assert(powFallback(-0.0, -2.0) ==  inf);
        assert(signbitFallback(powFallback(-0.0, 3.0)));         // -0.0
        assert(!signbitFallback(powFallback(-0.0, 2.0)));        // +0.0

        // infinite exponent
        assert(powFallback(2.0,  inf) == inf);
        assert(powFallback(0.5,  inf) == 0);
        assert(powFallback(2.0, -inf) == 0);
        assert(powFallback(0.5, -inf) == inf);

        // infinite base
        assert(powFallback( inf,  2.0) ==  inf);
        assert(powFallback( inf, -2.0) ==  0);
        assert(powFallback(-inf,  3.0) == -inf);
        assert(powFallback(-inf,  2.0) ==  inf);
        assert(powFallback(-inf, -3.0) == 0 && signbitFallback(powFallback(-inf, -3.0)));

        // NaN propagation
        assert(isNaN(powFallback(nan, 2.0)));
        assert(isNaN(powFallback(2.0, nan)));
    }
    
    // exp
    {
        assert(approx(expFallback(0.0), 1.0, 1e-15));
        assert(approx(expFallback(1.0), E, 1e-12));
        assert(approx(expFallback(-1.0), 0.36787944117144233, 1e-12));
        assert(approx(expFallback(0.5), 1.6487212707001282, 1e-12));
        assert(approx(expFallback(2.0), 7.38905609893065, 1e-12));
        assert(approx(expFallback(10.0), 22026.465794806718, 1e-11));
        assert(approx(expFallback(-10.0), 4.5399929762484854e-5, 1e-11));
        assert(approx(expFallback(1e-10), 1.0000000001, 1e-14)); // near zero
        assert(approx(expFallback(700.0), 1.0142320547350045e304, 1e-9));
        assert(approx(expFallback(-700.0), 9.85967654375977e-305, 1e-9));
        assert(approx(expFallback(709.0), 8.218407461554972e307, 1e-9));

        // limits
        assert(expFallback(710.0) == double.infinity);
        assert(expFallback(-750.0) == 0);
        assert(expFallback(-720.0) > 0 && expFallback(-720.0) < double.min_normal); // gradual underflow

        // specials
        assert(expFallback(double.infinity) == double.infinity);
        assert(expFallback(-double.infinity) == 0);
        assert(isNaN(expFallback(double.nan)));

        assert(approx(expFallback(1.0f), 2.7182817f, 1e-6));

        // exp(x) * exp(-x) == 1 and exp(x + 1) == e * exp(x)
        foreach (i; -100 .. 101)
        {
            double x = i * 0.5;
            assert(approx(expFallback(x) * expFallback(-x), 1.0, 1e-12));
            assert(approx(expFallback(x + 1.0), expFallback(x) * E, 1e-12));
        }
    }
    
    // exp2
    {
        assert(approx(exp2Fallback(0.0), 1.0, 1e-15));
        assert(approx(exp2Fallback(1.0), 2.0, 1e-15));
        assert(approx(exp2Fallback(10.0), 1024.0, 1e-14));
        assert(approx(exp2Fallback(-1.0), 0.5, 1e-15));
        assert(approx(exp2Fallback(-10.0), 1.0 / 1024.0, 1e-14));
        assert(approx(exp2Fallback(0.5), 1.41421356237309504880, 1e-12));
        assert(approx(exp2Fallback(3.5), 11.313708498984761, 1e-12));

        for (int i = -1000; i <= 1000; i += 7) // integer arguments
            assert(approx(exp2Fallback(cast(double) i), pow2!double(i), 1e-12));

        assert(approx(exp2Fallback(1023.0), pow2!double(1023), 1e-12));
        assert(approx(exp2Fallback(-1022.0), double.min_normal, 1e-12));
        assert(exp2Fallback(1024.0) == double.infinity);
        assert(exp2Fallback(-1030.0) > 0 && exp2Fallback(-1030.0) < double.min_normal);  // subnormal
        assert(exp2Fallback(-1080.0) == 0);

        assert(exp2Fallback(double.infinity) == double.infinity);
        assert(exp2Fallback(-double.infinity) == 0);
        assert(isNaN(exp2Fallback(double.nan)));

        assert(approx(exp2Fallback(0.5f), 1.4142135f, 1e-6));
    }
    
    // log
    {
        assert(logFallback(1.0) == 0);
        assert(approx(logFallback(E), 1.0, 1e-12));
        assert(approx(logFallback(2.0), 0.6931471805599453, 1e-12));
        assert(approx(logFallback(0.5), -0.6931471805599453, 1e-12));
        assert(approx(logFallback(10.0), 2.302585092994046, 1e-12));
        assert(approx(logFallback(100.0), 4.605170185988092, 1e-12));
        assert(approx(logFallback(1e300), 690.7755278982137, 1e-12));
        assert(approx(logFallback(1e-300), -690.7755278982137, 1e-12));

        // subnormal input: log(2^-1023) = -1023 * ln 2
        assert(approx(logFallback(double.min_normal / 2), -709.0895657128241, 1e-11));

        // just above 1: log(1 + eps) ~= eps (catastrophic cancellation if done naively)
        assert(approx(logFallback(1.0 + double.epsilon), double.epsilon, 1e-6));

        assert(logFallback(0.0)  == -double.infinity);
        assert(logFallback(-0.0) == -double.infinity);
        assert(logFallback(double.infinity) == double.infinity);
        assert(isNaN(logFallback(-1.0)));
        assert(isNaN(logFallback(-double.infinity)));
        assert(isNaN(logFallback(double.nan)));

        assert(approx(logFallback(2.0f), 0.6931472f, 1e-6));
    }
    
    // log2
    {
        assert(log2Fallback(1.0) == 0);
        assert(approx(log2Fallback(10.0), 3.321928094887362, 1e-12));
        assert(approx(log2Fallback(3.0),  1.584962500721156, 1e-12));
        assert(approx(log2Fallback(1.5),  0.5849625007211562, 1e-12));
        assert(approx(log2Fallback(0.1), -3.321928094887362, 1e-12));

        // every power of two, subnormals included, must come out as the exact integer
        {
            double p = double.min_normal;
            for (int i = -1022; i <= 1023; ++i, p *= 2)
                assert(approx(log2Fallback(p), cast(double) i, 1e-12, 1e-12));
        }
        assert(approx(log2Fallback(double.min_normal * double.epsilon), -1074.0, 1e-12));

        assert(log2Fallback(0.0)  == -double.infinity);
        assert(log2Fallback(-0.0) == -double.infinity);
        assert(log2Fallback(double.infinity) == double.infinity);
        assert(isNaN(log2Fallback(-1.0)));
        assert(isNaN(log2Fallback(double.nan)));

        assert(approx(log2Fallback(8.0f), 3.0f, 1e-6));
    }
    
    // log10
    {
        assert(log10Fallback(1.0) == 0);
        assert(approx(log10Fallback(2.0),  0.3010299956639812, 1e-12));
        assert(approx(log10Fallback(5.0),  0.6989700043360189, 1e-12));
        assert(approx(log10Fallback(0.5), -0.3010299956639812, 1e-12));
        assert(approx(log10Fallback(E),    0.4342944819032518, 1e-12));
        assert(approx(log10Fallback(1e300),  300.0, 1e-12));
        assert(approx(log10Fallback(1e-300), -300.0, 1e-12));

        double p = 1; // 10^0 .. 10^22 are exact in double
        for (int i = 0; i <= 22; ++i, p *= 10)
            assert(approx(log10Fallback(p), cast(double) i, 1e-12, 1e-12));
        assert(approx(log10Fallback(0.01), -2.0, 1e-12));
        assert(approx(log10Fallback(0.001), -3.0, 1e-12));

        assert(log10Fallback(0.0)  == -double.infinity);
        assert(log10Fallback(-0.0) == -double.infinity);
        assert(log10Fallback(double.infinity) == double.infinity);
        assert(isNaN(log10Fallback(-1.0)));
        assert(isNaN(log10Fallback(double.nan)));

        assert(approx(log10Fallback(1000.0f), 3.0f, 1e-6));
    }
    
    // fmax
    {
        static foreach(T; TFloatTypes)
        {{
            enum T inf = T.infinity;
            assert(fmaxFallback(cast(T) 1,  cast(T) 2)  == 2);
            assert(fmaxFallback(cast(T) 2,  cast(T) 1)  == 2);
            assert(fmaxFallback(cast(T) -1, cast(T) -2) == -1);
            assert(fmaxFallback(cast(T) 5,  cast(T) 5)  == 5);
            assert(fmaxFallback(cast(T) -1, cast(T) 1)  == 1);
            assert(fmaxFallback(T.max, -T.max) == T.max);

            assert(fmaxFallback(inf, cast(T) 1) == inf);
            assert(fmaxFallback(cast(T) 1, inf) == inf);
            assert(fmaxFallback(-inf, cast(T) 1) == 1);
            assert(fmaxFallback(-inf, -inf) == -inf);

            // a single NaN is ignored; only NaN vs NaN yields NaN
            assert(fmaxFallback(T.nan, cast(T) 1) == 1);
            assert(fmaxFallback(cast(T) 1, T.nan) == 1);
            assert(fmaxFallback(-inf, T.nan) == -inf);
            assert(isNaN(fmaxFallback(T.nan, T.nan)));

            assert(fmaxFallback(cast(T) 0, negZero!T) == 0);        // either zero sign is acceptable
        }}
    }
    
    // fmin
    {
        static foreach(T; TFloatTypes)
        {{
            enum T inf = T.infinity;
            assert(fminFallback(cast(T) 1,  cast(T) 2)  == 1);
            assert(fminFallback(cast(T) 2,  cast(T) 1)  == 1);
            assert(fminFallback(cast(T) -1, cast(T) -2) == -2);
            assert(fminFallback(cast(T) 5,  cast(T) 5)  == 5);
            assert(fminFallback(cast(T) -1, cast(T) 1)  == -1);
            assert(fminFallback(T.max, -T.max) == -T.max);

            assert(fminFallback(-inf, cast(T) 1) == -inf);
            assert(fminFallback(cast(T) 1, -inf) == -inf);
            assert(fminFallback(inf, cast(T) 1) == 1);
            assert(fminFallback(inf, inf) == inf);

            assert(fminFallback(T.nan, cast(T) 1) == 1);
            assert(fminFallback(cast(T) 1, T.nan) == 1);
            assert(fminFallback(inf, T.nan) == inf);
            assert(isNaN(fminFallback(T.nan, T.nan)));

            assert(fminFallback(cast(T) 0, negZero!T) == 0);
        }}
    }
    
    // fma
    {
        static foreach(T; TFloatTypes)
        {{
            assert(fmaFallback(cast(T)  2, cast(T) 3, cast(T)  4) == 10);
            assert(fmaFallback(cast(T) -2, cast(T) 3, cast(T)  4) == -2);
            assert(fmaFallback(cast(T) 0.5, cast(T) 0.5, cast(T) 0.25) == 0.5);
            assert(fmaFallback(cast(T) 0, cast(T) 5, cast(T) 7) == 7);

            // non-finite inputs
            assert(fmaFallback(cast(T) 2, cast(T) 3, T.infinity) == T.infinity);
            assert(fmaFallback(T.infinity, cast(T) 2, cast(T) 1) == T.infinity);
            assert(isNaN(fmaFallback(T.infinity, cast(T) 0, cast(T) 1)));       // inf * 0
            assert(isNaN(fmaFallback(T.infinity, cast(T) 1, -T.infinity)));     // inf - inf
            assert(isNaN(fmaFallback(T.nan, cast(T) 1, cast(T) 1)));
            assert(isNaN(fmaFallback(cast(T) 1, cast(T) 1, T.nan)));
        }}
    }
    
    // hypot: values and symmetry
    {
        static foreach (T; TFloatTypes)
        {{
            enum real tol = loose!T;
            static immutable double[3][] triples = [
                [3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29], [9, 40, 41]];
            static immutable double[2] signs = [1.0, -1.0];
 
            foreach (t; triples)
                foreach (sx; signs)
                    foreach (sy; signs)
                    {
                        assert(approx(hypotFallback(cast(T)(sx * t[0]), cast(T)(sy * t[1])), t[2], tol));
                        assert(approx(hypotFallback(cast(T)(sy * t[1]), cast(T)(sx * t[0])), t[2], tol));
                    }
 
            assert(hypotFallback(cast(T) 0, cast(T)  5) == 5);
            assert(hypotFallback(cast(T) 5, cast(T)  0) == 5);
            assert(hypotFallback(cast(T) 0, cast(T) -5) == 5);
            assert(hypotFallback(cast(T) 0, cast(T)  0) == 0);
            assert(!signbitFallback(hypotFallback(cast(T) 0, cast(T) 0)));
            assert(!signbitFallback(hypotFallback(negZero!T, negZero!T))); // always +0
 
            assert(approx(hypotFallback(cast(T) 1, T.epsilon / 4), cast(T) 1, tol)); // tiny second operand
            assert(approx(hypotFallback(cast(T) 1, cast(T) 1), 1.41421356237309504880L, tol));
        }}
    }
    
    // hypot: sweep against sqrt(x*x + y*y), plus symmetry and scaling
    {
        // hypot(kx, ky) == k * hypot(x, y) for a power of two k
        pragma(inline, true)
        bool approxScaled(double x, double y, double h, double k)
        {
            return approx(hypotFallback(x * k, y * k), h * k, 1e-14);
        }
        
        foreach (i; -10 .. 11)
            foreach (j; -10 .. 11)
            {
                double x = i * 0.7, y = j * 1.3;
                double h = hypotFallback(x, y);
 
                assert(approx(h, sqrtFallback(x * x + y * y), 1e-14));
                assert(approx(hypotFallback(y, x),   h, 1e-15));
                assert(approx(hypotFallback(-x, y),  h, 1e-15));
                assert(approxScaled(x, y, h, 0x1p+100));
                assert(approxScaled(x, y, h, 0x1p-100));
            }
    }
    
    // hypot: overflow, underflow, subnormals
    {
        // squaring the operands would overflow / underflow
        assert(approx(hypotFallback(1e200, 1e200),   1.4142135623730951e200, 1e-14));
        assert(approx(hypotFallback(1e-200, 1e-200), 1.4142135623730951e-200, 1e-14));
        assert(approx(hypotFallback(3e200, 4e200),   5e200, 1e-14));
        assert(approx(hypotFallback(3e-200, 4e-200), 5e-200, 1e-14));
 
        assert(approx(hypotFallback(double.max, 1.0), double.max, 1e-15));
        assert(approx(hypotFallback(double.max / 2, 1.0), double.max / 2, 1e-15));
        assert(hypotFallback(double.max, double.max) == double.infinity);     // result really overflows
 
        // subnormal operands: (3, 4, 5) * 2^-1024
        immutable double u = pow2!double(-1024);
        assert(approx(hypotFallback(3 * u, 4 * u), 5 * u, 1e-14));
        assert(approx(hypotFallback(double.min_normal * double.epsilon, 0.0),
                       double.min_normal * double.epsilon, 1e-15));           // smallest subnormal
 
        assert(approx(hypotFallback(3e30f, 4e30f), 5e30f, 1e-6));            // float: x*x overflows
    }
    
    // hypot: special values (IEEE 754 / C99)
    {
        static foreach(T; TFloatTypes)
        {{
            enum T inf = T.infinity;
            assert(hypotFallback( inf, cast(T) 1) == inf);
            assert(hypotFallback(cast(T) 1, -inf) == inf);
            assert(hypotFallback(-inf, -inf) == inf);
            assert(hypotFallback( inf, T.nan) == inf); // infinity wins over NaN
            assert(hypotFallback(T.nan, -inf) == inf);
            assert(isNaN(hypotFallback(T.nan, cast(T) 1)));
            assert(isNaN(hypotFallback(cast(T) 1, T.nan)));
            assert(isNaN(hypotFallback(T.nan, T.nan)));
        }}
    }
    
    // modf: values and signs
    {
        static foreach(T; TFloatTypes)
        {{
            T ip, fp;
 
            fp = modfFallback(cast(T)  3.5, ip);  assert(ip ==  3 && fp ==  0.5);
            fp = modfFallback(cast(T) -3.5, ip);  assert(ip == -3 && fp == -0.5);
            fp = modfFallback(cast(T)  1.25, ip); assert(ip ==  1 && fp ==  0.25);
 
            // |x| < 1: integer part is a zero carrying x's sign
            fp = modfFallback(cast(T) 0.25, ip);
            assert(ip == 0 && !signbitFallback(ip) && fp == 0.25);
            fp = modfFallback(cast(T) -0.25, ip);
            assert(ip == 0 &&  signbitFallback(ip) && fp == -0.25);
 
            // integers: fractional part is a zero carrying x's sign
            fp = modfFallback(cast(T) 3, ip);
            assert(ip == 3 && fp == 0 && !signbitFallback(fp));
            fp = modfFallback(cast(T) -3, ip);
            assert(ip == -3 && fp == 0 && signbitFallback(fp));
 
            // zeros
            fp = modfFallback(cast(T) 0, ip);
            assert(ip == 0 && !signbitFallback(ip) && fp == 0 && !signbitFallback(fp));
            fp = modfFallback(negZero!T, ip);
            assert(ip == 0 &&  signbitFallback(ip) && fp == 0 &&  signbitFallback(fp));
 
            // infinities: integer part is +-inf, fractional part is a signed zero (not NaN)
            fp = modfFallback(T.infinity, ip);
            assert(ip == T.infinity && fp == 0 && !signbitFallback(fp));
            fp = modfFallback(-T.infinity, ip);
            assert(ip == -T.infinity && fp == 0 && signbitFallback(fp));
 
            // NaN
            fp = modfFallback(T.nan, ip);
            assert(isNaN(fp) && isNaN(ip));
 
            // large values have no fractional part
            immutable T big = pow2!T(T.mant_dig - 1) + 1;
            fp = modfFallback(big, ip);   assert(ip == big && fp == 0);
            fp = modfFallback(-big, ip);  assert(ip == -big && fp == 0);
            fp = modfFallback(T.max, ip); assert(ip == T.max && fp == 0);
 
            // tiny values are entirely fractional
            fp = modfFallback(T.min_normal, ip);
            assert(ip == 0 && fp == T.min_normal);
            fp = modfFallback(T.min_normal * T.epsilon, ip);    // subnormal
            assert(ip == 0 && fp == T.min_normal * T.epsilon);
 
            // largest value below 1
            immutable T belowOne = 1 - T.epsilon / 2;
            fp = modfFallback(belowOne, ip);
            assert(ip == 0 && fp == belowOne);
        }}
    }
    
    // modf: sweep invariants
    {
        static foreach(T; TFloatTypes)
        {{
            foreach(i; -200..201)
            {
                T x = cast(T) i * cast(T) 0.37;
                T ip;
                T fp = modfFallback(x, ip);
 
                assert(ip + fp == x); // exact decomposition
                assert(ip == floorFallback(ip)); // integral
                assert(abs(fp) < 1);
                assert(abs(ip) <= abs(x)); // truncation, not floor
                if (fp != 0) assert(signbitFallback(fp) == signbitFallback(x));
                if (ip != 0) assert(signbitFallback(ip) == signbitFallback(x));
                assert(ip == truncFallback(x));
            }
        }}
    }
    
    // sinh
    {
        assert(approx(sinhFallback(1.0),  1.1752011936438014, 1e-14));
        assert(approx(sinhFallback(0.5),  0.5210953054937474, 1e-14));
        assert(approx(sinhFallback(2.0),  3.626860407847019,  1e-14));
        assert(approx(sinhFallback(10.0), 11013.232874703393, 1e-13));
        assert(approx(sinhFallback(-1.0), -1.1752011936438014, 1e-14));
 
        // small arguments: (exp(x) - exp(-x)) / 2 would lose most digits here
        assert(approx(sinhFallback(1e-5),  1.0000000000166667e-5, 1e-13));
        assert(approx(sinhFallback(-1e-5), -1.0000000000166667e-5, 1e-13));
        assert(approx(sinhFallback(1e-10), 1e-10, 1e-14));
 
        // near the overflow threshold (~710.4758): exp(x) overflows, sinh(x) doesn't
        assert(approx(sinhFallback(709.0),  4.109203730777486e307, 1e-9));
        assert(approx(sinhFallback(710.0),  1.1169973830808557e308, 1e-6));
        assert(approx(sinhFallback(-710.0), -1.1169973830808557e308, 1e-6));
        assert(sinhFallback(711.0)  ==  double.infinity);
        assert(sinhFallback(-711.0) == -double.infinity);
        assert(sinhFallback(100.0f) ==  float.infinity);       // float overflow (~89)
 
        assert(approx(sinhFallback(1.0f), 1.1752012f, 1e-6));
 
        // agrees with the definition away from zero
        for (int i = 1; i <= 80; ++i)
        {
            double x = i * 0.25;
            assert(approx(sinhFallback(x), 0.5 * (expFallback(x) - expFallback(-x)), 1e-12));
        }
    }
    
    // cosh
    {
        assert(coshFallback(0.0) == 1.0);
        assert(coshFallback(negZero!double) == 1.0);
        assert(approx(coshFallback(1.0),  1.5430806348152437, 1e-14));
        assert(approx(coshFallback(0.5),  1.1276259652063807, 1e-14));
        assert(approx(coshFallback(2.0),  3.7621956910836314, 1e-14));
        assert(approx(coshFallback(10.0), 11013.232920103324, 1e-13));
        assert(approx(coshFallback(-2.0), 3.7621956910836314, 1e-14));
 
        assert(coshFallback(1e-10) == 1.0);                     // 1 + 5e-21 rounds to 1
 
        assert(approx(coshFallback(709.0),  4.109203730777486e307, 1e-9));
        assert(approx(coshFallback(710.0),  1.1169973830808557e308, 1e-6));
        assert(approx(coshFallback(-710.0), 1.1169973830808557e308, 1e-6));
        assert(coshFallback(711.0)  == double.infinity);
        assert(coshFallback(-711.0) == double.infinity);
        assert(coshFallback(100.0f) == float.infinity);
 
        assert(approx(coshFallback(1.0f), 1.5430806f, 1e-6));
 
        for (int i = -80; i <= 80; ++i)
        {
            double x = i * 0.25;
            assert(approx(coshFallback(x), 0.5 * (expFallback(x) + expFallback(-x)), 1e-12));
            assert(approx(coshFallback(-x), coshFallback(x), 1e-15));           // even
        }
    }
    
    // tanh
    {
        assert(approx(tanhFallback(1.0),  0.7615941559557649,  1e-14));
        assert(approx(tanhFallback(0.5),  0.46211715726000974, 1e-14));
        assert(approx(tanhFallback(0.1),  0.09966799462495582, 1e-14));
        assert(approx(tanhFallback(2.0),  0.9640275800758169,  1e-14));
        assert(approx(tanhFallback(5.0),  0.9999092042625951,  1e-14));
        assert(approx(tanhFallback(-1.0), -0.7615941559557649, 1e-14));
 
        assert(approx(tanhFallback(1e-5),  9.999999999666667e-6, 1e-13)); // small-argument accuracy
        assert(approx(tanhFallback(1e-10), 1e-10, 1e-14));
 
        // saturation
        assert(tanhFallback(30.0)  ==  1.0);
        assert(tanhFallback(-30.0) == -1.0);
        assert(tanhFallback(1e10)  ==  1.0);
        assert(tanhFallback(double.max)  ==  1.0);
        assert(tanhFallback(-double.max) == -1.0);
        assert(tanhFallback(double.infinity)  ==  1.0);
        assert(tanhFallback(-double.infinity) == -1.0);
 
        assert(approx(tanhFallback(1.0f), 0.7615942f, 1e-6));
 
        // |tanh| <= 1, non-decreasing, and equal to sinh / cosh
        for (int i = -300; i < 300; ++i)
        {
            double x = i * 0.01;
            double t = tanhFallback(x);
            assert(abs(t) <= 1.0);
            assert(t <= tanhFallback(x + 0.01));
        }
        for (int i = 1; i <= 40; ++i)
        {
            double x = i * 0.25;
            assert(approx(tanhFallback(x), sinhFallback(x) / coshFallback(x), 1e-12));
            assert(approx(tanhFallback(-x), -tanhFallback(x), 1e-14));
        }
    }
    
    // sinh / cosh: cosh^2 - sinh^2 == 1
    {
        for (int i = -20; i <= 20; ++i)
        {
            double x = i * 0.25;
            double s = sinhFallback(x), c = coshFallback(x);
            assert(approx(c * c - s * s, 1.0, 1e-9));
        }
    }
    
    // asinh
    {
        assert(approx(asinhFallback(1.0),  0.881373587019543,   1e-14));
        assert(approx(asinhFallback(0.5),  0.48121182505960347, 1e-14));
        assert(approx(asinhFallback(2.0),  1.4436354751788103,  1e-14));
        assert(approx(asinhFallback(10.0), 2.99822295029797,    1e-14));
        assert(approx(asinhFallback(-1.0), -0.881373587019543,  1e-14));
 
        // small arguments: log(x + sqrt(x*x + 1)) collapses here
        assert(approx(asinhFallback(1e-5),  9.999999999833333e-6, 1e-13));
        assert(approx(asinhFallback(-1e-5), -9.999999999833333e-6, 1e-13));
        assert(approx(asinhFallback(1e-10), 1e-10, 1e-14));
 
        // large arguments: x*x must not overflow
        assert(approx(asinhFallback(1e300),  691.4686750787736, 1e-12));
        assert(approx(asinhFallback(-1e300), -691.4686750787736, 1e-12));
        assert(approx(asinhFallback(double.max), 710.4758600739439, 1e-12));
 
        assert(approx(asinhFallback(1.0f), 0.8813736f, 1e-6));
 
        // round trips and the log formula
        for (int i = -200; i <= 200; ++i)
        {
            double x = i * 0.5;
            assert(approx(sinhFallback(asinhFallback(x)), x, 1e-12, 1e-14));
        }
        for (int i = -20; i <= 20; ++i)
        {
            double x = i * 0.25;
            assert(approx(asinhFallback(sinhFallback(x)), x, 1e-12, 1e-14));
        }
        for (int i = 1; i <= 100; ++i)
        {
            double x = i * 0.5;
            assert(approx(asinhFallback(x), logFallback(x + sqrtFallback(x * x + 1.0)), 1e-12));
        }
    }
    
    // acosh
    {
        assert(acoshFallback(1.0) == 0 && !signbitFallback(acoshFallback(1.0)));
        assert(approx(acoshFallback(1.5),  0.9624236501192069, 1e-14));
        assert(approx(acoshFallback(2.0),  1.3169578969248166, 1e-14));
        assert(approx(acoshFallback(10.0), 2.993222846126381,  1e-14));
 
        // just above 1: acosh(1 + e) ~= sqrt(2e) * (1 - e/12); (x - 1) is exact here
        {
            enum double e = 0x1p-40;
            assert(approx(acoshFallback(1.0 + e), sqrtFallback(2 * e) * (1 - e / 12), 1e-12));
        }
 
        assert(approx(acoshFallback(1e300), 691.4686750787736, 1e-12));
        assert(approx(acoshFallback(double.max), 710.4758600739439, 1e-12));
        assert(acoshFallback(double.infinity) == double.infinity);
 
        // outside the domain (x < 1)
        assert(isNaN(acoshFallback(0.999999)));
        assert(isNaN(acoshFallback(0.0)));
        assert(isNaN(acoshFallback(-1.0)));
        assert(isNaN(acoshFallback(-double.infinity)));
        assert(isNaN(acoshFallback(double.nan)));
 
        assert(approx(acoshFallback(2.0f), 1.3169579f, 1e-6));
 
        for (int i = 0; i <= 200; ++i)
        {
            double x = 1.0 + i * 0.5;
            assert(approx(coshFallback(acoshFallback(x)), x, 1e-12));
        }
        for (int i = 1; i <= 80; ++i)
        {
            double x = i * 0.25;
            assert(approx(acoshFallback(coshFallback(x)), x, 1e-11));
        }
        for (int i = 3; i <= 100; ++i)
        {
            double x = i * 0.5;
            assert(approx(acoshFallback(x), logFallback(x + sqrtFallback(x * x - 1.0)), 1e-12));
        }
    }
    
    // atanh
    {
        assert(approx(atanhFallback(0.5),  0.5493061443340548, 1e-14));
        assert(approx(atanhFallback(-0.5), -0.5493061443340548, 1e-14));
        assert(approx(atanhFallback(0.9),  1.4722194895832204, 1e-14));
        assert(approx(atanhFallback(0.99), 2.646652412362246,  1e-13));
 
        // small arguments
        assert(approx(atanhFallback(1e-5),  1.0000000000333333e-5, 1e-13));
        assert(approx(atanhFallback(-1e-5), -1.0000000000333333e-5, 1e-13));
        assert(approx(atanhFallback(1e-10), 1e-10, 1e-14));
 
        // close to 1: atanh(1 - 2^-20) = 0.5 * ln(2^21 - 1)
        assert(approx(atanhFallback(1.0 - 0x1p-20),  7.2780451574608, 1e-10));
        assert(approx(atanhFallback(-(1.0 - 0x1p-20)), -7.2780451574608, 1e-10));
 
        // endpoints and domain
        assert(atanhFallback(1.0)  ==  double.infinity);
        assert(atanhFallback(-1.0) == -double.infinity);
        assert(isNaN(atanhFallback(1.0000001)));
        assert(isNaN(atanhFallback(-1.0000001)));
        assert(isNaN(atanhFallback(2.0)));
        assert(isNaN(atanhFallback(double.infinity)));
        assert(isNaN(atanhFallback(-double.infinity)));
        assert(isNaN(atanhFallback(double.nan)));
 
        assert(approx(atanhFallback(0.5f), 0.54930615f, 1e-6));
 
        for (int i = -99; i <= 99; ++i) // round trips
        {
            double x = i * 0.01;
            assert(approx(tanhFallback(atanhFallback(x)), x, 1e-12, 1e-14));
        }
        for (int i = -12; i <= 12; ++i)
        {
            double x = i * 0.25;
            assert(approx(atanhFallback(tanhFallback(x)), x, 1e-11, 1e-14));
        }
        for (int i = 1; i <= 18; ++i) // log formula, away from 0
        {
            double x = i * 0.05;
            assert(approx(atanhFallback(x), 0.5 * logFallback((1.0 + x) / (1.0 - x)), 1e-12));
        }
    }
    
    // Shared properties of the odd functions sinh, tanh, asinh, atanh
    {
        static foreach(fn; TSeq!(sinhFallback, tanhFallback, asinhFallback, atanhFallback))
        static foreach(T; TFloatTypes)
        {{
            assert(fn(cast(T)0) == 0  && !signbitFallback(fn(cast(T) 0)));
            assert(fn(negZero!T) == 0 && signbitFallback(fn(negZero!T))); // f(-0) == -0
            assert(isNaN(fn(T.nan)));
 
            foreach(i; -15..16) // inside every function's domain
            {
                T x = cast(T)i * cast(T) 0.0625;
                assert(approx(fn(-x), -fn(x), loose!T));
            }
        }}
 
        static foreach(fn; TSeq!(sinhFallback, tanhFallback, asinhFallback, atanhFallback))
        {
            assert(approx(fn(1e-300), 1e-300, 1e-14)); // f(x) == x for tiny x
            assert(approx(fn(-1e-300), -1e-300, 1e-14));
            assert(approx(fn(double.min_normal * double.epsilon), double.min_normal * double.epsilon, 1e-14)); // smallest subnormal
        }
    }
    
    // infinities of the unbounded odd functions and cosh
    {
        static foreach(T; TFloatTypes)
        {{
            assert(sinhFallback( T.infinity) ==  T.infinity);
            assert(sinhFallback(-T.infinity) == -T.infinity);
            assert(coshFallback( T.infinity) ==  T.infinity);
            assert(coshFallback(-T.infinity) ==  T.infinity);
            assert(asinhFallback( T.infinity) ==  T.infinity);
            assert(asinhFallback(-T.infinity) == -T.infinity);
            assert(isNaN(coshFallback(T.nan)));
        }}
    }
    
    printLn("All tests passed!");
}
