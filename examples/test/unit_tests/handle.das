require UnitTest

struct TestObjectFooNative
    fooData : int

struct TestObjectBarNative
    fooPtr:TestObjectFooNative?
    barData:float

[export]
def test:bool
    // with native type
    let ( a:TestObjectFooNative?;b:TestObjectBarNative?;idummy:int;fdummy:float)
        a?.fooData ?? idummy = 1
        assert(idummy==1)
        a = new TestObjectFooNative
        a?.fooData ?? idummy = 2
        assert(a.fooData==2 & idummy==1)
        b?.barData ?? fdummy = 1.0
        assert(fdummy==1.0)
        b = new TestObjectBarNative
        b?.barData ?? fdummy = 2.0
        assert(b.barData==2.0 & fdummy==1.0)
        b?.fooPtr?.fooData ?? idummy = 3
        assert(idummy==3)
        b.fooPtr = a
        b?.fooPtr?.fooData ?? idummy = 4
        assert(b.fooPtr.fooData==4 & idummy==3)
    // with identical external type
    let ( a:TestObjectFoo?;b:TestObjectBar?;idummy:int;fdummy:float)
        a?.fooData ?? idummy = 1
        assert(idummy==1)
        a = new TestObjectFoo
        a?.fooData ?? idummy = 2
        assert(a.fooData==2 & idummy==1)
        b?.barData ?? fdummy = 1.0
        assert(fdummy==1.0)
        b = new TestObjectBar
        b?.barData ?? fdummy = 2.0
        assert(b.barData==2.0 & fdummy==1.0)
        b?.fooPtr?.fooData ?? idummy = 3
        assert(idummy==3)
        b.fooPtr = a
        b?.fooPtr?.fooData ?? idummy = 4
        assert(b.fooPtr.fooData==4 & idummy==3)
    return true