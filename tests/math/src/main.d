module main;

import std.stdio;
import std.algorithm: max, map, cartesianProduct;
import std.typecons: Tuple;
import std.range: iota, isInputRange;
import std.math: abs;
import std.math.operations: nextUp;

import rtld.math.constants;
import stdmath = std.math;
import rtldmath = rtld.math.fallback;

version(Windows)
{
    import core.sys.windows.windows;
    
    static this()
    {
        HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        if (hConsole != INVALID_HANDLE_VALUE)
        {
            DWORD mode = 0;
            if (GetConsoleMode(hConsole, &mode))
                SetConsoleMode(hConsole, mode | 0x0004);
        }
    }
}

pragma(inline, true)
auto linearRange(size_t steps, double mi, double ma)
{
    double divisor = (steps > 1) ? cast(double)(steps - 1) : 1.0;
    return iota(steps).map!(i => mi + (ma - mi) * (cast(double)i / divisor));
}

pragma(inline, true)
double ulp(double x) @nogc nothrow pure
{
    double ax = abs(x);
    return nextUp(ax) - ax;
}

enum double DOUBLE_DENORM_MIN = 0x0.0000000000001p-1022;

pragma(inline, true)
double ulpError(double r1, double r2, double absErr) @nogc nothrow pure
{
    double err = 0.0;
    if (abs(r1) > 1e-15) 
        err = absErr / ulp(r1);
    else if (absErr > 1e-16)
        err = absErr / DOUBLE_DENORM_MIN;
    return err;
}

pragma(inline, true)
bool approxEqual(
    double a,
    double b,
    double absTolerance,
    double relTolerance) @nogc nothrow pure
{
    double diff = stdmath.abs(a - b);
    if (diff == 0.0)
        return true;
    double scale = stdmath.fmax(stdmath.abs(a), stdmath.abs(b));
    if (diff <= absTolerance)
        return true;
    return diff / scale <= relTolerance;
}

enum double ULP_TOLERANCE = 5;

struct AccuracyResult
{
    size_t count;
    size_t exact;
    double maxULP;
    double maxRelativeError;
    double maxAbsoluteError;
    double worstX;
    double worstY;
    double reference;
    double tested;
}

enum ABS_TOLERANCE = 1e-15;
enum REL_TOLERANCE = 1e-14;

enum string COLOR_RESET = "\033[0m";
enum string COLOR_GREEN = "\033[32m";
enum string COLOR_RED   = "\033[31m";

// alias F1 - reference function
// alias F2 - tested function
void testUnary(alias F1, alias F2, R)(string funcName, R testPoints)
{
    AccuracyResult result = {
        count: 0,
        exact: 0,
        maxULP: 0.0,
        maxRelativeError: 0.0,
        maxAbsoluteError: 0.0,
        worstX: 0.0,
        reference: 0.0,
        tested: 0.0
    };

    foreach (x; testPoints)
    {
        result.count++;
        
        double r1 = F1(x);
        double r2 = F2(x);
        
        if (r1 == r2)
        {
            result.exact++;
        }
        else
        {
            double absErr = stdmath.abs(r1 - r2);
            
            if (absErr > result.maxAbsoluteError)
            {
                result.maxAbsoluteError = absErr;
                result.reference = r1;
                result.tested = r2;
                result.worstX = x;
            }
            
            if (r1 != 0.0)
            {
                double relErr = absErr / stdmath.abs(r1);

                if (relErr > result.maxRelativeError)
                    result.maxRelativeError = relErr;
            }
            
            double u = ulpError(r1, r2, absErr);
            if (u > result.maxULP)
                result.maxULP = u;
        }
    }

    enum string COLOR_RESET = "\033[0m";
    enum string COLOR_GREEN = "\033[32m";
    enum string COLOR_RED   = "\033[31m";

    writeln(funcName, ":");
    writefln("Points tested: %d", result.count);
    if (result.count > 0)
    {
        writefln("Exact matches: %d from %d (%.1f%%)",
            result.exact,
            result.count,
            (cast(double)result.exact / cast(double)result.count) * 100.0);
    }
    writefln("Max error:     %.2f ULP", result.maxULP);
    
    if (result.maxULP > 1.0)
    {
        writefln("  Worst case at x = %.6f", result.worstX);
        writefln("  stdmath:  %.16g", result.reference);
        writefln("  rtldmath: %.16g", result.tested);
    }
    
    bool pass = approxEqual(
        result.reference,
        result.tested,
        ABS_TOLERANCE,
        REL_TOLERANCE
    );
    
    if (pass)
        writefln("%sPass%s\n", COLOR_GREEN, COLOR_RESET);
    else
        writefln("%sFail%s\n", COLOR_RED, COLOR_RESET);
}

