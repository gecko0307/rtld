module main;

import rtld;

int main()
{
    Stopwatch sw;
    sw.start();
    for (ulong i = 0; i < 1000; i++)
    {
    }
    auto t = sw.elapsed();
    printFmtLn("{0} µs", t.microseconds);

    return 0;
}
