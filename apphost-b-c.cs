#:sdk Aspire.AppHost.Sdk@13.1.2
#:project B/B/B.csproj
#:project C/C/C.csproj

var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.B>("b");
builder.AddProject<Projects.C>("c");

builder.Build().Run();
