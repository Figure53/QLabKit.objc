//
//  QLKQuaternion.h
//  QLabKit
//
//  Created by Brent Lord on 8/23/20.
//
//  Copyright (c) 2020 Figure 53 LLC, https://figure53.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>


#pragma mark - GLKit legacy

union _QLKVector3 {
    struct
    {
        float x, y, z;
    };
    struct
    {
        float r, g, b;
    };
    struct
    {
        float s, t, p;
    };
    float v[3];
};
typedef union _QLKVector3 QLKVector3;

union _QLKQuaternion {
    struct
    {
        QLKVector3 v;
        float s;
    };
    struct
    {
        float x, y, z, w;
    };
    float q[4];
} __attribute__((aligned(16)));
typedef union _QLKQuaternion QLKQuaternion;

extern const QLKQuaternion QLKQuaternionIdentity;

static inline QLKQuaternion QLKQuaternionMake(float x, float y, float z, float w)
{
    QLKQuaternion q = {x, y, z, w};
    return q;
}
