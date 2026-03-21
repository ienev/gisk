import Foundation

public struct Commit: Identifiable, Hashable {
    public let id: String          // full SHA
    public let shortSHA: String
    public let subject: String     // first line of message
    public let body: String        // full message
    public let author: String
    public let authorEmail: String
    public let authorDate: Date
    public let committer: String
    public let committerDate: Date
    public let parentIDs: [String]
    public var childIDs: [String] = []
    public var refs: [Ref] = []

    // Assigned by GraphLayoutEngine
    public var graphLane: GraphLane?

    public init(
        id: String,
        shortSHA: String,
        subject: String,
        body: String,
        author: String,
        authorEmail: String,
        authorDate: Date,
        committer: String,
        committerDate: Date,
        parentIDs: [String],
        childIDs: [String] = [],
        refs: [Ref] = [],
        graphLane: GraphLane? = nil
    ) {
        self.id = id
        self.shortSHA = shortSHA
        self.subject = subject
        self.body = body
        self.author = author
        self.authorEmail = authorEmail
        self.authorDate = authorDate
        self.committer = committer
        self.committerDate = committerDate
        self.parentIDs = parentIDs
        self.childIDs = childIDs
        self.refs = refs
        self.graphLane = graphLane
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Commit, rhs: Commit) -> Bool {
        lhs.id == rhs.id
    }
}
