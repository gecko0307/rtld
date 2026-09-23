module rtld.core.atomic;

version(LDC)
{
    import ldc.llvmasm;

    /// Atomic Compare-And-Swap.
    bool atomicCAS(shared(uint)* ptr, uint cmp, uint val) @nogc nothrow
    {
        return __asm!bool(
            "lock; cmpxchg $3, ($1); setz $0", 
            "={ax},r,r,r,~{memory},~{cc}", 
            ptr, cmp, val
        );
    }

    /// Atomic write.
    void atomicStore(shared(bool)* ptr, bool val) @nogc nothrow
    {
        __asm!void(
            "xchg $1, ($0)", 
            "r,r,~{memory}", 
            ptr, val
        );
    }

    /// Atomic read.
    bool atomicLoad(const shared(bool)* ptr) @nogc nothrow
    {
        return __asm!bool(
            "movb ($1), $0", 
            "=r,r,~{memory}", 
            ptr
        );
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
