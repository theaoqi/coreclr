// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

// Copyright (c) Loongson Technology. All rights reserved.

#include "asmconstants.h"
#include "unixasmmacros.inc"

////FIXME for MIPS: how to call these functions on MIPS64.
// ------------------------------------------------------------------
// Macro to generate PInvoke Stubs.
// $__PInvokeStubFuncName : function which calls the actual stub obtained from VASigCookie
// $__PInvokeGenStubFuncName : function which generates the IL stubs for PInvoke
//
// Params :-
// $FuncPrefix : prefix of the function name for the stub
//                     Eg. VarargPinvoke, GenericPInvokeCalli
// $VASigCookieReg : register which contains the VASigCookie
// $SaveFPArgs : "Yes" or "No" . For varidic functions FP Args are not present in FP regs
//                        So need not save FP Args registers for vararg Pinvoke

.macro PINVOKE_STUB __PInvokeStubFuncName,__PInvokeGenStubFuncName,__PInvokeStubWorkerName,VASigCookieReg,HiddenArg,SaveFPArgs,ShiftLeftAndOrSecret=0

        NESTED_ENTRY \__PInvokeStubFuncName, _TEXT, NoHandler
        .set noreorder

        // get the stub
        ld   t0, VASigCookie__pNDirectILStub(\VASigCookieReg)

        // if null goto stub generation
        beq  t0, zero, \__PInvokeGenStubFuncName
        daddiu  t9, t9, %lo(\__PInvokeGenStubFuncName - \__PInvokeStubFuncName)   //NOTE: here 16-bits is enough.

        .if (\ShiftLeftAndOrSecret == 1)
            //
            // We need to distinguish between a MethodDesc* and an unmanaged target.
            // The way we do this is to shift the managed target to the left by one bit and then set the
            // least significant bit to 1.  This works because MethodDesc* are always 8-byte aligned.
            //
            dsll            \HiddenArg, \HiddenArg, 1
            ori             \HiddenArg, \HiddenArg, 1
        .endif

        jr  t0
        ori t9, t0, 0

        NESTED_END \__PInvokeStubFuncName, _TEXT

        NESTED_ENTRY \__PInvokeGenStubFuncName, _TEXT, NoHandler

        PROLOG_WITH_TRANSITION_BLOCK 0, 0, \SaveFPArgs

        // a2 = Umanaged Target\MethodDesc
        move  a2, \HiddenArg

        // a1 = VaSigCookie
        move  a1, \VASigCookieReg

        // a0 = pTransitionBlock
        daddiu  a0, sp, __PWTB_TransitionBlock

        // save hidden arg
        move  s0, \HiddenArg

        // save VASigCookieReg
        move  s1, \VASigCookieReg

        lui  AT, %hi(%neg(%gp_rel(\__PInvokeGenStubFuncName)))
        daddu  AT, AT, t9
        daddiu  AT, AT, %lo(%neg(%gp_rel(\__PInvokeGenStubFuncName)))
        ld  t9, %call16(\__PInvokeStubWorkerName)(AT)
        jalr t9

        // restore VASigCookieReg
        move  \VASigCookieReg, s1

        // restore hidden arg (method desc or unmanaged target)
        move  \HiddenArg, s0

        EPILOG_WITH_TRANSITION_BLOCK_TAILCALL

        EPILOG_BRANCH       \__PInvokeStubFuncName

        NESTED_END \__PInvokeGenStubFuncName, _TEXT
.endm

// ------------------------------------------------------------------
// IN:
// InlinedCallFrame (a0) = pointer to the InlinedCallFrame data, including the GS cookie slot (GS cookie right
//                         before actual InlinedCallFrame data)
//
//
NESTED_ENTRY JIT_PInvokeBegin, _TEXT, NoHandler

    ////FIXME for MIPS: not implements!!!
    sw  zero, 0(zero)
    break

NESTED_END JIT_PInvokeBegin, _TEXT

// ------------------------------------------------------------------
// IN:
// InlinedCallFrame (a0) = pointer to the InlinedCallFrame data, including the GS cookie slot (GS cookie right
//                         before actual InlinedCallFrame data)
//
//
LEAF_ENTRY JIT_PInvokeEnd, _TEXT

    ////FIXME for MIPS: not implements!!!
    sw  zero, 0(zero)
    break

//LOCAL_LABEL(RarePath):
    //b       C_FUNC(JIT_PInvokeEndRarePath)

LEAF_END JIT_PInvokeEnd, _TEXT

// ------------------------------------------------------------------
// VarargPInvokeStub & VarargPInvokeGenILStub
// There is a separate stub when the method has a hidden return buffer arg.
//
// in:
// a0 = VASigCookie*          //FIXME for MIPS: how to control the arguments ?
// t2 = MethodDesc *
//
PINVOKE_STUB VarargPInvokeStub, VarargPInvokeGenILStub, VarargPInvokeStubWorker, a0, t2, 0


// ------------------------------------------------------------------
// GenericPInvokeCalliHelper & GenericPInvokeCalliGenILStub
// Helper for generic pinvoke calli instruction
//
// in:
// t3 = VASigCookie*
// t2 = Unmanaged target
//
PINVOKE_STUB GenericPInvokeCalliHelper, GenericPInvokeCalliGenILStub, GenericPInvokeCalliStubWorker, t3, t2, 1, 1

//// ------------------------------------------------------------------
//// VarargPInvokeStub_RetBuffArg & VarargPInvokeGenILStub_RetBuffArg
//// Vararg PInvoke Stub when the method has a hidden return buffer arg
////
//// in:
//// a1 = VASigCookie*          //FIXME for MIPS: not used ???
//// t2 = MethodDesc*
////
//PINVOKE_STUB VarargPInvokeStub_RetBuffArg, VarargPInvokeGenILStub_RetBuffArg, VarargPInvokeStubWorker, a1, t8, 0
