# Aspire Parasite

A proof of concept demonstrating how to use **.NET Aspire single-file AppHost** combined with **Git submodules** to achieve flexible, composable service orchestration across multiple independent solutions.

---

## Concept

In a traditional Aspire setup, each solution owns its AppHost and orchestrates only its own services. This project inverts that model: a **root workspace** acts as a parasite host that can selectively orchestrate services from any combination of child solutions — without modifying those solutions themselves.

Each child solution (A, B, C) is:
- A fully independent .NET Aspire solution with its own AppHost
- A Git repository tracked as a submodule in this workspace
- Unaware that it is being orchestrated externally

The root workspace contains multiple single-file AppHosts, each defining a different orchestration slice.

---

## Repository Structure

```
aspire-parasite/
├── apphost.cs             # Orchestrates A + B + C
├── apphost.run.json
├── apphost-ab.cs          # Orchestrates A + B only
├── apphost-ab.run.json
├── apphost-bc.cs          # Orchestrates B + C only
├── apphost-bc.run.json
├── apphost-ac.cs          # Orchestrates A + C only
├── apphost-ac.run.json
├── submodule-branches.ps1 # Helper script
├── doc/
│   └── README.pt-BR.md
├── A/                     # Git submodule → aspire-parasite-A
├── B/                     # Git submodule → aspire-parasite-B
└── C/                     # Git submodule → aspire-parasite-C
```

---

## How It Works

### Single-File AppHost

.NET 10 introduced single-file AppHost support via the `#:sdk` directive. Instead of a full `.csproj`, the AppHost is a plain `.cs` file:

```csharp
#:sdk Aspire.AppHost.Sdk@13.1.2
#:project A/A/A.csproj
#:project B/B/B.csproj

var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.A>("a");
builder.AddProject<Projects.B>("b");

builder.Build().Run();
```

The `#:project` directives reference services from the submodules. Aspire generates the `Projects.X` types automatically at build time.

Each AppHost file has a companion `.run.json` with isolated port assignments so multiple configurations can run simultaneously without conflicts.

### Git Submodules as Versioned Service Providers

Each child solution lives in its own Git repository with three branches:

| Branch   | Purpose                        |
|----------|--------------------------------|
| `master` | Stable, production-ready code  |
| `stag`   | Staging / pre-production       |
| `dev`    | Active development             |

The root workspace tracks each submodule at a specific commit, not a branch. This means you can pin different services to different versions independently:

- Service A → `dev` branch (latest features)
- Service B → `stag` branch (validated, not yet released)
- Service C → `master` branch (stable)

This gives you fine-grained control over which version of each service participates in a given orchestration.

---

## Getting Started

### Clone with submodules

```bash
git clone --recurse-submodules <repo-url>
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### Run an orchestration

```bash
# All services
dotnet run apphost.cs

# Only A and B
dotnet run apphost-ab.cs

# Only B and C
dotnet run apphost-bc.cs

# Only A and C
dotnet run apphost-ac.cs
```

Each command opens an Aspire Dashboard on its own port, allowing multiple configurations to run side by side.

---

## Managing Submodule Branches

Check which branch each submodule is currently on:

```powershell
.\submodule-branches.ps1
# or
git submodule foreach 'git branch --show-current'
```

Switch a submodule to a specific branch:

```bash
cd A
git switch dev
cd ..
git add A
git commit -m "Point A to dev"
```

Pull and update all submodules to their current branch:

```bash
git submodule foreach 'git pull origin $(git branch --show-current)'
```

---

## Adding a New Orchestration Configuration

1. Create a new AppHost file:

```csharp
// apphost-custom.cs
#:sdk Aspire.AppHost.Sdk@13.1.2
#:project A/A/A.csproj
#:project C/C/C.csproj

var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.A>("a");
builder.AddProject<Projects.C>("c");

builder.Build().Run();
```

2. Copy and adjust ports in a companion run file:

```bash
cp apphost.run.json apphost-custom.run.json
# Edit ports in apphost-custom.run.json to avoid conflicts
```

3. Run it:

```bash
dotnet run apphost-custom.cs
```

---

## Why This Pattern?

| Scenario | Benefit |
|----------|---------|
| Microservices development | Run only the services you need locally |
| Cross-team integration | Compose services from separate team repos |
| Environment simulation | Mix branches to simulate staging scenarios |
| Incremental onboarding | Add services to orchestration without touching their code |

---

## Requirements

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- .NET Aspire workload (`dotnet workload install aspire`)
- Git