// alias F1 - reference function
// alias F2 - tested function
void testBinary(alias F1, alias F2, R1, R2)(string funcName, R1 rangeX, R2 rangeY)
{
    AccuracyResult result = {
        count: 0,
        exact: 0,
        maxULP: 0.0,
        maxRelativeError: 0.0,
        maxAbsoluteError: 0.0,
        worstX: 0.0,
        worstY: 0.0,
        reference: 0.0,
        tested: 0.0
    };

    foreach (pair; cartesianProduct(rangeX, rangeY))
    {
        double x = pair[0];
        double y = pair[1];

        result.count++;

        double r1 = F1(x, y);
        double r2 = F2(x, y);

        if (r1 == r2)
        {
            result.exact++;
        }
        else
        {
            double absErr = stdmath.abs(r1 - r2);

            if (absErr > result.maxAbsoluteError)
            {
                result.maxAbsoluteError = absErr;
                result.reference = r1;
                result.tested = r2;
                result.worstX = x;
                result.worstY = y;
            }

            if (r1 != 0.0)
            {
                double relErr = absErr / stdmath.abs(r1);

                if (relErr > result.maxRelativeError)
                    result.maxRelativeError = relErr;
            }

            double u = ulpError(r1, r2, absErr);

            if (u > result.maxULP)
                result.maxULP = u;
        }
    }

    enum string COLOR_RESET = "\033[0m";
    enum string COLOR_GREEN = "\033[32m";
    enum string COLOR_RED   = "\033[31m";

    writeln(funcName, ":");
    writefln("Pairs tested:  %d", result.count);

    if (result.count > 0)
    {
        writefln(
            "Exact matches: %d from %d (%.1f%%)",
            result.exact,
            result.count,
            (cast(double) result.exact / cast(double) result.count) * 100.0
        );
    }

    writefln("Max error:     %.2f ULP", result.maxULP);

    if (result.maxULP > 1.0)
    {
        writefln(
            "  Worst case at x = %.6f, y = %.6f",
            result.worstX,
            result.worstY
        );
        writefln("  stdmath:  %.16g", result.reference);
        writefln("  rtldmath: %.16g", result.tested);
    }

    bool pass = approxEqual(
        result.reference,
        result.tested,
        ABS_TOLERANCE,
        REL_TOLERANCE
    );

    if (pass)
        writefln("%sPass%s\n", COLOR_GREEN, COLOR_RESET);
    else
        writefln("%sFail%s\n", COLOR_RED, COLOR_RESET);
}

