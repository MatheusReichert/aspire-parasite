# Aspire Parasite

Uma prova de conceito demonstrando como usar o **.NET Aspire AppHost de arquivo único** combinado com **Git submodules** para alcançar orquestração de serviços flexível e composável entre múltiplas soluções independentes.

---

## Conceito

Em uma configuração tradicional do Aspire, cada solução possui seu próprio AppHost e orquestra apenas seus próprios serviços. Este projeto inverte esse modelo: um **workspace raiz** atua como um host parasita que pode orquestrar seletivamente serviços de qualquer combinação de soluções filhas — sem modificar essas soluções.

Cada solução filha (A, B, C) é:
- Uma solução .NET Aspire completamente independente com seu próprio AppHost
- Um repositório Git rastreado como submodule neste workspace
- Alheia ao fato de estar sendo orquestrada externamente

O workspace raiz contém múltiplos AppHosts de arquivo único, cada um definindo um recorte de orquestração diferente.

---

## Estrutura do Repositório

```
aspire-parasite/
├── apphost.cs             # Orquestra A + B + C
├── apphost.run.json
├── apphost-ab.cs          # Orquestra apenas A + B
├── apphost-ab.run.json
├── apphost-bc.cs          # Orquestra apenas B + C
├── apphost-bc.run.json
├── apphost-ac.cs          # Orquestra apenas A + C
├── apphost-ac.run.json
├── submodule-branches.ps1 # Script auxiliar
├── doc/
│   └── README.pt-BR.md
├── A/                     # Git submodule → aspire-parasite-A
├── B/                     # Git submodule → aspire-parasite-B
└── C/                     # Git submodule → aspire-parasite-C
```

---

## Como Funciona

### AppHost de Arquivo Único

O .NET 10 introduziu suporte a AppHost de arquivo único via a diretiva `#:sdk`. Em vez de um `.csproj` completo, o AppHost é um arquivo `.cs` simples:

```csharp
#:sdk Aspire.AppHost.Sdk@13.1.2
#:project A/A/A.csproj
#:project B/B/B.csproj

var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.A>("a");
builder.AddProject<Projects.B>("b");

builder.Build().Run();
```

As diretivas `#:project` referenciam serviços dos submodules. O Aspire gera os tipos `Projects.X` automaticamente em tempo de build.

Cada arquivo AppHost possui um `.run.json` associado com portas isoladas para que múltiplas configurações possam rodar simultaneamente sem conflitos.

### Git Submodules como Provedores de Serviço Versionados

Cada solução filha vive em seu próprio repositório Git com três branches:

| Branch   | Propósito                          |
|----------|------------------------------------|
| `master` | Código estável, pronto para produção |
| `stag`   | Homologação / pré-produção         |
| `dev`    | Desenvolvimento ativo              |

O workspace raiz rastreia cada submodule em um commit específico, não em uma branch. Isso significa que você pode fixar diferentes serviços em versões diferentes de forma independente:

- Serviço A → branch `dev` (funcionalidades mais recentes)
- Serviço B → branch `stag` (validado, ainda não lançado)
- Serviço C → branch `master` (estável)

Isso oferece controle granular sobre qual versão de cada serviço participa de uma determinada orquestração.

---

## Como Começar

### Clonar com submodules

```bash
git clone --recurse-submodules <url-do-repo>
```

Se você já clonou sem os submodules:

```bash
git submodule update --init --recursive
```

### Executar uma orquestração

```bash
# Todos os serviços
dotnet run apphost.cs

# Apenas A e B
dotnet run apphost-ab.cs

# Apenas B e C
dotnet run apphost-bc.cs

# Apenas A e C
dotnet run apphost-ac.cs
```

Cada comando abre um Aspire Dashboard em sua própria porta, permitindo que múltiplas configurações rodem lado a lado.

---

## Gerenciando Branches dos Submodules

Verificar em qual branch cada submodule está atualmente:

```powershell
.\submodule-branches.ps1
# ou
git submodule foreach 'git branch --show-current'
```

Trocar um submodule para uma branch específica:

```bash
cd A
git switch dev
cd ..
git add A
git commit -m "Aponta A para dev"
```

Fazer pull e atualizar todos os submodules para sua branch atual:

```bash
git submodule foreach 'git pull origin $(git branch --show-current)'
```

---

## Adicionando uma Nova Configuração de Orquestração

1. Crie um novo arquivo AppHost:

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

2. Copie e ajuste as portas no arquivo run associado:

```bash
cp apphost.run.json apphost-custom.run.json
# Edite as portas em apphost-custom.run.json para evitar conflitos
```

3. Execute:

```bash
dotnet run apphost-custom.cs
```

---

## Por Que Esse Padrão?

| Cenário | Benefício |
|---------|-----------|
| Desenvolvimento de microsserviços | Execute apenas os serviços que você precisa localmente |
| Integração entre times | Componha serviços de repositórios de times separados |
| Simulação de ambiente | Misture branches para simular cenários de homologação |
| Onboarding incremental | Adicione serviços à orquestração sem tocar no código deles |

---

## Requisitos

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Workload do .NET Aspire (`dotnet workload install aspire`)
- Git
