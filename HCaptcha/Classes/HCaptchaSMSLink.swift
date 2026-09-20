//
//  HCaptchaSMSLink.swift
//  HCaptcha
//
//  Copyright © 2026 HCaptcha. All rights reserved.
//

import Foundation

/**
 * The recipient and message body carried by an `sms:` URL.
 *
 * Covers the RFC 5724 grammar — `sms:<recipients>[;<subscriber-params>][?<query>]` — as well as
 * the legacy `;body=` form Apple documents.
 */
internal struct HCaptchaSMSLink {
    /// The first recipient of the link, normalized for `MFMessageComposeViewController`
    let recipient: String?

    /// The pre-filled message body, percent-decoded and otherwise untouched
    let body: String?

    /// Fails for any URL that is not an `sms:` link
    init?(url: URL) {
        let string = url.absoluteString

        guard let schemeRange = string.range(of: "sms:", options: [.caseInsensitive, .anchored]) else {
            return nil
        }

        // Tolerate the authority-style `sms://` spelling seen in the wild
        var payload = string[schemeRange.upperBound...]
        while payload.hasPrefix("/") {
            payload = payload.dropFirst()
        }

        // The query and the `;` subscriber parameters are separate grammars, so `?` has to be
        // split off first. Folding them together loses the body of a link such as
        // `sms:+15551234567;phone-context=+1?body=code`.
        let head: Substring
        let query: Substring

        if let mark = payload.firstIndex(of: "?") {
            head = payload[..<mark]
            query = payload[payload.index(after: mark)...]
        } else {
            head = payload
            query = ""
        }

        let recipients = head.prefix { $0 != ";" && $0 != "&" }
        let headParameters = head.dropFirst(recipients.count).dropFirst()

        self.recipient = HCaptchaSMSLink.firstRecipient(in: recipients)
        // A `;` inside a query is body text, not a separator (RFC 3986 lists it as a sub-delim),
        // so the query is split on `&` alone. The legacy `;body=` form is read from the head.
        self.body = HCaptchaSMSLink.value(forKey: "body", in: query, separators: ["&"])
            ?? HCaptchaSMSLink.value(forKey: "body", in: headParameters, separators: [";", "&"])
    }
}

// MARK: - Private helpers

private extension HCaptchaSMSLink {
    /// `MFMessageComposeViewController` takes a recipient list, but the challenge only ever
    /// targets a single hCaptcha number, so any extras are dropped.
    static func firstRecipient(in list: Substring) -> String? {
        let first = list.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        let decoded = String(first).removingPercentEncoding ?? String(first)

        // An allowlist rather than a denylist: formatting can arrive as spaces, dashes, parens,
        // dots, or their non-breaking cousins, and anything left in that the composer rejects
        // makes it silently drop the recipient.
        let normalized = decoded.filter { $0.isASCII && ($0 == "+" || $0.isNumber) }

        return normalized.isEmpty ? nil : normalized
    }

    /// Reads a single parameter out of a `separators`-delimited list.
    ///
    /// `+` is deliberately left alone: it means a literal plus in a URI query (RFC 3986), and
    /// only means a space in form encoding, which `sms:` links do not use. Decoding happens
    /// after splitting so an encoded separator inside a value survives.
    static func value(forKey key: String, in parameters: Substring, separators: Set<Character>) -> String? {
        for item in parameters.split(whereSeparator: { separators.contains($0) }) {
            let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.first?.lowercased() == key else { continue }

            let rawValue = pair.count > 1 ? String(pair[1]) : ""
            let value = rawValue.removingPercentEncoding ?? rawValue
            return value.isEmpty ? nil : value
        }

        return nil
    }
}
