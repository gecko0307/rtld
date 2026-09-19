module main;

import rtld;

void threadFunc()
{
    Thread.sleep(500);
    printStr("Thread finished\n");
}

void main()
{
    Thread t = create!Thread(&threadFunc);
    t.start();
    printStr("Thread started\n");
    t.join();
}
