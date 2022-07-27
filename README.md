<div align = "center"><img src = "https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsexport.png" align = center></img></div>
</br>

This module allows you to compile toolips apps into shared libraries, executables, and mobile apps to be ran natively (**yes, this is real**), as of right now the project is currently a **work in progress**, though compiling to a shared library does work! The part of this module that is still in the works is the export templates, which are to wrap the shared library into native projects, or compile an executable server, or application with Blink.jl.
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
```
