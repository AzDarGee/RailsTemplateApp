// Import and register all your controllers
import { application } from "./application"

// Hello Controller
import HelloController from "./hello_controller"
application.register("hello", HelloController)