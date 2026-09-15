# Railway execution

Use Railway for fast development runs of the FCR studies. GitHub Actions remains the final regression gate.

Default development command:

```bash
julia --project=. examples/FCR/<study>/run.jl
```

The Railway service should build from the repository root and use the existing Julia/Docker environment. Each study writes results under its own `results/` directory.
