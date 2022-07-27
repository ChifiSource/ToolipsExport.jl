module ToolipsExport
using PackageCompiler
using TOML
using Pkg

macro L_str(s::String)
    s
end

mutable struct ExportTemplate{type} end

const so = ExportTemplate{:so}()
const app = ExportTemplate{:app}()
const server = ExportTemplate{:server}()
const android = ExportTemplate{:android}()

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

function build(et::ExportTemplate{:so} = so)
    name = build_copy()
    open("src/$name.jl", "a") do io
        write(io, """
        using $name
        Base.@ccallable function _start()::Cvoid
            $name.start()
        end""")
    end
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

function build(et::ExportTemplate{:app})
    name = build_copy()
    Pkg.activate(".")
    Pkg.add("Blink")
    current_file::String = read("src/$name.jl", String)
    lastend::UnitRange{Int64} = findlast("end", current_file)
    current_file = current_file[1:minimum(lastend) - 1] * """\n
    using Blink
    using $name
    function julia_main()::Cint
        $name.start("127.0.0.1", 8003)
        w = Window()
        loadurl(w, "http://127.0.0.1:8003")
        Base.Threads.@spawn while active(w)
            if ~(active(w))
                return(0)
            end
        end
    end
end # - module"""
    open("src/$name.jl", "w") do io
        write(io, current_file)
    end
    create_app(".", "$(name)app")
    touch("$(name)app/share/julia/cert.pem")
end

export build, app, so
end # module
