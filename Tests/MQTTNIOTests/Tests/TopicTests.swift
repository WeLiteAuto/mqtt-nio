@testable import MQTTNIO
import Testing

@Suite
struct TopicTests {
    @Test
    func topicValidation() {
        #expect("/".isValidMqttTopic)
        #expect("/test".isValidMqttTopic)
        #expect("one/two/three".isValidMqttTopic)
        #expect("one//three".isValidMqttTopic)
        #expect("$SYS".isValidMqttTopic)
        #expect("$SYS/test".isValidMqttTopic)

        #expect(!"one/+/three".isValidMqttTopic)
        #expect(!"one/two/#".isValidMqttTopic)
        #expect(!"/+".isValidMqttTopic)
        #expect(!"/#".isValidMqttTopic)
        #expect(!"test/+".isValidMqttTopic)
        #expect(!"test/#".isValidMqttTopic)
        #expect(!"+/".isValidMqttTopic)
        #expect(!"+/test".isValidMqttTopic)
        #expect(!"one/+/three".isValidMqttTopic)
        #expect(!"#".isValidMqttTopic)
        #expect(!"+".isValidMqttTopic)
        #expect(!"".isValidMqttTopic)
        #expect(!"\u{0000}".isValidMqttTopic)
        #expect(!"#/".isValidMqttTopic)
        #expect(!"#/test".isValidMqttTopic)
        #expect(!"one/#/three".isValidMqttTopic)
        #expect(!"one/two#".isValidMqttTopic)
        #expect(!"one/two+".isValidMqttTopic)
        #expect(!"one/+two/three".isValidMqttTopic)
        #expect(!"one/two+/three".isValidMqttTopic)
    }

    @Test
    func topicFilterValidation() {
        #expect("one/two/three".isValidMqttTopicFilter)
        #expect("one//three".isValidMqttTopicFilter)
        #expect("$SYS".isValidMqttTopicFilter)
        #expect("$SYS/test".isValidMqttTopicFilter)
        #expect("/".isValidMqttTopicFilter)
        #expect("/test".isValidMqttTopicFilter)
        #expect("#".isValidMqttTopicFilter)
        #expect("+".isValidMqttTopicFilter)
        #expect("one/+/three".isValidMqttTopicFilter)
        #expect("one/two/#".isValidMqttTopicFilter)
        #expect("/+".isValidMqttTopicFilter)
        #expect("/#".isValidMqttTopicFilter)
        #expect("test/+".isValidMqttTopicFilter)
        #expect("test/#".isValidMqttTopicFilter)
        #expect("+/".isValidMqttTopicFilter)
        #expect("+/test".isValidMqttTopicFilter)
        #expect("one/+/three".isValidMqttTopicFilter)

        #expect(!"".isValidMqttTopicFilter)
        #expect(!"\u{0000}".isValidMqttTopicFilter)
        #expect(!"#/".isValidMqttTopicFilter)
        #expect(!"#/test".isValidMqttTopicFilter)
        #expect(!"one/#/three".isValidMqttTopicFilter)
        #expect(!"one/two#".isValidMqttTopicFilter)
        #expect(!"one/two+".isValidMqttTopicFilter)
        #expect(!"one/+two/three".isValidMqttTopicFilter)
        #expect(!"one/two+/three".isValidMqttTopicFilter)
    }

    @Test
    func topicFilterMatches() {
        #expect("one/two/three".matchesMqttTopicFilter("one/two/three"))
        #expect("one/two/three".matchesMqttTopicFilter("one/+/three"))
        #expect("one/two/three".matchesMqttTopicFilter("one/#"))

        #expect(!"one/two/three".matchesMqttTopicFilter("One/Two/Three"))

        #expect(!"/one/two/three".matchesMqttTopicFilter("one/two/three"))
        #expect("/one/two/three".matchesMqttTopicFilter("/one/two/three"))

        #expect("one/two/three/four/five/six".matchesMqttTopicFilter("one/two/#"))
        #expect("one/two/three/four/five/six".matchesMqttTopicFilter("one/+/three/#"))
        #expect("one/two/three/four/five/six".matchesMqttTopicFilter("one/two/+/four/+/six"))

        #expect(!"one/two/three".matchesMqttTopicFilter("one/two"))
        #expect(!"one/two/three".matchesMqttTopicFilter("one/+"))
        #expect(!"one/two/three".matchesMqttTopicFilter("one/two/three/four"))
        #expect("one/two/three".matchesMqttTopicFilter("one/two/three/#"))
        #expect(!"one/two/three".matchesMqttTopicFilter("one/two/three/+"))

        #expect("one/two/three".matchesMqttTopicFilter("#"))
        #expect("one".matchesMqttTopicFilter("one/#"))
        #expect(!"one".matchesMqttTopicFilter("one/+"))

        #expect("one//three".matchesMqttTopicFilter("one//three"))
        #expect("one//three".matchesMqttTopicFilter("one/#"))
        #expect("one//three".matchesMqttTopicFilter("one//#"))

        #expect(!"$SYS/test".matchesMqttTopicFilter("#"))
        #expect(!"$SYS/test".matchesMqttTopicFilter("#/test"))
        #expect(!"$SYS/test".matchesMqttTopicFilter("+"))
        #expect(!"$SYS/test".matchesMqttTopicFilter("+/test"))
        #expect("$SYS/test".matchesMqttTopicFilter("$SYS/+"))
        #expect("$SYS/test".matchesMqttTopicFilter("$SYS/#"))
        #expect("$SYS/test".matchesMqttTopicFilter("$SYS/test"))
    }
}
