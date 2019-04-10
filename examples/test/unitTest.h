#pragma once

#include "daScript/daScript.h"

//sample of your-engine-float3-type to be aliased as float3 in daScript.
struct Point3 { float x, y, z; };

__forceinline Point3 getSamplePoint3() {return Point3{0,1,2};}
__forceinline Point3 doubleSamplePoint3(const Point3 &a) { return Point3{ a.x + a.x, a.y + a.y, a.z + a.z }; }

struct TestObjectFoo {
    int fooData;
    int propAdd13() {
        return fooData + 13;
    }
};

int *getPtr();

void testFields ( das::Context * ctx );
void test_das_string(const das::Block & block, das::Context * context);
vec4f new_and_init ( das::Context & context, das::SimNode_CallBase * call, vec4f * );