public protocol RouteGrouper {
    var leadingPath: String { get }
    var scopedMiddleware: [Middleware] { get }

    func add(middleware: [Middleware],
             method: Request.Method,
             path: String,
             handler: Route.Handler)
}

extension RouteGrouper {
    func add(_ method: Request.Method,
             path: String,
             handler: Route.Handler) {
        add(middleware: [], method: method, path: path, handler: handler)
    }
}

extension RouteGrouper {
    public var leadingPath: String { return "" }
    public var scopedMiddleware: [Middleware] { return [] }
}

extension RouteGrouper {
    public func grouped(_ path: String) -> Route.Group {
        return Route.Group(parent: self, leadingPath: path, scopedMiddleware: scopedMiddleware)
    }

    public func grouped(_ path: String, _ body: @noescape (group: Route.Group) -> Void) {
        let group = grouped(path)
        body(group: group)
    }

    public func grouped(_ middlewares: Middleware...) -> Route.Group {
        return Route.Group(parent: self, leadingPath: leadingPath, scopedMiddleware: scopedMiddleware + middlewares)
    }

    public func grouped(_ middlewares: [Middleware]) -> Route.Group {
        return Route.Group(parent: self, leadingPath: leadingPath, scopedMiddleware: scopedMiddleware + middlewares)
    }

    public func grouped(_ middlewares: Middleware..., _ body: @noescape (group: Route.Group) -> Void) {
        let groupObject = grouped(middlewares)
        body(group: groupObject)
    }

    public func grouped(collection middlewares: [Middleware], _ body: @noescape (group: Route.Group) -> Void) {
        let groupObject = grouped(middlewares)
        body(group: groupObject)
    }
}

extension Application: RouteGrouper {
    public func add(middleware: [Middleware],
                    method: Request.Method,
                    path: String,
                    handler: Route.Handler) {
        // Convert Route.Handler to Request.Handler
        let wrapped: Request.Handler = Request.Handler { request in
            return try handler(request).makeResponse()
        }
        let responder: Responder = middleware.reduce(wrapped) { resp, nextMiddleware in
            return nextMiddleware.chain(to: resp)
        }
        let route = Route(host: "*", method: method, path: path, responder: responder)
        routes.append(route)
    }
}
