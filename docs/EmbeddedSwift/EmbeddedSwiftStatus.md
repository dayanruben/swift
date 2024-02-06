# Embedded Swift -- Status

**⚠️ Embedded Swift is experimental. This document might be out of date with latest development.**

**‼️ Use the latest downloadable 'Trunk Development' snapshot from swift.org to use Embedded Swift. Public releases of Swift do not yet support Embedded Swift.**

For an introduction and motivation into Embedded Swift, please see "[A Vision for Embedded Swift](https://github.com/apple/swift-evolution/blob/main/visions/embedded-swift.md)", a Swift Evolution document highlighting the main goals and approaches.

## Embedded Standard Library Breakdown

This status table describes which of the following standard library features can be used in Embedded Swift:

| **Swift Standard Library Feature**          | **Currently Supported In Embedded Swift** |
|---------------------------------------------|-----------------------------------------------------|
| Array (dynamic heap-allocated container)                   | Yes    |                                      
| Array slices                                               | Yes    |                                      
| assert, precondition, fatalError                           | Partial, only StaticStrings can be used as a failure message |
| Bool, Integer types, Float types                           | Yes    |
| Codable, Encodable, Decodable                              | No     |
| Collection + related protocols                             | Yes    |
| Collection algorithms (sort, reverse)                      | Yes    |
| CustomStringConvertible, CustomDebugStringConvertible      | No     |
| Dictionary (dynamic heap-allocated container)              | Yes    |
| FixedWidthInteger + related protocols                      | Yes    |
| Hashable, Equatable, Comparable protocols                  | Yes    |
| InputStream, OutputStream                                  | No     |
| Integer parsing                                            | No     |
| KeyPaths                                                   | No     |
| Lazy collections                                           | No     |
| Mirror                                                     | No, intentionally unsupported long-term |
| Objective-C bridging                                       | No, intentionally unsupported long-term |
| Optional                                                   | Yes    |
| print / debugPrint                                         | Partial (only StaticStrings and integers) |
| Range, ClosedRange, Stride                                 | Yes    |
| Result                                                     | Yes    |
| Set (dynamic heap-allocated container)                     | Yes    |                                      
| SIMD types                                                 | Yes    |
| StaticString                                               | Yes    |
| String (dynamic)                                           | No (work in progress) |
| String Interpolations                                      | No (work in progress) |
| Unicode                                                    | No     |
| Unsafe\[Mutable\]\[Raw\]\[Buffer\]Pointer                  | Yes    |
| VarArgs                                                    | No     |

## Non-stdlib Features

This status table describes which of the following Swift features can be used in Embedded Swift:

| **Swift Feature**                           | **Currently Supported In Embedded Swift** |
|---------------------------------------------|-----------------------------------------------------|
| Swift Concurrency                   | Partial, experimental (basics of actors and tasks work in single-threaded concurrency mode)    |
