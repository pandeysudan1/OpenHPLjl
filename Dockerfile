FROM julia:1.12-bookworm

WORKDIR /app

COPY Project.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(; allow_autoprecomp=false)'

COPY . .
RUN julia --project=. -e 'using Pkg; Pkg.resolve(); Pkg.precompile(); using OpenHPLjl; println("OpenHPLjl package load OK")'

CMD ["julia", "--project=.", "scripts/railway_entrypoint.jl"]