void main()
{
    testUnary!(stdmath.sin, rtldmath.sinFallback)("sinFallback (0..2*PI)", linearRange(100, 0.0, 2.0 * PI));
    testUnary!(stdmath.cos, rtldmath.cosFallback)("cosFallback (0..2*PI)", linearRange(100, 0.0, 2.0 * PI));
    testUnary!(stdmath.tan, rtldmath.tanFallback)("tanFallback (-PI/2..+PI/2)", linearRange(100, -PI * 0.5, +PI * 0.5));
    testUnary!(stdmath.asin, rtldmath.asinFallback)("asinFallback (-1..1)", linearRange(100, -1.0, 1.0));
    testUnary!(stdmath.acos, rtldmath.acosFallback)("acosFallback (-1..1)", linearRange(100, -1.0, 1.0));
    testUnary!(stdmath.atan, rtldmath.atanFallback)("atanFallback (-10..10)", linearRange(100, -10.0, 10.0));

    testUnary!(stdmath.sinh, rtldmath.sinhFallback)("sinhFallback (-5..5)", linearRange(100, -5.0, 5.0));
    testUnary!(stdmath.cosh, rtldmath.coshFallback)("coshFallback (-5..5)", linearRange(100, -5.0, 5.0));
    testUnary!(stdmath.tanh, rtldmath.tanhFallback)("tanhFallback (-5..5)", linearRange(100, -5.0, 5.0));
    testUnary!(stdmath.asinh, rtldmath.asinhFallback)("asinhFallback (-10..10)", linearRange(100, -10.0, 10.0));
    testUnary!(stdmath.acosh, rtldmath.acoshFallback)("acoshFallback (1..50)", linearRange(100, 1.0, 50.0));
    testUnary!(stdmath.atanh, rtldmath.atanhFallback)("atanhFallback (-0.99..0.99)", linearRange(100, -0.99, 0.99));

    testUnary!(stdmath.sqrt, rtldmath.sqrtFallback)("sqrtFallback (0..1000)", linearRange(100, 0.0, 1000.0));
    testUnary!(stdmath.cbrt, rtldmath.cbrtFallback)("cbrtFallback (-1000..1000)", linearRange(100, -1000.0, 1000.0));

    testUnary!(stdmath.ceil, rtldmath.ceilFallback)("ceilFallback (-50..50)", linearRange(100, -50.0, 50.0));
    testUnary!(stdmath.floor, rtldmath.floorFallback)("floorFallback (-50..50)", linearRange(100, -50.0, 50.0));
    testUnary!(stdmath.round, rtldmath.roundFallback)("roundFallback (-50..50)", linearRange(100, -50.0, 50.0));
    testUnary!(stdmath.trunc, rtldmath.truncFallback)("truncFallback (-50..50)", linearRange(100, -50.0, 50.0));
    testUnary!(stdmath.rint,  rtldmath.rintFallback)("rintFallback (-50..50)", linearRange(100, -50.0, 50.0));

    testUnary!(stdmath.exp, rtldmath.expFallback)("expFallback (-10..10)", linearRange(100, -10.0, 10.0));
    testUnary!(stdmath.exp2, rtldmath.exp2Fallback)("exp2Fallback (-10..10)", linearRange(100, -10.0, 10.0));

    testUnary!(stdmath.log, rtldmath.logFallback)("logFallback (0.01..100)", linearRange(100, 0.01, 100.0));
    testUnary!(stdmath.log2, rtldmath.log2Fallback)("log2Fallback (0.01..100)", linearRange(100, 0.01, 100.0));
    testUnary!(stdmath.log10, rtldmath.log10Fallback)("log10Fallback (0.01..100)", linearRange(100, 0.01, 100.0));
    
    testBinary!(stdmath.hypot, rtldmath.hypotFallback)(
        "hypotFallback (-100..100, -100..100)",
        linearRange(20, -100.0, 100.0), 
        linearRange(20, -100.0, 100.0));
    
    testBinary!(stdmath.atan2, rtldmath.atan2Fallback)(
        "atan2Fallback",
        linearRange(20, -50.0, 50.0), 
        linearRange(20, -50.0, 50.0)
    );
    
    testBinary!(stdmath.pow, rtldmath.powFallback)(
        "powFallback",
        linearRange(25, 0.01, 10.0),
        linearRange(20, -5.0, 5.0)
    );
    
    testBinary!(stdmath.copysign, rtldmath.copysignFallback)(
        "copysignFallback",
        linearRange(10, -10.0, 10.0), 
        linearRange(10, -10.0, 10.0)
    );
}