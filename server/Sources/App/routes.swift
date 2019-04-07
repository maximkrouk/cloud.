import Crypto
import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    router.get("hello") { req in return "Hello, world!" }
    
    
    
    let userController = UserController()
    let fileController = FSController()
    
    let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let guardAuthMiddleware = User.guardAuthMiddleware()
    let authedGroup = router.grouped([basicAuthMiddleware, guardAuthMiddleware])
    
    router.get("auth/register", use: userController.sendRegistrationHtmlForm)
    router.get("auth/login", use: userController.sendLoginHtmlForm)
    
    router.post("auth/register", use: userController.create)
    authedGroup.post("auth/login", use: userController.login)
    
    authedGroup.get("upload", use: fileController.sendUploadHtmlForm)
    authedGroup.post(FSItem.FileWrapper.self, at: "upload", use: fileController.upload)
    
    authedGroup.post("download", use: fileController.download)
    
    authedGroup.delete("delete", use: fileController.delete)
    
    authedGroup.get("list", use: fileController.list)
    
}
