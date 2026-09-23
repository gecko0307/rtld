module rtld.core.atomic;

version(LDC)
{
    import ldc.llvmasm;

    /// Atomic Compare-And-Swap.
    bool atomicCAS(shared(uint)* ptr, uint cmp, uint val) @nogc nothrow
    {
        version(X86_64)
        {
            return __asm!bool(
                "lock; cmpxchg $3, ($1); setz $0", 
                "={ax},r,r,r,~{memory},~{cc}", 
                ptr, cmp, val
            );
        }
        else version(X86)
        {
            return __asm!bool(
                "lock; cmpxchg $3, ($1); setz $0", 
                "={ax},r,r,r,~{memory},~{cc}", 
                ptr, cmp, val
            );
        }
        else version(AArch64)
        {
            return __asm!bool(
                "1: ldaxr w4, [$1]\n" ~
                "   cmp w4, ${2:w}\n" ~
                "   b.ne 2f\n" ~
                "   stlxr w5, ${3:w}, [$1]\n" ~
                "   cbnz w5, 1b\n" ~
                "   mov $0, #1\n" ~
                "   b 3f\n" ~
                "2: clrex\n" ~
                "   mov $0, #0\n" ~
                "3:",
                "=r,r,r,r,~{x4},~{x5},~{memory},~{cc}",
                ptr, cmp, val
            );
        }
        else
        {
            return true;
        }
    }

    /// Atomic write.
    void atomicStore(shared(bool)* ptr, bool val) @nogc nothrow
    {
        version(X86_64)
        {
            __asm!void("xchg $1, ($0)", "r,r,~{memory}", ptr, val);
        }
        else version(X86)
        {
            __asm!void("xchg $1, ($0)", "r,r,~{memory}", ptr, val);
        }
        else version(AArch64)
        {
            __asm!void("stlrb ${1:w}, [$0]", "r,r,~{memory}", ptr, val);
        }
        else
        {
            *cast(bool*)p = val;
        }
    }

    /// Atomic read.
    bool atomicLoad(const shared(bool)* ptr) @nogc nothrow
    {
        version(X86_64)
        {
            return __asm!bool("movb ($1), $0", "=r,r,~{memory}", ptr);
        }
        else version(X86)
        {
            return __asm!bool("movb ($1), $0", "=r,r,~{memory}", ptr);
        }
        else version(AArch64)
        {
            return __asm!bool("ldarb ${0:w}, [$1]", "=r,r,~{memory}", ptr);
        }
        else
        {
            return *cast(const(bool)*)p;
        }
    }
}
else
{
    version(X86_64)
    {
        enum UseInlineAsm = true;
    }
    else version(X86)
    {
        enum UseInlineAsm = true;
    }
    else
    {
        enum UseInlineAsm = false;
    }

    /// Atomic Compare-And-Swap.
    bool atomicCAS(shared(uint)* p, uint cmp, uint val) @nogc nothrow
    {
        static if (UseInlineAsm)
        {
            version(X86_64)
            {
                asm @nogc nothrow
                {
                    mov EAX, cmp;
                    mov EDX, val;
                    mov RCX, p;
                    lock;
                    cmpxchg [RCX], EDX;
                    setz AL;
                }
            }
            else version(X86)
            {
                asm @nogc nothrow
                {
                    mov EAX, cmp;
                    mov EDX, val;
                    mov ECX, p;
                    lock;
                    cmpxchg [ECX], EDX;
                    setz AL;
                }
            }
        }
        else
        {
            return true; 
        }
    }
    
    /// Atomic write.
    void atomicStore(shared(bool)* p, bool val) @nogc nothrow
    {
        static if (UseInlineAsm)
        {
            version(X86_64)
            {
                asm @nogc nothrow
                {
                    mov AL, val;
                    mov RCX, p;
                    xchg [RCX], AL;
                }
            }
            else version(X86)
            {
                asm @nogc nothrow
                {
                    mov AL, val;
                    mov ECX, p;
                    xchg [ECX], AL;
                }
            }
        }
        else
        {
            *cast(bool*)p = val;
        }
    }
    
    /// Atomic read.
    bool atomicLoad(const shared(bool)* p) @nogc nothrow
    {
        static if (UseInlineAsm)
        {
            version(X86_64)
            {
                asm @nogc nothrow
                {
                    mov RCX, p;
                    mov AL, [RCX];
                }
            }
            else version(X86)
            {
                asm @nogc nothrow
                {
                    mov ECX, p;
                    mov AL, [ECX];
                }
            }
        }
        else
        {
            return *cast(const(bool)*)p;
        }
    }
}
