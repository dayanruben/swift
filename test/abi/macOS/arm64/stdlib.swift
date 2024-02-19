// RUN: %empty-directory(%t)
// RUN: %llvm-nm -g --defined-only -f just-symbols %stdlib_dir/arm64/libswiftCore.dylib > %t/symbols
// RUN: %abi-symbol-checker %s %t/symbols
// RUN: diff -u %S/../../Inputs/macOS/arm64/stdlib/baseline %t/symbols

// REQUIRES: swift_stdlib_no_asserts
// REQUIRES: STDLIB_VARIANT=macosx-arm64

// *** DO NOT DISABLE OR XFAIL THIS TEST. *** (See comment below.)

// Welcome, Build Wrangler!
//
// This file lists APIs that have recently changed in a way that potentially
// indicates an ABI- or source-breaking problem.
//
// A failure in this test indicates that there is a potential breaking change in
// the Standard Library. If you observe a failure outside of a PR test, please
// reach out to the Standard Library team directly to make sure this gets
// resolved quickly! If your own PR fails in this test, you probably have an
// ABI- or source-breaking change in your commits. Please go and fix it.
//
// Please DO NOT DISABLE THIS TEST. In addition to ignoring the current set of
// ABI breaks, XFAILing this test also silences any future ABI breaks that may
// land on this branch, which simply generates extra work for the next person
// that picks up the mess.
//
// Instead of disabling this test, you'll need to extend the list of expected
// changes at the bottom. (You'll also need to do this if your own PR triggers
// false positives, or if you have special permission to break things.) You can
// find a diff of what needs to be added in the output of the failed test run.
// The order of lines doesn't matter, and you can also include comments to refer
// to any bugs you filed.
//
// Thank you for your help ensuring the stdlib remains compatible with its past!
//                                            -- Your friendly stdlib engineers

// Standard Library Symbols

// Swift._getRetainCount(Swift.AnyObject) -> Swift.UInt
Added: _$ss15_getRetainCountySuyXlF

// Swift._getWeakRetainCount(Swift.AnyObject) -> Swift.UInt
Added: _$ss19_getWeakRetainCountySuyXlF

// Swift._getUnownedRetainCount(Swift.AnyObject) -> Swift.UInt
Added: _$ss22_getUnownedRetainCountySuyXlF

// Swift.String.init<A, B where A: Swift._UnicodeEncoding, B: Swift.Sequence, A.CodeUnit == B.Element>(validating: B, as: A.Type) -> Swift.String?
Added: _$sSS10validating2asSSSgq__xmtcs16_UnicodeEncodingRzSTR_7ElementQy_8CodeUnitRtzr0_lufC

// Swift.String.init<A, B where A: Swift._UnicodeEncoding, B: Swift.Sequence, A.CodeUnit == Swift.UInt8, B.Element == Swift.Int8>(validating: B, as: A.Type) -> Swift.String?
Added: _$sSS10validating2asSSSgq__xmtcs16_UnicodeEncodingRzSTR_s5UInt8V8CodeUnitRtzs4Int8V7ElementRt_r0_lufC

// static Swift.String._validate<A where A: Swift._UnicodeEncoding>(_: Swift.UnsafeBufferPointer<A.CodeUnit>, as: A.Type) -> Swift.String?
Added: _$sSS9_validate_2asSSSgSRy8CodeUnitQzG_xmts16_UnicodeEncodingRzlFZ

// class __StaticArrayStorage
Added: _$ss20__StaticArrayStorageC12_doNotCallMeAByt_tcfC
Added: _$ss20__StaticArrayStorageC12_doNotCallMeAByt_tcfCTj
Added: _$ss20__StaticArrayStorageC12_doNotCallMeAByt_tcfCTq
Added: _$ss20__StaticArrayStorageC12_doNotCallMeAByt_tcfc
Added: _$ss20__StaticArrayStorageC16_doNotCallMeBaseAByt_tcfC
Added: _$ss20__StaticArrayStorageC16_doNotCallMeBaseAByt_tcfc
Added: _$ss20__StaticArrayStorageC16canStoreElements13ofDynamicTypeSbypXp_tF
Added: _$ss20__StaticArrayStorageC17staticElementTypeypXpvg
Added: _$ss20__StaticArrayStorageCMa
Added: _$ss20__StaticArrayStorageCMn
Added: _$ss20__StaticArrayStorageCMo
Added: _$ss20__StaticArrayStorageCMu
Added: _$ss20__StaticArrayStorageCN
Added: _$ss20__StaticArrayStorageCfD
Added: _$ss20__StaticArrayStorageCfd
Added: _OBJC_CLASS_$__TtCs20__StaticArrayStorage
Added: _OBJC_METACLASS_$__TtCs20__StaticArrayStorage

