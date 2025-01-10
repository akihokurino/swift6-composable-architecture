import Foundation

struct WithCursor<T: Identifiable & Sendable>: Equatable, Sendable {
    let items: [T]
    let cursor: String?
    let hasNext: Bool
    let limit: Int
    
    func next(_ nextItems: [T], cursor: String?, hasNext: Bool) -> WithCursor {
        var _next = items
        _next.append(contentsOf: nextItems)
        return WithCursor(items: _next, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    func insert(_ newItem: T) -> WithCursor {
        var _next = items
        _next.insert(newItem, at: 0)
        return WithCursor(items: _next, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    func update(_ newItem: T) -> WithCursor {
        var _next = items
        guard let index = _next.firstIndex(where: { $0.id == newItem.id }) else {
            return self
        }
        _next[index] = newItem
        return WithCursor(items: _next, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    func delete(_ deleteItem: T) -> WithCursor {
        var _next = items
        _next.removeAll(where: { $0.id == deleteItem.id })
        return WithCursor(items: _next, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    func replace(_ newItems: [T]) -> WithCursor {
        return WithCursor(items: newItems, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    func replace(_ newItems: [T], cursor: String?, hasNext: Bool) -> WithCursor {
        return WithCursor(items: newItems, cursor: cursor, hasNext: hasNext, limit: limit)
    }
        
    static func new(limit: Int = 10) -> WithCursor {
        return WithCursor(items: [], cursor: nil, hasNext: false, limit: limit)
    }
    
    static func == (lhs: WithCursor<T>, rhs: WithCursor<T>) -> Bool {
        guard lhs.cursor == rhs.cursor else { return false }
        guard lhs.items.count == rhs.items.count else { return false }
                    
        for (leftItem, rightItem) in zip(lhs.items, rhs.items) {
            guard leftItem.id == rightItem.id else { return false }
        }
                    
        return true
    }
}
