import Foundation
import Testing
@testable import AppleRemotePacketLogger

struct G9N9NHCIAuthorizationTests {
    @Test func nativeUserConfirmationRemainsConsumableAfterTwoMinutes() {
        var wait = PacketLoggerAuthorizationWait(requiresPreparedRule: true)
        wait.begin()
        let expiredAt128 = wait.expire(after: 128)
        let expiredAt600 = wait.expire(after: 600)
        let accepted = wait.complete()
        let duplicate = wait.complete()
        #expect(!expiredAt128 && !expiredAt600)
        #expect(accepted && !duplicate)
    }

    @Test func nonPreparedFlowKeepsItsBoundAndRejectsLateReply() {
        var wait = PacketLoggerAuthorizationWait(requiresPreparedRule: false)
        wait.begin()
        let early = wait.expire(after: 29)
        let expired = wait.expire(after: 30)
        let lateReply = wait.complete()
        #expect(!early && expired && !lateReply)
    }

    @Test func stoppingStillRejectsTheOldNativeReply() {
        var wait = PacketLoggerAuthorizationWait(requiresPreparedRule: true)
        wait.begin()
        wait.cancel()
        let lateReply = wait.complete()
        #expect(!lateReply)
    }

    private var strong: [String: Any] {
        ["class": "user", "group": "admin", "authenticate-user": true,
         "shared": false, "timeout": 0]
    }

    @Test func omittedAndExplicitFalseSessionOwnerAreEquivalent() {
        #expect(PacketLoggerAuthorizationRulePolicy.isStrongEnough(strong))
        var normalized = strong
        normalized["session-owner"] = false
        #expect(PacketLoggerAuthorizationRulePolicy.isStrongEnough(normalized))
        normalized["session-owner"] = true
        #expect(!PacketLoggerAuthorizationRulePolicy.isStrongEnough(normalized))
        normalized["session-owner"] = "false"
        #expect(!PacketLoggerAuthorizationRulePolicy.isStrongEnough(normalized))
    }

    @Test func everyAuthenticationBoundaryIsStillRequired() {
        for (key, value) in [("class", "allow" as Any), ("group", "everyone"),
            ("authenticate-user", false), ("shared", true), ("timeout", 300),
            ("rule", ["allow"])] {
            var rule = strong
            rule[key] = value
            #expect(!PacketLoggerAuthorizationRulePolicy.isStrongEnough(rule))
        }
        for key in ["class", "group", "authenticate-user", "shared", "timeout"] {
            var rule = strong
            rule.removeValue(forKey: key)
            #expect(!PacketLoggerAuthorizationRulePolicy.isStrongEnough(rule))
        }
    }
}