// struct DiscontiguousSlice
Added: _$ss18DiscontiguousSliceV10startIndexAB0D0Vyx_Gvg
Added: _$ss18DiscontiguousSliceV10startIndexAB0D0Vyx_GvpMV
Added: _$ss18DiscontiguousSliceV11descriptionSSvg
Added: _$ss18DiscontiguousSliceV11descriptionSSvpMV
Added: _$ss18DiscontiguousSliceV20_failEarlyRangeCheck_6boundsyAB5IndexVyx_G_SNyAGGtF
Added: _$ss18DiscontiguousSliceV20_failEarlyRangeCheck_6boundsyAB5IndexVyx_G_SnyAGGtF
Added: _$ss18DiscontiguousSliceV20_failEarlyRangeCheck_6boundsySnyAB5IndexVyx_GG_AHtF
Added: _$ss18DiscontiguousSliceV22_copyToContiguousArrays0eF0Vy7ElementQzGyF
Added: _$ss18DiscontiguousSliceV30_customIndexOfEquatableElementyAB0D0Vyx_GSgSg0G0QzF
Added: _$ss18DiscontiguousSliceV31_customContainsEquatableElementySbSg0F0QzF
Added: _$ss18DiscontiguousSliceV34_customLastIndexOfEquatableElementyAB0E0Vyx_GSgSg0H0QzF
Added: _$ss18DiscontiguousSliceV4basexvg
Added: _$ss18DiscontiguousSliceV4basexvpMV
Added: _$ss18DiscontiguousSliceV5IndexV11descriptionSSvg
Added: _$ss18DiscontiguousSliceV5IndexV11descriptionSSvpMV
Added: _$ss18DiscontiguousSliceV5IndexV1loiySbADyx_G_AFtFZ
Added: _$ss18DiscontiguousSliceV5IndexV2eeoiySbADyx_G_AFtFZ
Added: _$ss18DiscontiguousSliceV5IndexV4baseACQzvg
Added: _$ss18DiscontiguousSliceV5IndexV4baseACQzvpMV
Added: _$ss18DiscontiguousSliceV5IndexVMa
Added: _$ss18DiscontiguousSliceV5IndexVMn
Added: _$ss18DiscontiguousSliceV5IndexVsSHACRpzrlE4hash4intoys6HasherVz_tF
Added: _$ss18DiscontiguousSliceV5IndexVsSHACRpzrlE9hashValueSivg
Added: _$ss18DiscontiguousSliceV5IndexVsSHACRpzrlE9hashValueSivpMV
Added: _$ss18DiscontiguousSliceV5IndexVyx_GSHsSHACRpzrlMc
Added: _$ss18DiscontiguousSliceV5IndexVyx_GSLsMc
Added: _$ss18DiscontiguousSliceV5IndexVyx_GSLsWP
Added: _$ss18DiscontiguousSliceV5IndexVyx_GSQsMc
Added: _$ss18DiscontiguousSliceV5IndexVyx_GSQsWP
Added: _$ss18DiscontiguousSliceV5IndexVyx_Gs23CustomStringConvertiblesMc
Added: _$ss18DiscontiguousSliceV5IndexVyx_Gs23CustomStringConvertiblesWP
Added: _$ss18DiscontiguousSliceV5_base9subrangesAByxGx_s8RangeSetVy5IndexQzGtcfC
Added: _$ss18DiscontiguousSliceV5countSivg
Added: _$ss18DiscontiguousSliceV5countSivpMV
Added: _$ss18DiscontiguousSliceV5index5afterAB5IndexVyx_GAG_tF
Added: _$ss18DiscontiguousSliceV6_index2ofAB5IndexVyx_GSgAEQz_tF
Added: _$ss18DiscontiguousSliceV7isEmptySbvg
Added: _$ss18DiscontiguousSliceV7isEmptySbvpMV
Added: _$ss18DiscontiguousSliceV8distance4from2toSiAB5IndexVyx_G_AHtF
Added: _$ss18DiscontiguousSliceV8endIndexAB0D0Vyx_Gvg
Added: _$ss18DiscontiguousSliceV8endIndexAB0D0Vyx_GvpMV
Added: _$ss18DiscontiguousSliceV9subrangess8RangeSetVy5IndexQzGvg
Added: _$ss18DiscontiguousSliceV9subrangess8RangeSetVy5IndexQzGvpMV
Added: _$ss18DiscontiguousSliceVMa
Added: _$ss18DiscontiguousSliceVMn
Added: _$ss18DiscontiguousSliceVsSH7ElementRpzrlE4hash4intoys6HasherVz_tF
Added: _$ss18DiscontiguousSliceVsSH7ElementRpzrlE9hashValueSivg
Added: _$ss18DiscontiguousSliceVsSH7ElementRpzrlE9hashValueSivpMV
Added: _$ss18DiscontiguousSliceVsSKRzrlE5index6beforeAB5IndexVyx_GAG_tF
Added: _$ss18DiscontiguousSliceVsSMRzrlEy7ElementQzAB5IndexVyx_GciM
Added: _$ss18DiscontiguousSliceVsSMRzrlEy7ElementQzAB5IndexVyx_Gcig
Added: _$ss18DiscontiguousSliceVsSMRzrlEy7ElementQzAB5IndexVyx_GcipMV
Added: _$ss18DiscontiguousSliceVsSMRzrlEy7ElementQzAB5IndexVyx_Gcis
Added: _$ss18DiscontiguousSliceVsSQ7ElementRpzrlE2eeoiySbAByxG_AFtFZ
Added: _$ss18DiscontiguousSliceVy7ElementQzAB5IndexVyx_Gcig
Added: _$ss18DiscontiguousSliceVy7ElementQzAB5IndexVyx_GcipMV
Added: _$ss18DiscontiguousSliceVyAByxGSnyAB5IndexVyx_GGcig
Added: _$ss18DiscontiguousSliceVyAByxGSnyAB5IndexVyx_GGcipMV
Added: _$ss18DiscontiguousSliceVyxGSHsSH7ElementRpzrlMc
Added: _$ss18DiscontiguousSliceVyxGSKsSKRzrlMc
Added: _$ss18DiscontiguousSliceVyxGSQsSQ7ElementRpzrlMc
Added: _$ss18DiscontiguousSliceVyxGSTsMc
Added: _$ss18DiscontiguousSliceVyxGSlsMc
Added: _$ss18DiscontiguousSliceVyxGs23CustomStringConvertiblesMc
Added: _$ss18DiscontiguousSliceVyxGs23CustomStringConvertiblesWP

