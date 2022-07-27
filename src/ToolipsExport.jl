"""
Created in July, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### ToolipsExport
Toolips Export allows one to compile toolips apps using the ToolipsExport.build() method.
##### Module Composition
- [**Toolips**](https://github.com/ChifiSource/Toolips.jl)
"""

module ToolipsExport
using PackageCompiler
using TOML
using Pkg

macro L_str(s::String)
    s
end

"""
### ExportTemplate{type}
The ExportTemplate holds a Symbol used by dispatch in order to change
the export type from the `build()` method. The currently available export options
are:
- so
- app
- server \n
In order to compile these, simply provide the export template to the `build` method.
##### example
```
# Inside of this module:
const so = ExportTemplate{:so}()

# Using this template:
build(so)
```
------------------
##### constructors
- ExportTemplate{type}()
"""
mutable struct ExportTemplate{type} end

const so = ExportTemplate{:so}()
const app = ExportTemplate{:app}()
const server = ExportTemplate{:server}()
const android = ExportTemplate{:android}()

"""
**Toolips Export**
### build_copy() -> ::String
------------------
Builds a copy of the project in the current working directory. Returns the
project's name from the `Project.toml` file.
#### example
```
# From Toolips project working directory
build_copy()
```
"""
function build_copy()
    name = TOML.parse(read("Project.toml", String))["name"]
    if ~(isdir(name))
        Pkg.generate(name)
    end
    cp("src", "$name/src", force = true)
    cp("Project.toml", "$name/Project.toml", force = true)
    cp("Manifest.toml", "$name/Manifest.toml", force = true)
    cd(name)
    name::String
end

"""
**Toolips Export**
### append_src(name::String, append::String) -> _
------------------
Appends the data in `append` to  the file of name `name`. This is used by
the `build` functions to add main functions and C callable functions.
#### example
```
append_src("ToolipsApp", "newsource")
```
"""
function append_src(name::String, append::String)
    current_file::String = read("src/$name.jl", String)
    lastend::UnitRange{Int64} = findlast("end", current_file)
    current_file = current_file[1:minimum(lastend) - 1] * append
    open("src/$name.jl", "w") do io
        write(io, current_file)
    end
end

"""
**Toolips Export**
### build(et::ExportTemplate{:so}) -> _
------------------
Builds a new shared library from the working directory of a toolips project.
#### example
```
# From a toolips project directory:
build(so)
```
"""
function build(et::ExportTemplate{:so} = so)
    name = build_copy()
    open("src/$name.jl", "a") do io
        write(io, """
        """)
    end
    append_src(name, """\n
    Base.@ccallable function _start()::Cvoid
        start()
    end
   end # - module""")
    touch("Makefile")
    open("Makefile", "w") do io
        write(io, L"""# Makefile

JULIA ?= julia
DLEXT := $(shell $(JULIA) --startup-file=no -e 'using Libdl; print(Libdl.dlext)')

TARGET="../MyLibCompiled"

MYLIB_INCLUDES = $(TARGET)/include/julia_init.h $(TARGET)/include/mylib.h
MYLIB_PATH := $(TARGET)/lib/libmylib.$(DLEXT)

$(MYLIB_PATH) $(MYLIB_INCLUDES): build/build.jl src/MyLib.jl
	$(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
	$(JULIA) --startup-file=no --project=build -e 'using Pkg; Pkg.instantiate(); include("build/build.jl")'

.PHONY: clean
clean:
	$(RM) *~ *.o *.$(DLEXT)
	$(RM) -Rf $(TARGET)""")
    end
    create_library(".", "$(name)so";
                      lib_name=name)
end

"""
**Toolips Export**
### build(et::ExportTemplate{:app}, title::String = "toolips app") -> _
------------------
Builds a new compiled application from the current working directory. `title`
will become the title of the Window.
#### example
```
# From a toolips project directory:
build(app)
```
"""
function build(et::ExportTemplate{:app}, title::String = "toolips app")
    name = build_copy()
    Pkg.activate(".")
    Pkg.add("Blink")
 append_src(name, """\n
    using Blink
    function julia_main()::Cint
        start("127.0.0.1", 8003)
        w = Window()
        title(w, $title)
        loadurl(w, "http://127.0.0.1:8003")
        while active(w)

        end
        return(0)
    end
end # - module""")
    create_app(".", "$(name)app")
    touch("$(name)app/share/julia/cert.pem")
end

"""
**Toolips Export**
### build(et::ExportTemplate{:server}) -> _
------------------
Builds a new compiled server from a toolips project.
#### example
```
# From a toolips project directory:
build(so)
```
"""
function build(et::ExportTemplate{:server})
    name = build_copy()
    Pkg.activate(".")
 append_src(name, L"""\n
    function julia_main()::Cint
        ws = start()
        @info "toolips server started at $(ws.host):$(ws.port)"
        while true

        end
        return(0)
    end
    end # - module""")
    create_app(".", "$(name)app")
    touch("$(name)app/share/julia/cert.pem")
end

"""
**Toolips Export**
### build(et::ExportTemplate{:android}) -> _
------------------
**Not yet implemented.** If you would like to help this portion of the project
come into fruition, please consider contributing to any of the Toolips modules.
Your contribution will go a long way as there are a lot of toolips modules and
not a lot of people working on them. This will take the work away from the
problem you are working on, and onto projects such as this.
#### example
```
# From a toolips project directory:
build(android)
```
"""
function build(et::ExportTemplate{:android})
    name = build_copy()
    throw("build(::ExportTemplate{:android}) not implemented! Coming soon!")
end

"""
**Toolips Export**
### buildall(ets::Vector{ExportTemplate{Any}} = [so, server, app], title::String) -> _
------------------
Builds each export inside of `ets`.
#### example
```
# From a toolips project directory:
buildall()
```
"""
function buildall(ets::Vector{ExportTemplate{Any}} = [so, server, app],
    title::String = "toolips app")
    [begin
    @info "Compiling $et..."
    if et == app
        build(et, title)
    else
        build(et)
    end
    @info "$et Successfully built."
    end for et in ets]
end
export build, app, so, server, android
end # module
