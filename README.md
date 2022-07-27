<div align = "center"><img src = "https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsexport.png" align = center></img></div>
</br>

This module allows you to compile [toolips](https://github.com/ChifiSource/Toolips.jl) apps into executable files and shared libraries. Future plans are also to port this to ARM64 and mobile. Currently available exports are:
- **so**: A shared library
- **app**: An Electron-based application
- **server**: An executable server
## Compiling a shared library (.so)
```julia
Toolips.new_app("ExampleApp")

cd("ExampleApp")

using ToolipsExport

build(so)
```
## Compiling an application (elf64/.exe)
**note:** unfortunately, you will only be able to compile apps for **your current system**. If you would like to compile them for another system, instead compile this to a shared library and distribute this with an executable that uses the shared library.
```julia
Toolips.new_app("ExampleApp")

cd("ExampleApp")

using ToolipsExport

build(app)

# we can change the title of the app by adding a second positional argument.

build(app, "My Title")
```
## Compiling an executable server (elf64/.exe)
**note:** unfortunately, you will only be able to compile servers for **your current system**. If you would like to compile them for another system, instead compile this to a shared library and distribute this with an executable that uses the shared library.
```julia
Toolips.new_app("ExampleApp")

cd("ExampleApp")

using ToolipsExport

build(server)
```
## Build multiple
```julia
Toolips.new_app("ExampleApp")

cd("ExampleApp")

using ToolipsExport

buildall(title = "My App")
# build only some:
buildall([server, app], title = "My App")
```
