import Authentication
import FluentSQLite
import Leaf
import Vapor

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    // Register providers first
    // Leaf provider
    try services.register(LeafProvider())
    // SQLite provider
    try services.register(FluentSQLiteProvider())
    // Auth provider
    try services.register(AuthenticationProvider())
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Configure the rest of your application here
    // Setup view renderer
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    // Create SQLite database
    let directoryConfig = DirectoryConfig.detect()
    let sqlite = try SQLiteDatabase(storage: .file(path: "\(directoryConfig.workDir)sqlite.db"))//.memory)
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    
    // Make migrations
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: User.self, database: .sqlite)
    migrationConfig.add(model: FSItem.self, database: .sqlite)
    services.register(migrationConfig)
    
}
