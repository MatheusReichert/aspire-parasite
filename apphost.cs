#:sdk Aspire.AppHost.Sdk@13.1.2
#:project A/A/A.csproj
#:project B/B/B.csproj
#:project C/C/C.csproj

var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.A>("a");
builder.AddProject<Projects.B>("b");
builder.AddProject<Projects.C>("c");

builder.Build().Run();