// (extension in Swift):Swift.Collection.removingSubranges(Swift.RangeSet<A.Index>) -> Swift.DiscontiguousSlice<A>
Added: _$sSlsE17removingSubrangesys18DiscontiguousSliceVyxGs8RangeSetVy5IndexQzGF

// (extension in Swift):Swift.Collection.subscript.getter : (Swift.RangeSet<A.Index>) -> Swift.DiscontiguousSlice<A>
Added: _$sSlsEys18DiscontiguousSliceVyxGs8RangeSetVy5IndexQzGcig

// property descriptor for (extension in Swift):Swift.Collection.subscript(Swift.RangeSet<A.Index>) -> Swift.DiscontiguousSlice<A>
Added: _$sSlsEys18DiscontiguousSliceVyxGs8RangeSetVy5IndexQzGcipMV

// struct RangeSet
Added: _$ss8RangeSetV10isDisjointySbAByxGF
Added: _$ss8RangeSetV10isSuperset2ofSbAByxG_tF
Added: _$ss8RangeSetV11descriptionSSvg
Added: _$ss8RangeSetV11descriptionSSvpMV
Added: _$ss8RangeSetV11subtractingyAByxGADF
Added: _$ss8RangeSetV12intersectionyAByxGADF
Added: _$ss8RangeSetV14_orderedRangesAByxGSaySnyxGG_tcfC
Added: _$ss8RangeSetV14isStrictSubset2ofSbAByxG_tF
Added: _$ss8RangeSetV16_checkInvariantsyyF
Added: _$ss8RangeSetV16formIntersectionyyAByxGF
Added: _$ss8RangeSetV16isStrictSuperset2ofSbAByxG_tF
Added: _$ss8RangeSetV19symmetricDifferenceyAByxGADnF
Added: _$ss8RangeSetV23formSymmetricDifferenceyyAByxGnF
Added: _$ss8RangeSetV2eeoiySbAByxG_ADtFZ
Added: _$ss8RangeSetV5unionyAByxGADnF
Added: _$ss8RangeSetV6RangesV010_indicesOfA0_2in15includeAdjacentSnySiGSnyxG_s15ContiguousArrayVyAIGSbtF
Added: _$ss8RangeSetV6RangesV010_unorderedC0ADyx_GSaySnyxGG_tcfC
Added: _$ss8RangeSetV6RangesV10startIndexSivg
Added: _$ss8RangeSetV6RangesV10startIndexSivpMV
Added: _$ss8RangeSetV6RangesV11descriptionSSvg
Added: _$ss8RangeSetV6RangesV11descriptionSSvpMV
Added: _$ss8RangeSetV6RangesV13_intersectionyADyx_GAFF
Added: _$ss8RangeSetV6RangesV2eeoiySbADyx_G_AFtFZ
Added: _$ss8RangeSetV6RangesV5_gaps9boundedByADyx_GSnyxG_tF
Added: _$ss8RangeSetV6RangesV5countSivg
Added: _$ss8RangeSetV6RangesV5countSivpMV
Added: _$ss8RangeSetV6RangesV6_rangeADyx_GSnyxG_tcfC
Added: _$ss8RangeSetV6RangesV7_insert10contentsOfSbSnyxG_tF
Added: _$ss8RangeSetV6RangesV7_rangesADyx_GSaySnyxGG_tcfC
Added: _$ss8RangeSetV6RangesV7_remove10contentsOfySnyxG_tF
Added: _$ss8RangeSetV6RangesV8endIndexSivg
Added: _$ss8RangeSetV6RangesV8endIndexSivpMV
Added: _$ss8RangeSetV6RangesV9_containsySbxF
Added: _$ss8RangeSetV6RangesVADyx_GycfC
Added: _$ss8RangeSetV6RangesVMa
Added: _$ss8RangeSetV6RangesVMn
Added: _$ss8RangeSetV6RangesVsSHRzrlE4hash4intoys6HasherVz_tF
Added: _$ss8RangeSetV6RangesVsSHRzrlE9hashValueSivg
Added: _$ss8RangeSetV6RangesVsSHRzrlE9hashValueSivpMV
Added: _$ss8RangeSetV6RangesVySnyxGSicig
Added: _$ss8RangeSetV6RangesVySnyxGSicipMV
Added: _$ss8RangeSetV6RangesVyx_GSHsSHRzrlMc
Added: _$ss8RangeSetV6RangesVyx_GSKsMc
Added: _$ss8RangeSetV6RangesVyx_GSQsMc
Added: _$ss8RangeSetV6RangesVyx_GSQsWP
Added: _$ss8RangeSetV6RangesVyx_GSTsMc
Added: _$ss8RangeSetV6RangesVyx_GSksMc
Added: _$ss8RangeSetV6RangesVyx_GSlsMc
Added: _$ss8RangeSetV6RangesVyx_Gs23CustomStringConvertiblesMc
Added: _$ss8RangeSetV6RangesVyx_Gs23CustomStringConvertiblesWP
Added: _$ss8RangeSetV6insert_6withinSbx_qd__t5IndexQyd__RszSlRd__lF
Added: _$ss8RangeSetV6insert10contentsOfySnyxG_tF
Added: _$ss8RangeSetV6rangesAB6RangesVyx_Gvg
Added: _$ss8RangeSetV6rangesAB6RangesVyx_GvpMV
Added: _$ss8RangeSetV6remove10contentsOfySnyxG_tF
Added: _$ss8RangeSetV6remove_6withinyx_qd__t5IndexQyd__RszSlRd__lF
Added: _$ss8RangeSetV7_rangesAB6RangesVyx_GvM
Added: _$ss8RangeSetV7_rangesAB6RangesVyx_Gvg
Added: _$ss8RangeSetV7_rangesAB6RangesVyx_GvpMV
Added: _$ss8RangeSetV7_rangesAB6RangesVyx_Gvs
Added: _$ss8RangeSetV7_rangesAByxGAB6RangesVyx_G_tcfC
Added: _$ss8RangeSetV7isEmptySbvg
Added: _$ss8RangeSetV7isEmptySbvpMV
Added: _$ss8RangeSetV8containsySbxF
Added: _$ss8RangeSetV8isSubset2ofSbAByxG_tF
Added: _$ss8RangeSetV8subtractyyAByxGF
Added: _$ss8RangeSetV9_inverted6withinAByxGqd___t5IndexQyd__RszSlRd__lF
Added: _$ss8RangeSetV9formUnionyyAByxGnF
Added: _$ss8RangeSetVAByxGycfC
Added: _$ss8RangeSetVMa
Added: _$ss8RangeSetVMn
Added: _$ss8RangeSetV_6withinAByxGqd___qd_0_tc7ElementQyd__RszSTRd__SlRd_0_5IndexQyd_0_AFRSr0_lufC
Added: _$ss8RangeSetVsSHRzrlE4hash4intoys6HasherVz_tF
Added: _$ss8RangeSetVsSHRzrlE9hashValueSivg
Added: _$ss8RangeSetVsSHRzrlE9hashValueSivpMV
Added: _$ss8RangeSetVyAByxGSnyxGcfC
Added: _$ss8RangeSetVyAByxGqd__cSTRd__SnyxG7ElementRtd__lufC
Added: _$ss8RangeSetVyxGSHsSHRzrlMc
Added: _$ss8RangeSetVyxGSQsMc
Added: _$ss8RangeSetVyxGSQsWP
Added: _$ss8RangeSetVyxGs23CustomStringConvertiblesMc
Added: _$ss8RangeSetVyxGs23CustomStringConvertiblesWP

