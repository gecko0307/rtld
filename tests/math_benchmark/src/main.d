module main;

import std.stdio;
import std.datetime.stopwatch;
import std.math;

import rtld.math.fallback;

private double sink;

enum size_t Iterations = 10_000_000;

// ------------------------------------------------------------
// Input generation
// ------------------------------------------------------------

double[] makeInput(double min, double max)
{
    auto result = new double[Iterations];

    ulong state = 0x123456789abcdef0UL;

    foreach (i; 0 .. Iterations)
    {
        state ^= state >> 12;
        state ^= state << 25;
        state ^= state >> 27;

        ulong r = state * 0x2545F4914F6CDD1DUL;

        double t =
            (r >> 11) *
            (1.0 / 9007199254740992.0);

        result[i] = min + (max - min) * t;
    }

    return result;
}

// ------------------------------------------------------------
// Benchmark helpers
// ------------------------------------------------------------

double benchmark(alias F)(double[] input)
{
    double result = 0.0;

    auto sw = StopWatch();
    sw.start();

    foreach (x; input)
        result += F(x);

    const long elapsed = sw.peek().total!"nsecs";

    sink = result;

    return cast(double)elapsed / input.length;
}


double benchmark2(alias F)(double[] a, double[] b)
{
    double result = 0.0;

    auto sw = StopWatch();
    sw.start();

    foreach (i; 0 .. a.length)
        result += F(a[i], b[i]);

    const long elapsed = sw.peek().total!"nsecs";

    sink = result;

    return cast(double)elapsed / a.length;
}


double benchmark3(alias F)(
    double[] a,
    double[] b,
    double[] c)
{
    double result = 0.0;

    auto sw = StopWatch();
    sw.start();

    foreach (i; 0 .. a.length)
        result += F(a[i], b[i], c[i]);

    const long elapsed = sw.peek().total!"nsecs";

    sink = result;

    return cast(double)elapsed / a.length;
}


void printResult(
    string name,
    double fallback,
    double system)
{
    writefln(
        "%-10s  fallback %9.3f ns   std.math %9.3f ns   ratio %6.2fx",
        name,
        fallback,
        system,
        fallback / system
    );
}


// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void main()
{
    writeln("RTLD fallback math benchmark");
    writeln("============================");
    writeln("Iterations: ", Iterations);
    writeln();

    /*
     * Keep different domains for different functions.
     */
    auto small    = makeInput(-10.0, 10.0);
    auto unit     = makeInput(-1.0, 1.0);
    auto positive = makeInput(0.001, 100.0);

    /*
     * Inputs for binary/ternary functions.
     */
    auto small2    = makeInput(-10.0, 10.0);
    auto positive2 = makeInput(0.001, 100.0);
    auto third     = makeInput(-10.0, 10.0);


    /*
     * Warm up code and CPU caches.
     */
    sink = rtld.math.fallback.sqrtFallback(3.141592653589793);
    sink = std.math.sqrt(3.141592653589793);


    // --------------------------------------------------------
    // Elementary
    // --------------------------------------------------------

    writeln("Elementary");
    writeln("----------");

    printResult(
        "abs",
        benchmark!(rtld.math.fallback.absFallback)(small),
        benchmark!(std.math.abs)(small)
    );

    printResult(
        "fabs",
        benchmark!(rtld.math.fallback.fabsFallback)(small),
        benchmark!(std.math.fabs)(small)
    );

    printResult(
        "sqrt",
        benchmark!(rtld.math.fallback.sqrtFallback)(positive),
        benchmark!(std.math.sqrt)(positive)
    );

    printResult(
        "cbrt",
        benchmark!(rtld.math.fallback.cbrtFallback)(positive),
        benchmark!(std.math.cbrt)(positive)
    );


    // --------------------------------------------------------
    // Rounding
    // --------------------------------------------------------

    writeln();
    writeln("Rounding");
    writeln("--------");

    printResult(
        "trunc",
        benchmark!(rtld.math.fallback.truncFallback)(small),
        benchmark!(std.math.trunc)(small)
    );

    printResult(
        "floor",
        benchmark!(rtld.math.fallback.floorFallback)(small),
        benchmark!(std.math.floor)(small)
    );

    printResult(
        "ceil",
        benchmark!(rtld.math.fallback.ceilFallback)(small),
        benchmark!(std.math.ceil)(small)
    );

    printResult(
        "round",
        benchmark!(rtld.math.fallback.roundFallback)(small),
        benchmark!(std.math.round)(small)
    );

    printResult(
        "rint",
        benchmark!(rtld.math.fallback.rintFallback)(small),
        benchmark!(std.math.rint)(small)
    );

    printResult(
        "nearbyint",
        benchmark!(rtld.math.fallback.nearbyintFallback)(small),
        benchmark!(std.math.nearbyint)(small)
    );


    // --------------------------------------------------------
    // Trigonometric
    // --------------------------------------------------------

    writeln();
    writeln("Trigonometric");
    writeln("-------------");

    printResult(
        "sin",
        benchmark!(rtld.math.fallback.sinFallback)(small),
        benchmark!(std.math.sin)(small)
    );

    printResult(
        "cos",
        benchmark!(rtld.math.fallback.cosFallback)(small),
        benchmark!(std.math.cos)(small)
    );

    printResult(
        "tan",
        benchmark!(rtld.math.fallback.tanFallback)(small),
        benchmark!(std.math.tan)(small)
    );

    printResult(
        "asin",
        benchmark!(rtld.math.fallback.asinFallback)(unit),
        benchmark!(std.math.asin)(unit)
    );

    printResult(
        "acos",
        benchmark!(rtld.math.fallback.acosFallback)(unit),
        benchmark!(std.math.acos)(unit)
    );

    printResult(
        "atan",
        benchmark!(rtld.math.fallback.atanFallback)(small),
        benchmark!(std.math.atan)(small)
    );

    printResult(
        "atan2",
        benchmark2!(rtld.math.fallback.atan2Fallback)(
            small,
            small2
        ),
        benchmark2!(std.math.atan2)(
            small,
            small2
        )
    );


    // --------------------------------------------------------
    // Exponential / logarithmic
    // --------------------------------------------------------

    writeln();
    writeln("Exponential / logarithmic");
    writeln("-------------------------");

    printResult(
        "exp",
        benchmark!(rtld.math.fallback.expFallback)(small),
        benchmark!(std.math.exp)(small)
    );

    printResult(
        "exp2",
        benchmark!(rtld.math.fallback.exp2Fallback)(small),
        benchmark!(std.math.exp2)(small)
    );

    printResult(
        "log",
        benchmark!(rtld.math.fallback.logFallback)(positive),
        benchmark!(std.math.log)(positive)
    );

    printResult(
        "log2",
        benchmark!(rtld.math.fallback.log2Fallback)(positive),
        benchmark!(std.math.log2)(positive)
    );

    printResult(
        "log10",
        benchmark!(rtld.math.fallback.log10Fallback)(positive),
        benchmark!(std.math.log10)(positive)
    );

    printResult(
        "log1p",
        benchmark!(rtld.math.fallback.log1pFallback)(small),
        benchmark!(std.math.log1p)(small)
    );


    // --------------------------------------------------------
    // Power / geometry
    // --------------------------------------------------------

    writeln();
    writeln("Power / geometry");
    writeln("----------------");

    printResult(
        "pow",
        benchmark2!(rtld.math.fallback.powFallback)(
            positive,
            positive2
        ),
        benchmark2!(std.math.pow)(
            positive,
            positive2
        )
    );

    printResult(
        "hypot",
        benchmark2!(rtld.math.fallback.hypotFallback)(
            small,
            small2
        ),
        benchmark2!(std.math.hypot)(
            small,
            small2
        )
    );


    // --------------------------------------------------------
    // Hyperbolic
    // --------------------------------------------------------

    writeln();
    writeln("Hyperbolic");
    writeln("----------");

    printResult(
        "sinh",
        benchmark!(rtld.math.fallback.sinhFallback)(small),
        benchmark!(std.math.sinh)(small)
    );

    printResult(
        "cosh",
        benchmark!(rtld.math.fallback.coshFallback)(small),
        benchmark!(std.math.cosh)(small)
    );

    printResult(
        "tanh",
        benchmark!(rtld.math.fallback.tanhFallback)(small),
        benchmark!(std.math.tanh)(small)
    );

    printResult(
        "asinh",
        benchmark!(rtld.math.fallback.asinhFallback)(small),
        benchmark!(std.math.asinh)(small)
    );

    printResult(
        "acosh",
        benchmark!(rtld.math.fallback.acoshFallback)(positive),
        benchmark!(std.math.acosh)(positive)
    );

    printResult(
        "atanh",
        benchmark!(rtld.math.fallback.atanhFallback)(unit),
        benchmark!(std.math.atanh)(unit)
    );


    // --------------------------------------------------------
    // Miscellaneous
    // --------------------------------------------------------

    writeln();
    writeln("Miscellaneous");
    writeln("-------------");

    printResult(
        "fmax",
        benchmark2!(rtld.math.fallback.fmaxFallback)(
            small,
            small2
        ),
        benchmark2!(std.math.fmax)(
            small,
            small2
        )
    );

    printResult(
        "fmin",
        benchmark2!(rtld.math.fallback.fminFallback)(
            small,
            small2
        ),
        benchmark2!(std.math.fmin)(
            small,
            small2
        )
    );

    printResult(
        "copysign",
        benchmark2!(rtld.math.fallback.copysignFallback)(
            small,
            small2
        ),
        benchmark2!(std.math.copysign)(
            small,
            small2
        )
    );

    printResult(
        "fma",
        benchmark3!(rtld.math.fallback.fmaFallback)(
            small,
            small2,
            third
        ),
        benchmark3!(std.math.fma)(
            small,
            small2,
            third
        )
    );


    // --------------------------------------------------------
    // Final result
    // --------------------------------------------------------

    writeln();
    writeln("sink = ", sink);
}
