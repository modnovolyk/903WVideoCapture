<img src="https://cloud.githubusercontent.com/assets/4676904/24254191/efb601e8-0fea-11e7-8b03-2bd16b12f7bd.png" width="30" height="30"> Analog Video Capture in iOS
======================================

![903W Photo](/Assets/903W.png)

Analog video is still used in many systems today where low latency is crucial. One good example is racing FPV systems.

Due to lack of complete USB On-The-Go (OTG) support in iOS, there is no other way than capture analog video over Wi-Fi through special video encoding device like WIFI AVIN 903W. It receives AV signal on input, encodes video and broadcasts it into Wi-Fi network using a proprietary protocol. WIFI AVIN 903W protocol uses UDP on the transport layer and H264 standard for video compression.

This repository contains sample application that demonstrates work with WIFI AVIN 903W proprietary protocol.

## Components

The source code contains 5 major components:
- `IncomingPacket` and `OutgoingPacket` protocols and implementations - represent packets that could be received or sent over WIFI AVIN 903W proprietary protocol
- `Socket` protocol and `UDPSocket` class - a simple wrapper around BSD socket. Uses blocking `recvfrom` in a separate thread to receive data and non-blocking `sendto` to send.
- `NaluBuffer` protocol and `RawH264NaluBuffer` class - buffer that accumulates packets until complete NALU is received
- `VideoStreamConverter` protocol and `ElementaryVideoStreamConverter` class - converts elementary stream (Annex B) to AVCC format and returns `CMSampleBuffers`
- `NetworkVideoStream` protocol and `W903NetworkVideoStream` class - composes elements into complete system, analyzes incoming packets and sends appropriate responses

![Components Diagram](/Assets/components.png)

## Known Issues

Before use this code in production consider the following steps:
- Move stream parsing and conversion to a background thread (you can configure `UDPSocket` with custom delegation `DispatchQueue` for this purpose)
- Decrease number of memory allocations/deallocations during packet receiving and conversion (reuse same `Unsafe​Mutable​Buffer​Pointer`)
- Consider setting presentation timestamp of resulting `CMSampleBuffers` for smoother video output
- Handle player restart on the protocol level (process already stacked frames)
- Add WIFI AVIN 903W settings configuration support
- Improve error handling (remove usage of forced-try at least)
- Make `NaluBuffer` implementation conform to `Sequence` and/or `Collection` protocols to be legitimate Swift citizen

## License

This sample project is distributed under the MIT license. See LICENSE for details.
