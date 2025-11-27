@testable import MQTTNIO
import Testing

@Suite
struct SizeTests {
    let existentialContainerBufferSize = 24

    private func checkSize<T>(_ type: T.Type) {
        #expect(MemoryLayout<T>.size <= existentialContainerBufferSize)
    }

    @Test func packetSize() { checkSize(MQTTPacket.self) }
    @Test func acknowledgementSize() { checkSize(MQTTPacket.Acknowledgement.self) }
    @Test func connectionAcknowledgementSize() { checkSize(MQTTPacket.ConnAck.self) }
    @Test func connectSize() { checkSize(MQTTPacket.Connect.self) }
    @Test func disconnect() { checkSize(MQTTPacket.Disconnect.self) }
    @Test func pingRequestSize() { checkSize(MQTTPacket.PingReq.self) }
    @Test func pingReponseSize() { checkSize(MQTTPacket.PingResp.self) }
    @Test func publishSize() { checkSize(MQTTPacket.Publish.self) }
    @Test func subscribeAcknowledgementSize() { checkSize(MQTTPacket.SubAck.self) }
    @Test func subscribeSize() { checkSize(MQTTPacket.Subscribe.self) }
    @Test func unsubscribeAcknowledgementSize() { checkSize(MQTTPacket.UnsubAck.self) }
    @Test func unsubscribeSize() { checkSize(MQTTPacket.Unsubscribe.self) }
    @Test func inboundSize() { checkSize(MQTTPacket.Inbound.self) }
}
