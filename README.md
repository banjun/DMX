# DMX

Send & Receive DMX512 with sACN packet

ANSI E1.31 - 2018 Entertainment Technology - Lightweight streaming protocol for transport of DMX512 using ACN
<https://tsp.esta.org/tsp/documents/published_docs.php>


## Features Implemented

### sACN

Read/Write sACN packet using mapping memory with Swift struct memory layout.

- Data Packet
	- Root Layer
	- Framing Layer
	- DMP Layer

Source: send sACN packets, via standard multicast, and non-standard unicast and directed broadcast

Sink: receive sACN packets, ignore local endpoints (sent by the directed broadcast)


## Example App

DMXController
DMXController.xcodeproj