// (extension in Swift):Swift.Collection< where A.Element: Swift.Equatable>.indices(of: A.Element) -> Swift.RangeSet<A.Index>
Added: _$sSlsSQ7ElementRpzrlE7indices2ofs8RangeSetVy5IndexQzGAB_tF

// (extension in Swift):Swift.RangeReplaceableCollection.removeSubranges(Swift.RangeSet<A.Index>) -> ()
Added: _$sSmsE15removeSubrangesyys8RangeSetVy5IndexQzGF

// (extension in Swift):Swift.Collection.indices(where: (A.Element) throws -> Swift.Bool) throws -> Swift.RangeSet<A.Index>
Added: _$sSlsE7indices5wheres8RangeSetVy5IndexQzGSb7ElementQzKXE_tKF

// (extension in Swift):Swift.MutableCollection< where A: Swift.RangeReplaceableCollection>.removeSubranges(Swift.RangeSet<A.Swift.Collection.Index>) -> ()
Added: _$sSMsSmRzrlE15removeSubrangesyys8RangeSetVy5IndexSlQzGF

// (extension in Swift):Swift.MutableCollection.moveSubranges(_: Swift.RangeSet<A.Index>, to: A.Index) -> Swift.Range<A.Index>
Added: _$sSMsE13moveSubranges_2toSny5IndexQzGs8RangeSetVyADG_ADtF

// Runtime Symbols
Added: __swift_pod_copy
Added: __swift_pod_destroy
Added: __swift_pod_direct_initializeBufferWithCopyOfBuffer
Added: __swift_pod_indirect_initializeBufferWithCopyOfBuffer
Added: __swift_validatePrespecializedMetadata
Added: __swift_exceptionPersonality
Added: _swift_willThrowTypedImpl
Added: __swift_willThrowTypedImpl
Added: __swift_enableSwizzlingOfAllocationAndRefCountingFunctions_forInstrumentsOnly
