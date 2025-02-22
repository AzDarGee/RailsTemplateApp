// Import and register all your controllers
import { application } from "./application"

// Hello Controller
import HelloController from "./hello_controller"
application.register("hello", HelloController)

// Trix Controller
import TrixController from "./trix_controller"
application.register("trix", TrixController)