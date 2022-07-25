module ToolipsExport
using Toolips
using Blink
using PackageCompiler
using TOML
using Pkg
macro L_str(s::String)
    s
end
abstract type ExportTemplate end

mutable struct So <: ExportTemplate

end

function build(et::ExportTemplate = So())
    name = TOML.parse(read("Project.toml", String))["name"]
    if ~(isdir(name))
        Pkg.generate(name)
    else

    end
    cp("src", "$name/src", force = true)
    cp("Project.toml", "$name/Project.toml", force = true)
    cp("Manifest.toml", "$name/Manifest.toml", force = true)
    cd(name)
    touch("src/build.jl")
    open("src/$name.jl", "a") do io
        write(io, """
        Base.@ccallable function _start()::Cvoid
            start()
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
    create_library(".", "$(name)build";
                      lib_name=name,
            )
end
end # module
