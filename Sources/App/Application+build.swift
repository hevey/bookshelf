import Hummingbird
import Logging
import PostgresNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var inMemoryTesting: Bool { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "Bookshelf")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()
    let router = Router()
    // Add logging
    router.add(middleware: LogRequestsMiddleware(.info))
    // Add health endpoint
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
    
    var postgresRepository: BookPostgresRepository?
    if !arguments.inMemoryTesting {
        let client = PostgresClient(
            configuration: .init(host: "localhost", username: "postgres", password: "postgres", database: "hummingbird", tls: .disable),
            
            backgroundLogger: logger
        )
        let repository = BookPostgresRepository(client: client, logger: logger)
            postgresRepository = repository
            BookController(repository: repository).addRoutes(to: router.group("books"))
    } else {
        BookController(repository: BookMemoryRepository()).addRoutes(to: router.group("books"))
    }
    
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Bookshelf"
        ),
        logger: logger
    )
    
    if let postgresRepository {
        app.addServices(postgresRepository.client)
        app.beforeServerStarts {
            try await postgresRepository.createTable()
        }
    }
    
    return app
}
