module main;

import std.stdio;
import std.algorithm: max, map;
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

double ulp(double x)
{
    double ax = abs(x);
    return nextUp(ax) - ax;
}

auto linearRange(size_t steps, double mi, double ma)
{
    double divisor = (steps > 1) ? cast(double)(steps - 1) : 1.0;
    return iota(steps).map!(i => mi + (ma - mi) * (cast(double)i / divisor));
}

enum string COLOR_RESET = "\033[0m";
enum string COLOR_GREEN = "\033[32m";
enum string COLOR_RED   = "\033[31m";

enum ULP_TOLERANCE = 5;

// alias F1 - reference function
// alias F2 - tested function
void testUnary(alias F1, alias F2, R)(string funcName, R testPoints)
{
    enum double DOUBLE_DENORM_MIN = 0x0.0000000000001p-1022;
    
    double max_ulp = 0.0;
    int exact_matches = 0;
    size_t total_steps = 0;
    
    double worst_x = 0.0;
    double worst_r1 = 0.0;
    double worst_r2 = 0.0;

    foreach (a; testPoints)
    {
        total_steps++;
        double r1 = F1(a);
        double r2 = F2(a);
        
        if (r1 == r2)
        {
            exact_matches++;
        }
        else
        {
            double abs_err = abs(r1 - r2);
            
            double ulp_err = 0.0;
            if (abs(r1) > 1e-15) 
                ulp_err = abs_err / ulp(r1);
            else if (abs_err > 1e-16)
                ulp_err = abs_err / DOUBLE_DENORM_MIN;
            
            if (ulp_err > max_ulp)
            {
                max_ulp = ulp_err;
                worst_x = a;
                worst_r1 = r1;
                worst_r2 = r2;
            }
        }
    }

    enum string COLOR_RESET = "\033[0m";
    enum string COLOR_GREEN = "\033[32m";
    enum string COLOR_RED   = "\033[31m";

    writeln(funcName, ":");
    writefln("Points tested: %d", total_steps);
    if (total_steps > 0)
    {
        writefln("Exact matches: %d from %d (%.1f%%)", exact_matches, total_steps, (cast(double)exact_matches / total_steps) * 100.0);
    }
    writefln("Max error:     %.2f ULP", max_ulp);
    
    if (max_ulp > 1.0)
    {
        writefln("  Worst case at x = %.6f", worst_x);
        writefln("  stdmath:  %.16g", worst_r1);
        writefln("  rtldmath: %.16g", worst_r2);
    }
    
    if (max_ulp <= ULP_TOLERANCE)
        writefln("%sPass%s\n", COLOR_GREEN, COLOR_RESET);
    else
        writefln("%sFail%s\n", COLOR_RED, COLOR_RESET);
}

double sinh_ref(double x)
{
    import std.math: abs, expm1;
    double ax = abs(x);
    double t = expm1(ax);
    double res = 0.5 * (t + t / (t + 1.0));
    return (x < 0) ? -res : res;
}

void main()
{
    testUnary!(stdmath.sin, rtldmath.sinFallback)("sinFallback (0..2*PI)", linearRange(100, 0.0, 2.0 * PI));
    testUnary!(stdmath.cos, rtldmath.cosFallback)("cosFallback (0..2*PI)", linearRange(100, 0.0, 2.0 * PI));
    testUnary!(stdmath.tan, rtldmath.tanFallback)("tanFallback (-PI/2..+PI/2)", linearRange(100, -PI * 0.5, +PI * 0.5));
    testUnary!(stdmath.asin, rtldmath.asinFallback)("asinFallback (-1..1)", linearRange(100, -1.0, 1.0));
    testUnary!(stdmath.acos, rtldmath.acosFallback)("acosFallback (-1..1)", linearRange(100, -1.0, 1.0));
    testUnary!(stdmath.atan, rtldmath.atanFallback)("atanFallback (-10..10)", linearRange(100, -10.0, 10.0));

    testUnary!(sinh_ref, rtldmath.sinhFallback)("sinhFallback (-5..5)", linearRange(100, -5.0, 5.0));
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

    testUnary!(stdmath.exp, rtldmath.expFallback)("expFallback (-10..10)", linearRange(100, -10.0, 10.0));
    testUnary!(stdmath.exp2, rtldmath.exp2Fallback)("exp2Fallback (-10..10)", linearRange(100, -10.0, 10.0));

    testUnary!(stdmath.log, rtldmath.logFallback)("logFallback (0.01..100)", linearRange(100, 0.01, 100.0));
    testUnary!(stdmath.log2, rtldmath.log2Fallback)("log2Fallback (0.01..100)", linearRange(100, 0.01, 100.0));
    testUnary!(stdmath.log10, rtldmath.log10Fallback)("log10Fallback (0.01..100)", linearRange(100, 0.01, 100.0));
}