# DMX

Send & Receive DMX512 with sACN packet

ANSI E1.31 - 2018 Entertainment Technology - Lightweight streaming protocol for transport of DMX512 using ACN
<https://tsp.esta.org/tsp/documents/published_docs.php>


## Features Implemented

### sACN

Read/Write sACN packet using mapping memory with Swift struct memory layout.

Packets

- Data Packet
	- Root Layer
	- Framing Layer
	- DMP Layer
- Universe Discovery Packet
    - Root Layer
    - Framing Layer
    - Universe Discovery Layer

Source: send sACN packets, via standard multicast, and non-standard unicast and directed broadcast

Source Scheduler: manage its emission interval dynamically within 25ms (frequent) - 800ms (idle)

Sink: receive sACN packets, ignore local endpoints (sent by the directed broadcast)

Sink Scheduler: receiver with configurable interval for downstream, in case an upstream is too fast
    
Transports

- sACN multicast (239.255.UniverseHi.UniverseLo)
- directed broadcast
- unicast
- Multipeer Connectivity

Conflict Resolver (Universe Merge)

- Newset
- Higher Takes Precedence (HTP)

## Example Apps

DMXController.xcodeproj

1. DMXController: full set of demo application for this DMX library

2. DMXRelay: specific app utilizing "relay" for different transports, for example configuration:

```
// Device U1 <--Multipeer Connectivity-- Relay <--localhost:5569-- U3 TouchDesigner
// Device U2 --Multipeer Connectivity--> Relay --localhost:5568--> U4 TouchDesigner
```
